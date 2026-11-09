use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k70: the three pipeline seams -- _pipeline_enter,
# _pipeline_sync, _pipeline_exit -- through core's pipeline scaffold, on a
# pooled connection and on a transaction's.
#
# WHY: without a server the seams ran only where the sync fails
# (t/37-pipeline-sync-error-mock.t, on a connection that is a stub with no
# pool behind it). The batch that succeeds, the batch on a transaction's
# connection and the exit that dies ran only against PostgreSQL (t/15, t/29,
# t/36). What the seams owe core is small and easy to lose in a refactoring,
# and none of it needs a server to be seen:
#   - between enter and exit, _query_async_pinned sends every statement at
#     once -- that is the batch -- instead of one at a time, as it does on a
#     pinned connection otherwise (karr k48). The note of that is the seams'
#     own: made in _pipeline_enter, dropped in _pipeline_exit;
#   - the sync Future settles when EV::Pg reports the sync point, not before:
#     core leaves pipeline mode and hands the connection back from it;
#   - an exit EV::Pg refuses dies out of _pipeline_exit, so core retires the
#     connection instead of handing out one that is still in pipeline mode.
#
# What this file claims, through the REAL storage, pool and core scaffold over
# a stand-in EV::Pg:
#   1. pooled, a batch of two: enter, both statements and the sync are on the
#      wire before the first result; each statement settles with its own
#      result, in order; pipeline mode is left only after the sync point, and
#      the connection is released then, once, out of pipeline mode with
#      nothing in flight; the pipeline resolves with what the coderef
#      returned. Afterwards the connection is an ordinary one again: a pooled
#      call runs on it, and a transaction's statements go one at a time;
#   2. pooled, a statement of the batch fails: it has its own error, the one
#      before it its result, the one behind it "pipeline aborted"; the
#      pipeline fails with the statement's error; pipeline mode is left, the
#      connection released once and kept;
#   3. the exit dies, and the connection is retired -- closed once, never
#      released into the pool, the next call on a fresh one -- while the
#      pipeline keeps the error that ended the batch:
#      a. the coderef dies with a statement in flight (EV::Pg refuses the
#         exit: "cannot exit pipeline mode while busy"): the coderef's error;
#      b. the connection is lost during the batch (the exit croaks "not
#         connected"): the sync's "connection lost", and every statement
#         fails with it;
#      c. the exit is refused after a batch that succeeded (forced here; no
#         server does that): the exit's own error, nothing else having
#         failed, and the statements keep their results;
#   4. in a transaction ($ctx->pipeline): BEGIN, then the bracket and the
#      batch on that same connection, COMMIT only after pipeline mode was
#      left; the pipeline releases nothing, the transaction releases once,
#      with no transaction open; a statement that fails in the batch rolls
#      the transaction back instead;
#   5. in a transaction, the exit dies (as 3a): the transaction fails with the
#      error that ended the batch, COMMIT is never sent, and the connection is
#      retired, not released (core k232);
#   6. no callback of this transport dies out of EV::Pg, and nothing warns
#      but the pool reporting the lost connection of 3b.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/55: a fake the real pool
# builds through its real, fork-safe constructor. What it takes from EV::Pg
# (Pg.xs, 0.02 and 0.07 alike -- read there, not measured here) and from the
# conditions libpq documents for PQenterPipelineMode, PQpipelineSync and
# PQexitPipelineMode. The texts of the refusals are stand-ins: no assertion
# reads one, but for the one 3c forces itself.
#   - enter_pipeline croaks unless libpq is idle; in pipeline mode
#     query_params takes any number of statements, outside it a second one
#     croaks "another command is already in progress"; pipeline_sync croaks
#     outside pipeline mode; each croaks "not connected" on a handle that is
#     not, before it queues anything;
#   - results go to the queued callbacks in the order sent, the sync point to
#     the sync's callback as (1). A callback is delivered after its command's
#     result was read, and stays in the queue until it has returned;
#   - after a statement of a batch failed, the statements behind it are not
#     run: each gets (undef, "pipeline aborted"), up to the sync, which is
#     reported all the same (deliver_result's text for a
#     PGRES_PIPELINE_ABORTED result; t/36 saw it from a server);
#   - exit_pipeline croaks while a result is still due ("cannot exit pipeline
#     mode while busy", as t/36 quotes it from a server, and as
#     t/64-pipeline-seams-live.t holds it for 3a and 5, karr k73), and
#     succeeds inside the sync's callback, where none is -- which is where
#     core calls it, and what t/15 and t/29 run against PostgreSQL;
#   - a lost connection is handle_conn_loss: on_error, then every queued
#     callback gets (undef, "connection lost"); finish gives them "connection
#     finished" and calls no on_error.
# With $EV::Pg::HOLD set no result is delivered until the test delivers it
# (deliver), so each step can be looked at. The "server" answers a SELECT or
# INSERT with a row naming the statement's last bind value.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our $HOLD;    # true: results wait for t_deliver
  our %FAIL;    # wire name => message: such a statement fails on the server
  our %CROAK;   # op => message: the next call of that op croaks, once

  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      finished   => 0,
      pipeline   => 0,    # PQpipelineStatus
      intrans    => 0,
      queue      => [],   # sent, callback not returned yet
      wire       => [],   # every call that reached the wire, in order
    }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected    { $_[0]{up} ? 1 : 0 }
  sub pending_count   { scalar @{ $_[0]{queue} } }
  sub socket          { -1 }
  sub result_meta     { $_[0]{meta} }
  sub pipeline_status { $_[0]{pipeline} }

  # A result is still due: something is queued besides the callback being
  # delivered right now.
  sub _busy {
    my ($self) = @_;
    return scalar grep { !$self->{delivering} || $_ != $self->{delivering} } @{ $self->{queue} };
  }

  sub _check {
    my ($self, $op) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    my $msg = delete $CROAK{$op};
    die $msg if defined $msg;
    return;
  }

  sub _send {
    my ($self, $label, $entry) = @_;
    push @{ $self->{wire} }, $label;
    push @{ $self->{queue} }, $entry;
    $self->_arm;
    return;
  }

  sub enter_pipeline {
    my ($self) = @_;
    $self->_check('enter_pipeline');
    die "PQenterPipelineMode failed: cannot enter pipeline mode, connection not idle\n"
      if $self->_busy;
    push @{ $self->{wire} }, 'enter_pipeline';
    $self->{pipeline} = 1;
    return;
  }

  sub exit_pipeline {
    my ($self) = @_;
    $self->_check('exit_pipeline');
    die "PQexitPipelineMode failed: cannot exit pipeline mode while busy\n"
      if $self->{pipeline} && $self->_busy;
    push @{ $self->{wire} }, 'exit_pipeline';
    $self->{pipeline} = 0;
    return;
  }

  # A SELECT or INSERT is named by its last bind value, anything else by its verb.
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    $self->_check('query_params');
    die "PQsendQueryParams failed: another command is already in progress\n"
      if !$self->{pipeline} && $self->_busy;
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb =~ /^(?:SELECT|INSERT)\z/ && @$bind ? $bind->[-1] : $verb;
    return $self->_send($name, { sql => $sql, name => $name, cb => $cb, piped => $self->{pipeline} });
  }

  sub pipeline_sync {
    my ($self, $cb) = @_;
    $self->_check('pipeline_sync');
    die "PQpipelineSync failed: cannot send pipeline when not in pipeline mode\n"
      unless $self->{pipeline};
    return $self->_send('pipeline_sync', { sync => 1, cb => $cb });
  }

  # cancel_pending, then cleanup_connection: no on_error.
  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_drop_queued('connection finished');
    $self->{up}       = 0;
    $self->{pipeline} = 0;
    return;
  }

  sub _drop_queued {
    my ($self, $msg) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, $msg); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    return;
  }

  # handle_conn_loss
  sub t_lose {
    my ($self, $msg) = @_;
    my $finished = $self->{finished};
    $self->{up} = 0;
    $self->{on_error}->($msg) if $self->{on_error};
    $self->_drop_queued('connection lost') if $self->{finished} == $finished;
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $HOLD || $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  # The next result the server owes arrives now.
  sub t_deliver {
    my ($self) = @_;
    Carp::croak('t_deliver: nothing is in flight') unless @{ $self->{queue} };
    return $self->_complete_head;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    my ($tag, @result) = $self->_serve($head);
    $self->{meta} = { cmd_status => $tag } if defined $tag;
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_arm;
    return;
  }

  # The server's answer: its command tag, then what EV::Pg hands the callback
  # -- (undef, $error) for an error.
  sub _serve {
    my ($self, $entry) = @_;
    if ($entry->{sync}) {
      delete $self->{skipping};
      return (undef, 1);
    }
    return (undef, undef, 'pipeline aborted') if $self->{skipping};

    my ($sql, $name) = @$entry{qw( sql name )};
    if ($sql eq 'BEGIN') { $self->{intrans} = 1; return ('BEGIN', '') }
    if ($sql eq 'COMMIT' || $sql eq 'ROLLBACK') {
      my $aborted = delete $self->{aborted};
      $self->{intrans} = 0;
      return ($aborted ? 'ROLLBACK' : $sql, '');
    }
    my $error = $self->{aborted}
      ? "ERROR:  current transaction is aborted, commands ignored until end of transaction block\n"
      : $FAIL{$name};
    if (defined $error) {
      $self->{aborted}  = 1 if $self->{intrans};
      $self->{skipping} = 1 if $entry->{piped};
      return (undef, undef, $error);
    }
    return ('INSERT 0 1', [ [ 'row-of', $name ] ]) if $sql =~ /^INSERT/;
    return ('SELECT 1', [ [ 'row-of', $name ] ])   if $sql =~ /^SELECT/;
    return ('OK', '');
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use Scalar::Util ();
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF    = 'DBIO::PostgreSQL::EV::Future';
my $BROKEN = qq{ERROR:  relation "thing" does not exist\n};
my $LOST   = "server closed the connection unexpectedly\n";
my $BUSY   = "PQexitPipelineMode failed: cannot exit pipeline mode while busy\n";

# The real pool, with every way a connection leaves a caller's hands recorded:
# released -- and in what state --, or retired.
{
  package T58::Pool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{t_released} }, {
      conn      => $conn->{id},
      in_flight => $conn->_busy,
      pipeline  => $conn->{pipeline},
      in_txn    => $conn->{intrans},
    };
    return $self->SUPER::release($conn);
  }

  sub _retire_in_use_connection {
    my ($self, $conn) = @_;
    push @{ $self->{t_retired} }, $conn->{id};
    return $self->SUPER::_retire_in_use_connection($conn);
  }
}

sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The next result the server owes on $conn arrives now.
sub deliver {
  my ($conn) = @_;
  return $conn->t_deliver if $conn->pending_count;
  fail 'a result was due on the connection, but nothing is in flight on it';
  return;
}

sub the_conn { $_[0]->pool->{_connections}[0] }
sub wire     { [ @{ $_[0]{wire} } ] }
sub released { [ @{ $_[0]->pool->{t_released} || [] } ] }
sub retired  { [ @{ $_[0]->pool->{t_retired} || [] } ] }
sub clean    { { conn => $_[0]{id}, in_flight => 0, pipeline => 0, in_txn => 0 } }

sub select_named { $_[0]->select_async('thing', [qw( tag name )], { name => $_[1] }) }
sub insert       { $_[0]->insert_async('thing', { name => $_[1] }) }

# What a Future settled with: [ done => @result ], [ failed => $error ], or
# [ 'pending' ] / [ 'cancelled' ].
sub outcome {
  my ($f) = @_;
  return ['pending']   unless $f->is_ready;
  return ['cancelled'] if $f->is_cancelled;
  return [ failed => ($f->failure)[0] ] if $f->is_failed;
  return [ done => $f->get ];
}

# A pool of one whose connection is spawned and idle, a clean wire, nothing
# released yet.
sub fresh {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  bless $storage->pool, 'T58::Pool';
  my ($ok, @r) = wait_for(select_named($storage, 'warm'));
  die "warming the pool failed: $r[0]" unless $ok;
  settle();
  my $conn = the_conn($storage);
  @{ $conn->{wire} } = ();
  @{ $storage->pool->{t_released} } = ();
  @warnings = ();
  return ($storage, $conn);
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::Pg, nothing warned";
  @warnings = ();
}

# The connection is the pool's one, idle and an ordinary connection again, and
# the next pooled call runs on it and gets its own rows.
sub serves_on {
  my ($label, $storage, $conn) = @_;
  local $EV::Pg::HOLD = 0;
  settle();
  is $storage->pool->size, 1, "$label: the pool still has its one connection";
  is $storage->pool->available, 1, "$label: idle";
  is $conn->pipeline_status, 0, "$label: out of pipeline mode";
  my $sent = @{ wire($conn) };
  my ($ok, @r) = wait_for(select_named($storage, 'next'));
  ok $ok, "$label: the next pooled call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  is_deeply [ @{ wire($conn) }[ $sent .. $#{ wire($conn) } ] ], ['next'],
    "$label: on that connection, as a plain statement";
  settle();
  nothing_warned($label);
}

# The connection was retired: closed once, never released into the pool, and
# the next pooled call runs on a fresh one.
sub retired_and_replaced {
  my ($label, $storage, $conn) = @_;
  local $EV::Pg::HOLD = 0;
  settle();
  is_deeply retired($storage), [ $conn->{id} ], "$label: the connection is retired, once";
  is_deeply released($storage), [], "$label: and never released into the pool";
  is $conn->{finished}, 1, "$label: it is closed, once";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: the pool no longer holds it";
  is $conn->pending_count, 0, "$label: no callback is left queued on it";

  my ($ok, @r) = wait_for(select_named($storage, 'next'));
  ok $ok, "$label: the next pooled call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  my $fresh = the_conn($storage);
  ok $fresh && $fresh != $conn, "$label: on a fresh connection";
  is_deeply wire($fresh), ['next'], "$label: an ordinary one";
  ok !grep({ $_ eq 'next' } @{ wire($conn) }), "$label: nothing more went to the retired one";
  settle();
}

# --- 1. pooled: a batch of two ----------------------------------------------------

{
  my $label = 'pooled batch';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($ctx, @stmt);
  my $p = $storage->pipeline(sub {
    ($ctx) = @_;
    @stmt = (insert($ctx, 'a'), select_named($ctx, 'b'));
    return $ctx->future_class->needs_all(@stmt)->then(sub { $EVF->done(batch => scalar @_) });
  });

  is $ctx && $ctx->pipeline_conn, $conn, "$label: the batch context is on the pool's connection";
  is_deeply wire($conn), [qw( enter_pipeline a b pipeline_sync )],
    "$label: enter, both statements and the sync are on the wire before the first result";
  is $conn->pipeline_status, 1, "$label: the connection is in pipeline mode";
  is_deeply [ map { outcome($_)->[0] } @stmt, $p ], [qw( pending pending pending )],
    "$label: nothing has settled";
  is_deeply released($storage), [], "$label: nothing is released";

  deliver($conn);   # a's result
  is_deeply [ map { outcome($_)->[0] } @stmt, $p ], [qw( done pending pending )],
    "$label: the first result settles the first statement, and only that";
  deliver($conn);   # b's result
  is_deeply [ map { outcome($_) } @stmt ],
    [ [ done => { name => 'a' } ], [ done => [ 'row-of', 'b' ] ] ],
    "$label: each statement has its own result";
  is outcome($p)->[0], 'pending', "$label: the pipeline waits for the sync point";
  is $conn->pipeline_status, 1, "$label: still in pipeline mode";
  is_deeply released($storage), [], "$label: still not released";

  deliver($conn);   # the sync point
  is_deeply wire($conn), [qw( enter_pipeline a b pipeline_sync exit_pipeline )],
    "$label: the sync point leaves pipeline mode -- one enter, one sync, one exit";
  is_deeply released($storage), [ clean($conn) ],
    "$label: and releases the connection, once, out of pipeline mode, nothing in flight";
  is_deeply outcome($p), [ done => batch => 2 ], "$label: the pipeline resolves with what the coderef returned";
  is $conn->pending_count, 0, "$label: no result is due";

  serves_on($label, $storage, $conn);

  # An ordinary connection again for the pinned path too: one at a time.
  {
    local $EV::Pg::HOLD = 1;
    @{ $conn->{wire} } = ();
    my ($x, $y);
    my $txn = $storage->txn_do_async(sub {
      my ($t) = @_;
      ($x, $y) = (select_named($t, 'x'), select_named($t, 'y'));
      return $EVF->needs_all($x, $y);
    });
    deliver($conn);   # BEGIN's result: the coderef runs
    is_deeply wire($conn), [qw( BEGIN x )],
      "$label: afterwards a transaction's statements go one at a time again";
    is outcome($y)->[0], 'pending', "$label: the second one waits, it is not refused";
    deliver($conn) for 1 .. 3;   # x, y, COMMIT
    is_deeply wire($conn), [qw( BEGIN x y COMMIT )], "$label: and both run, in order";
    is outcome($txn)->[0], 'done', "$label: the transaction commits";
  }
  nothing_warned($label);
}

# --- 2. pooled: a statement of the batch fails ------------------------------------

{
  my $label = 'pooled batch, a statement fails';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;
  local $EV::Pg::FAIL{b} = $BROKEN;

  my @stmt;
  my $p = $storage->pipeline(sub {
    my ($ctx) = @_;
    @stmt = map { select_named($ctx, $_) } qw( a b c );
    return $stmt[1];   # not needs_all: that cancels the statement behind the failed one
  });
  is_deeply wire($conn), [qw( enter_pipeline a b c pipeline_sync )], "$label: the whole batch is on the wire";

  deliver($conn) for 1 .. 3;   # a, b, c
  is_deeply [ map { outcome($_) } @stmt ],
    [ [ done => [ 'row-of', 'a' ] ], [ failed => $BROKEN ], [ failed => 'pipeline aborted' ] ],
    "$label: the one before has its result, the failed one its error, the one behind was not run";
  is_deeply released($storage), [], "$label: the connection is held until the sync point";

  deliver($conn);   # the sync point
  is_deeply outcome($p), [ failed => $BROKEN ], "$label: the pipeline fails with the statement's error";
  is_deeply wire($conn), [qw( enter_pipeline a b c pipeline_sync exit_pipeline )],
    "$label: pipeline mode is left";
  # A batch that failed leaves statements unsynced or half read on the
  # connection: core retires it and never releases it (core k396), where this
  # file used to claim it was kept because the session survived.
  retired_and_replaced($label, $storage, $conn);
}

# --- 3a. the coderef dies with a statement in flight: the exit is refused ---------

{
  my $label = 'coderef dies mid-batch';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $stmt;
  my $p = $storage->pipeline(sub {
    my ($ctx) = @_;
    $stmt = select_named($ctx, 'a');
    die "boom\n";
  });

  is_deeply outcome($p), [ failed => "boom\n" ],
    "$label: the pipeline fails with the coderef's error, not with the exit's";
  is_deeply wire($conn), [qw( enter_pipeline a )],
    "$label: no sync was sent, and EV::Pg refused the exit: a result was still due";
  is_deeply outcome($stmt), [ failed => 'connection finished' ],
    "$label: the statement in flight fails as its connection is closed";
  retired_and_replaced($label, $storage, $conn);
  nothing_warned($label);
}

# --- 3b. the connection is lost during the batch ----------------------------------

{
  my $label = 'connection lost mid-batch';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my @stmt;
  my $p = $storage->pipeline(sub {
    my ($ctx) = @_;
    @stmt = map { select_named($ctx, $_) } qw( a b );
    return 'plain';   # no statement Future carries the failure
  });
  $conn->t_lose($LOST);

  is_deeply [ map { outcome($_) } @stmt ], [ ([ failed => 'connection lost' ]) x 2 ],
    "$label: every statement fails with EV::Pg's error";
  is_deeply outcome($p), [ failed => 'connection lost' ],
    "$label: the pipeline fails with the sync's error, not with the exit's \"not connected\"";
  is_deeply wire($conn), [qw( enter_pipeline a b pipeline_sync )], "$label: (the exit croaked)";
  like join('', @warnings), qr/pool error: \Q$LOST\E/, "$label: the pool reported the loss";
  is scalar(grep { /exception in callback/ } @warnings), 0, "$label: no callback died out of EV::Pg"
    or diag @warnings;
  @warnings = ();
  retired_and_replaced($label, $storage, $conn);
  nothing_warned($label);
}

# --- 3c. the exit is refused after a batch that succeeded -------------------------

{
  my $label = 'exit refused after the sync point';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my @stmt;
  my $p = $storage->pipeline(sub {
    my ($ctx) = @_;
    @stmt = map { select_named($ctx, $_) } qw( a b );
    return $ctx->future_class->needs_all(@stmt);
  });
  deliver($conn) for 1 .. 2;   # a, b
  local $EV::Pg::CROAK{exit_pipeline} = $BUSY;
  deliver($conn);              # the sync point

  is_deeply [ map { outcome($_) } @stmt ], [ [ done => [ 'row-of', 'a' ] ], [ done => [ 'row-of', 'b' ] ] ],
    "$label: the statements keep their results";
  is_deeply outcome($p), [ failed => $BUSY ],
    "$label: the pipeline fails with the exit's error, nothing else having failed";
  retired_and_replaced($label, $storage, $conn);
  nothing_warned($label);
}

# --- 4. in a transaction ----------------------------------------------------------

{
  my $label = 'batch in a transaction';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($batch_conn, @stmt);
  my $txn = $storage->txn_do_async(sub {
    my ($t) = @_;
    return $t->pipeline(sub {
      my ($ctx) = @_;
      $batch_conn = $ctx->pipeline_conn;
      @stmt = (insert($ctx, 'a'), insert($ctx, 'b'));
      return $ctx->future_class->needs_all(@stmt);
    })->then(sub { $EVF->done(rows => scalar @_) });
  });
  is_deeply wire($conn), ['BEGIN'], "$label: BEGIN first";

  deliver($conn);   # BEGIN's result: the coderef runs
  is $batch_conn, $conn, "$label: the batch is on the transaction's connection";
  is_deeply wire($conn), [qw( BEGIN enter_pipeline a b pipeline_sync )],
    "$label: then the bracket and the whole batch, on that connection";

  deliver($conn) for 1 .. 2;   # a, b
  is_deeply [ map { outcome($_) } @stmt ], [ [ done => { name => 'a' } ], [ done => { name => 'b' } ] ],
    "$label: each statement has its own result";
  is_deeply wire($conn), [qw( BEGIN enter_pipeline a b pipeline_sync )],
    "$label: COMMIT waits for the sync point";

  deliver($conn);   # the sync point
  is_deeply wire($conn), [qw( BEGIN enter_pipeline a b pipeline_sync exit_pipeline COMMIT )],
    "$label: the sync point leaves pipeline mode, and only then COMMIT goes out";
  is_deeply released($storage), [], "$label: the pipeline releases nothing -- the connection is the transaction's";
  is outcome($txn)->[0], 'pending', "$label: the transaction waits for its COMMIT";

  deliver($conn);   # COMMIT's
  is_deeply outcome($txn), [ done => rows => 2 ], "$label: the transaction resolves with what its coderef returned";
  is_deeply released($storage), [ clean($conn) ],
    "$label: and releases the connection, once, no transaction open, out of pipeline mode";
  is_deeply retired($storage), [], "$label: nothing is retired";

  serves_on($label, $storage, $conn);
}

{
  my $label = 'batch in a transaction, a statement fails';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;
  local $EV::Pg::FAIL{b} = $BROKEN;

  my $txn = $storage->txn_do_async(sub {
    my ($t) = @_;
    return $t->pipeline(sub {
      my ($ctx) = @_;
      return $ctx->future_class->needs_all(map { insert($ctx, $_) } qw( a b ));
    });
  });
  deliver($conn) for 1 .. 4;   # BEGIN, a, b, the sync point
  is_deeply wire($conn), [qw( BEGIN enter_pipeline a b pipeline_sync exit_pipeline ROLLBACK )],
    "$label: pipeline mode is left, then ROLLBACK goes out, never COMMIT";
  # The batch failed: core sends the ROLLBACK without waiting for its answer and
  # retires the connection, never releasing it (core k396). So there is no
  # answer of the ROLLBACK's to deliver, and the transaction fails at once.
  is_deeply outcome($txn), [ failed => $BROKEN ], "$label: the transaction fails with the statement's error";
  retired_and_replaced($label, $storage, $conn);
}

# --- 5. in a transaction, the exit dies -------------------------------------------

{
  my $label = 'batch in a transaction, coderef dies mid-batch';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($t) = @_;
    return $t->pipeline(sub {
      my ($ctx) = @_;
      $stmt = insert($ctx, 'a');
      die "boom\n";
    });
  });
  deliver($conn);   # BEGIN's result: the coderef runs, the batch dies, the exit is refused

  is_deeply outcome($txn), [ failed => "boom\n" ],
    "$label: the transaction fails with the error that ended the batch";
  ok !grep({ $_ eq 'COMMIT' } @{ wire($conn) }), "$label: COMMIT is never sent";
  is_deeply [ @{ wire($conn) }[ 0 .. 2 ] ], [qw( BEGIN enter_pipeline a )],
    "$label: (no sync was sent, and EV::Pg refused the exit)";
  note "$label: the wire was @{ wire($conn) } -- the ROLLBACK core sends without waiting for it "
    . 'is not claimed here';
  is outcome($stmt)->[0], 'failed', "$label: the statement in flight fails as its connection is closed";
  retired_and_replaced($label, $storage, $conn);
  nothing_warned($label);
}

done_testing;
