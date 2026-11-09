use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k70: a statement Future cancelled while its statement
# is in flight -- on the pooled path and inside txn_do_async.
#
# WHY: cancelling the Future a caller was given, or losing it in a wait_any
# against a timeout, is the only way a caller has to stop waiting, and it is a
# client-side act: EV::Pg knows nothing of it. The statement is on the server,
# its result is on its way, and the callback this transport handed to EV::Pg
# stays in EV::Pg's queue -- the connection is busy, not free and not dead.
# dbio-async retires a connection whose statement was cancelled in flight (its
# DBD result can no longer be read). This transport does not: it relies on
# EV::Pg calling the completion callback all the same, and gives the connection
# back from there. Nothing tested that, on either path. What is at stake: the
# connection goes back to the pool exactly once -- not at the cancel, where
# libpq is still busy with the statement, and not never -- and the late result
# does not reach the statement that runs next on that connection.
#
# Sections 1 to 8 are for a stack WITHOUT EV::Pg's cancel_async (libpq 16 and
# earlier: `can` says no): the transport then sends no cancel request and holds
# the connection until the statement's result. From section 9 on the fake has
# cancel_async and the cancel asks the server (karr k75, at the end of this
# file).
#
# What this file claims, through the REAL storage, pool and core transaction
# scaffold over a stand-in EV::Pg:
#   1. pooled, on a warm and on a cold pool: the cancel alone releases nothing
#      and the connection is not idle; the late result releases it, once, with
#      nothing in flight; the Future stays cancelled; the next call runs on the
#      same connection and gets its own rows;
#   2. pooled, pool of one, the next call issued BEFORE the late result (before
#      or after the cancel): it is not sent while the cancelled statement is in
#      flight; the late result hands the connection on to it without settling
#      it; it is sent then and settles with its own rows; one release each;
#   3. pooled, the late answer is not a result: a server error the session
#      survives leaves the connection in the pool, released once; a lost
#      connection is retired once, and the call waiting for it runs on a fresh
#      one;
#   4. pinned, a statement of a txn_do_async coderef cancelled in flight (in
#      the coderef, after it returned, or as the loser of a wait_any): ROLLBACK
#      goes on the wire only after the cancelled statement's result -- libpq
#      would refuse it before -- and never COMMIT; the late result does not end
#      the transaction; it fails with core's "cancelled before it was answered"
#      error, or with the error that won the wait_any; the connection comes
#      back once, IDLE, and the next call gets its own rows;
#   5. pinned, a statement queued behind the cancelled one is sent after the
#      late result, is not settled by it, and settles with its own rows;
#   6. pinned, a statement cancelled while it still waits behind another one:
#      the transaction rolls back and the connection comes back once, IDLE.
#      Such a statement is skipped, never sent (karr k75): the wire is BEGIN,
#      first, ROLLBACK. The COMMIT / ROLLBACK of core is the exception -- a
#      cancelled one still goes out, or the transaction would stay open;
#   7. no callback of this transport dies out of EV::Pg, and nothing warns.
#
#   8. pinned, the cancelled Future is the very one the coderef returned.
#      Future.pm runs no ->then callback of a cancelled Future, so core
#      answers the cancel itself (core k274, ADR 0055 addendum): the
#      transaction fails with "Transaction cancelled", ROLLBACK goes out
#      best-effort and unwaited, the connection is retired -- never released,
#      closed, the pool's slot going to a fresh connection -- and nothing is
#      committed. (Until core k274 the transaction stayed pending, its
#      connection checked out with the transaction open.)
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/41 and t/43: a fake the real
# pool builds through its real, fork-safe constructor. What it assumes of
# EV::Pg:
#   - a statement's callback is queued when it is sent, and each result goes to
#     the callback at the head of that queue, in the order sent. Read from
#     EV::Pg 0.07's POD, not measured here: pending_count is the "number of
#     callbacks currently in the queue (queries sent but not yet delivered)",
#     and skip_pending is the one call that drops queued callbacks. Nothing a
#     Future does reaches EV::Pg, so the callback of a cancelled statement is
#     still called, with that statement's result -- the assumption this whole
#     file stands on, held against PostgreSQL in t/61-cancel-in-flight-live.t
#     (karr k73);
#   - outside pipeline mode a dispatch while a statement is in flight croaks
#     "PQsendQueryParams failed: another command is already in progress" before
#     it queues anything (measured live at karr k44 / k48, as t/43 has it);
#   - a result is delivered after the command's last result was read, so libpq
#     is idle again inside the callback, which still counts in pending_count
#     until it returns; a callback is called under an eval that only warns
#     (t/43);
#   - a lost connection is handle_conn_loss: the handle is torn down, on_error
#     is called, then every queued callback gets (undef, "connection lost")
#     (t/41).
# With $EV::Pg::HOLD set no result is delivered until the test delivers it
# (t_deliver), so each step can be looked at; the connect is not held. The
# "server" answers a SELECT or INSERT with a row naming the statement's last
# bind value, so every statement's rows are its own, and keeps the transaction
# state and which inserted rows were committed.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our $HOLD;        # true: results wait for t_deliver
  our @BUILT;       # every handle made, in order (weak)
  our @COMMITTED;   # names of the rows the server has committed
  our %FAIL;        # wire name => message: such a statement fails on the server

  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],   # sent, result not delivered yet (the callback queue)
      busy       => 0,    # libpq has a command in progress
      intrans    => 0,
      rows       => [],   # inserted in the open transaction
      wire       => [],   # what was sent, in order: a statement's name or verb
    }, $class;
    push @BUILT, $self;
    Scalar::Util::weaken($BUILT[-1]);
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

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub result_meta   { $_[0]{meta} }
  # PQTRANS_IDLE 0, _ACTIVE 1, _INTRANS 2, _INERROR 3, _UNKNOWN 4
  sub transaction_status {
    my ($s) = @_;
    return !$s->{up} ? 4 : $s->{busy} ? 1 : !$s->{intrans} ? 0 : $s->{aborted} ? 3 : 2;
  }

  # A SELECT or INSERT is named by its last bind value, anything else by its verb.
  sub _name {
    my ($sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    return $verb =~ /^(?:SELECT|INSERT)\z/ && @$bind ? $bind->[-1] : $verb;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy};
    my $name = _name($sql, $bind);
    push @{ $self->{wire} }, $name;
    # A cancel request that is out and not answered lands on whatever the
    # connection runs next (measured, karr k75: 151 of 185 through the pool).
    my $stmt = { sql => $sql, name => $name, cb => $cb };
    $stmt->{cancelled} = 1 if $self->{cancel_open} && !@{ $self->{queue} };
    push @{ $self->{queue} }, $stmt;
    $self->{busy} = 1;
    $self->_arm;
    return;
  }

  # libpq pipeline mode, as far as the cancel is concerned: statements are
  # taken at once, whatever is in flight.
  sub enter_pipeline { $_[0]{pipeline} = 1; return }
  sub exit_pipeline  { delete $_[0]{pipeline}; return }

  # EV::Pg's cancel_async (libpq 17+): one request at a time, answered by its
  # callback with (1), or (undef, $error). It stops the statement in flight:
  # that fails with 57014. Defined only while a test gives the stack the
  # capability (t_capability), so `can` says what it says on libpq 16.
  sub _cancel_async {
    my ($self, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};
    Carp::croak('cancel already in progress') if $self->{cancel_cb};
    push @{ $self->{cancels} }, scalar @{ $self->{wire} };   # sent after this many statements
    $self->{cancel_cb}   = $cb;
    $self->{cancel_open} = 1;
    $self->{queue}[0]{cancelled} = 1 if @{ $self->{queue} };
    unless ($HOLD) {
      Scalar::Util::weaken(my $weak = $self);
      $self->{cancel_timer} = EV::timer(0.002, 0, sub { $weak->t_answer_cancel(1) if $weak && $weak->{cancel_cb} });
    }
    return;
  }

  # The server's answer to the cancel request arrives now: (1), or the error.
  sub t_answer_cancel {
    my ($self, @answer) = @_;
    Carp::croak('t_answer_cancel: no request is out') unless $self->{cancel_cb};
    delete $self->{cancel_timer};
    my $cb = delete $self->{cancel_cb};
    delete $self->{cancel_open};
    eval { $cb->(@answer); 1 } or warn "EV::Pg: exception in callback: $@";
    return;
  }

  sub t_capability {
    my ($class, $on) = @_;
    no strict 'refs';
    if ($on) { *{'EV::Pg::cancel_async'} = \&_cancel_async }
    else     { delete $EV::Pg::{cancel_async} }
    return;
  }

  sub finish {
    my ($self) = @_;
    # A cancel request that is not through is dropped unsent, and its callback
    # told so (Pg.xs cleanup_cancel, 0.07): the reason a retired connection
    # with a request out is closed only once it is answered.
    delete $self->{cancel_open};
    delete $self->{cancel_timer};
    if (my $cb = delete $self->{cancel_cb}) {
      eval { $cb->(undef, 'connection closed'); 1 } or warn "EV::Pg: exception in callback: $@";
      $self->{cancel_dropped}++;
    }
    $self->_drop_queued('connection finished');
    $self->{up}   = 0;
    $self->{busy} = 0;
    delete $self->{meta};
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

  # handle_conn_loss: torn down -- nothing is in progress on a connection that
  # is gone --, on_error, then every queued callback with "connection lost".
  sub t_lose {
    my ($self, $msg) = @_;
    $self->{up}   = 0;
    $self->{busy} = 0;
    $self->{on_error}->($msg) if $self->{on_error};
    # cleanup_connection ends a request that is out, and tells its callback.
    delete $self->{cancel_open};
    delete $self->{cancel_timer};
    if (my $cb = delete $self->{cancel_cb}) {
      eval { $cb->(undef, 'connection closed'); 1 } or warn "EV::Pg: exception in callback: $@";
    }
    $self->_drop_queued('connection lost');
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $HOLD || $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  # The server's answer to the statement in flight arrives now.
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

    # EV::Pg points result_meta at a successful result before it calls back.
    $self->{meta} = { cmd_status => $tag } if defined $tag;
    # Delivered once the command's last result is read: libpq is idle in the
    # callback, which still counts in pending_count.
    $self->{busy} = 0;
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_arm;
    return;
  }

  # The server's answer to one statement: its command tag, then what EV::Pg
  # hands the callback -- (undef, undef, $error) for an error. A statement that
  # fails aborts the open transaction.
  sub _serve {
    my ($self, $stmt) = @_;
    my ($sql, $name) = @$stmt{qw( sql name )};
    if ($sql eq 'BEGIN') { $self->{intrans} = 1; return ('BEGIN', '') }
    if ($sql eq 'COMMIT') {
      my $aborted = delete $self->{aborted};
      push @COMMITTED, @{ $self->{rows} } unless $aborted;
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      return ($aborted ? 'ROLLBACK' : 'COMMIT', '');
    }
    if ($sql eq 'ROLLBACK') {
      delete $self->{aborted};
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      return ('ROLLBACK', '');
    }
    if ($stmt->{cancelled}) {
      $self->{aborted} = 1 if $self->{intrans};
      return (undef, undef, "ERROR:  canceling statement due to user request\n");
    }
    return (undef, undef, "ERROR:  current transaction is aborted, commands ignored until end of transaction block\n")
      if $self->{aborted};
    if (defined(my $err = $FAIL{$name})) {
      $self->{aborted} = 1 if $self->{intrans};
      return (undef, undef, $err);
    }
    if ($sql =~ /^INSERT/) {
      push @{ $self->{intrans} ? $self->{rows} : \@COMMITTED }, $name;
      return ('INSERT 0 1', [ [ 'row-of', $name ] ]);
    }
    return ('SELECT 1', [ [ 'row-of', $name ] ]) if $sql =~ /^SELECT/;
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

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF = 'DBIO::PostgreSQL::EV::Future';

my $CANCELLED = qr/cancelled before it was answered/;
my $LOST      = "server closed the connection unexpectedly\n";

# The real pool, with every release recorded: which connection came back, and
# in what state -- a statement still in flight on it, a transaction open.
{
  package T55::Pool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{t_released} }, {
      conn      => $conn->{id},
      in_flight => $conn->{busy},
      in_txn    => $conn->{intrans},
    };
    return $self->SUPER::release($conn);
  }
}

# A real storage and pool of one over the fake EV::Pg.
sub pool_of_one {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  bless $storage->pool, 'T55::Pool';
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the EV loop until $cond holds; false if it does not within 5 seconds.
sub spin_until {
  my ($cond) = @_;
  EV::now_update();
  my $late = 0;
  my $dog  = EV::timer(5, 0, sub { $late = 1 });
  EV::run(EV::RUN_ONCE()) until $late || $cond->();
  return !$late;
}

# Let every timer the fake still has run out, so a callback that would fire
# late -- and release a second time -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The server's answer to the statement in flight on $conn arrives now. With
# nothing in flight there is nothing to deliver, and that is a failure.
sub deliver {
  my ($conn) = @_;
  return $conn->t_deliver if $conn->pending_count;
  fail 'a result was due on the connection, but nothing is in flight on it';
  return;
}

sub the_conn { $_[0]->pool->{_connections}[0] }
sub wire     { [ @{ $_[0]{wire} } ] }
sub released { [ @{ $_[0]->pool->{t_released} || [] } ] }
sub clean    { { conn => $_[0]{id}, in_flight => 0, in_txn => 0 } }

sub select_named { $_[0]->select_async('thing', [qw( tag name )], { name => $_[1] }) }
sub insert       { $_[0]->insert_async('thing', { name => $_[1] }) }

# A pool of one whose connection is spawned and idle, a clean wire, a clean
# server, nothing released yet.
sub fresh {
  my $storage = pool_of_one();
  my ($ok, @r) = wait_for(select_named($storage, 'warm'));
  die "warming the pool failed: $r[0]" unless $ok;
  settle();
  my $conn = the_conn($storage);
  @{ $conn->{wire} } = ();
  @{ $storage->pool->{t_released} } = ();
  @EV::Pg::COMMITTED = ();
  @warnings = ();
  return ($storage, $conn);
}

# The state of a Future, and what it settled with.
sub state_of {
  my ($f) = @_;
  return !$f->is_ready ? 'pending' : $f->is_cancelled ? 'cancelled' : $f->is_failed ? 'failed' : 'done';
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::Pg, nothing warned";
  @warnings = ();
}

# With results delivered again: the pool has its one connection, idle, with no
# transaction open and no result due -- and the next call runs on it and gets
# its own rows.
sub next_call_is_its_own {
  my ($label, $storage, $conn) = @_;
  local $EV::Pg::HOLD = 0;
  settle();
  is $storage->pool->size, 1, "$label: the pool still has its one connection";
  is $storage->pool->available, 1, "$label: idle";
  is $conn->transaction_status, 0, "$label: IDLE -- no transaction open, nothing in flight";
  is $conn->pending_count, 0, "$label: no result due";

  my $before = @{ released($storage) };
  my ($ok, @r) = wait_for(select_named($storage, 'next'));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  is $conn->{wire}[-1], 'next', "$label: on the same connection";
  settle();
  is @{ released($storage) } - $before, 1, "$label: and releases it once";
  is $storage->pool->available, 1, "$label: idle again";
  nothing_warned($label);
}

# --- 1. pooled: cancelled in flight, then its result arrives --------------------

for my $temp (qw( warm cold )) {
  my $label = "pooled, $temp pool";
  my ($storage, $conn) = $temp eq 'warm' ? fresh() : (pool_of_one());
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  if ($temp eq 'cold') {
    ok spin_until(sub { ($conn = the_conn($storage)) && @{ $conn->{wire} } }),
      "$label: the connection came up and the statement was sent"
      or next;
  }
  is_deeply wire($conn), ['q1'], "$label: the statement is in flight";

  $q1->cancel;
  is state_of($q1), 'cancelled', "$label: the caller's Future is cancelled";
  is_deeply released($storage), [],
    "$label: the cancel releases nothing -- libpq is still busy with the statement";
  is $storage->pool->available, 0, "$label: the connection is not idle while its result is due";
  is $conn->pending_count, 1, "$label: EV::Pg still holds the statement's callback";

  deliver($conn);
  is_deeply released($storage), [ clean($conn) ],
    "$label: the late result releases the connection, once, with nothing in flight";
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled";

  next_call_is_its_own($label, $storage, $conn);
  is_deeply wire($conn), [qw( q1 next )], "$label: nothing else went on the wire";
}

# --- 2. pooled, pool of one: the next call is issued before the late result -----

for my $order ('cancel, then the next call', 'the next call, then cancel') {
  my $label = "pool of one, $order";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  my $q2;
  if ($order =~ /^cancel/) {
    $q1->cancel;
    $q2 = select_named($storage, 'q2');
  }
  else {
    $q2 = select_named($storage, 'q2');
    $q1->cancel;
  }
  is state_of($q1), 'cancelled', "$label: the first call is cancelled";
  is_deeply wire($conn), ['q1'],
    "$label: the next call is not sent -- the connection is not handed out before the late result";
  is_deeply released($storage), [], "$label: nothing is released yet";
  is state_of($q2), 'pending', "$label: the next call waits";

  deliver($conn);   # the cancelled statement's result
  is state_of($q2), 'pending', "$label: the late result does not settle the next call";
  is_deeply wire($conn), [qw( q1 q2 )], "$label: the next call is sent now, on that connection";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the late result released the connection once, with nothing in flight";
  is $storage->pool->available, 0, "$label: it went straight to the waiting call, not to the idle list";

  deliver($conn);   # the next call's own result
  is state_of($q2), 'done', "$label: the next call completes"
    or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it did not settle';
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ], "$label: with its own rows";
  is state_of($q1), 'cancelled', "$label: the first call stays cancelled";
  is_deeply released($storage), [ clean($conn), clean($conn) ], "$label: one release for each call";

  next_call_is_its_own($label, $storage, $conn);
}

# --- 3. pooled: the late answer is an error, or the connection is lost ----------

{
  my $label = 'late server error';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;
  local $EV::Pg::FAIL{q1} = qq{ERROR:  relation "thing" does not exist\n};

  my $q1 = select_named($storage, 'q1');
  $q1->cancel;
  deliver($conn);
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled, it does not fail";
  is_deeply released($storage), [ clean($conn) ], "$label: the connection is released once";
  ok $conn->is_connected, "$label: the session survived";

  next_call_is_its_own($label, $storage, $conn);
}

{
  my $label = 'connection lost';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  $q1->cancel;
  my $q2 = select_named($storage, 'q2');

  $conn->t_lose($LOST);
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the lost connection is handed back once";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: and retired, not idled";
  is $storage->pool->available, 0, "$label: nothing is idle";
  like join('', @warnings), qr/pool error: \Q$LOST\E/, "$label: the pool reported the loss";
  @warnings = ();

  my $fresh;
  ok spin_until(sub { ($fresh = the_conn($storage)) && @{ $fresh->{wire} } }),
    "$label: the waiting call got a connection"
    or last;   # nothing to look at without one
  isnt $fresh->{id}, $conn->{id}, "$label: a fresh one";
  is_deeply wire($conn), ['q1'], "$label: nothing more was sent on the lost one";
  is_deeply wire($fresh), ['q2'], "$label: the waiting call was sent on the fresh one";
  deliver($fresh);
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ],
    "$label: and completes with its own rows";
  is_deeply released($storage), [ clean($conn), clean($fresh) ], "$label: one release for each call";

  next_call_is_its_own($label, $storage, $fresh);
}

# --- 4. pinned: a statement of a txn_do_async coderef cancelled in flight -------

# The transaction is at the point where its coderef has run and its statement
# 'doomed' is in flight, cancelled; $txn must now roll back behind it.
sub rolls_back_behind {
  my ($label, $storage, $conn, $txn, $stmt, $error) = @_;

  is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";
  is_deeply wire($conn), [qw( BEGIN doomed )],
    "$label: ROLLBACK is not sent while the cancelled statement is in flight";
  is state_of($txn), 'pending', "$label: the transaction waits";
  is_deeply released($storage), [], "$label: the connection stays pinned";

  deliver($conn);   # the cancelled statement's result
  is_deeply wire($conn), [qw( BEGIN doomed ROLLBACK )],
    "$label: the late result sends ROLLBACK, not COMMIT";
  is state_of($txn), 'pending', "$label: the late result does not end the transaction";
  is_deeply released($storage), [], "$label: still pinned while ROLLBACK is in flight";

  deliver($conn);   # ROLLBACK's
  is state_of($txn), 'failed', "$label: the transaction fails";
  if (ref $error) { like $txn->is_failed ? $txn->failure : '', $error, "$label: saying a statement was cancelled" }
  else            { is   $txn->is_failed ? $txn->failure : '', $error, "$label: with the error that cancelled it" }
  is state_of($stmt), 'cancelled', "$label: the statement stays cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
  is_deeply wire($conn), [qw( BEGIN doomed ROLLBACK next )], "$label: nothing else went on the wire";
}

for my $when ('in the coderef', 'after the coderef returned') {
  my $label = "txn, cancelled $when";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = insert($ctx, 'doomed');
    $stmt->cancel if $when eq 'in the coderef';
    return 'gave up';
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  $stmt->cancel if $when ne 'in the coderef';

  rolls_back_behind($label, $storage, $conn, $txn, $stmt, $CANCELLED);
}

{
  my $label = 'txn, lost a wait_any';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($stmt, $timeout);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt    = insert($ctx, 'doomed');
    $timeout = $EVF->new;
    return $EVF->wait_any($stmt, $timeout);
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  $timeout->fail("timed out\n");

  rolls_back_behind($label, $storage, $conn, $txn, $stmt, "timed out\n");
}

# --- 5. pinned: the statement queued behind the cancelled one -------------------

{
  my $label = 'txn, a statement behind the cancelled one';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($doomed, $behind);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $doomed = insert($ctx, 'doomed');
    $behind = select_named($ctx, 'behind');   # a SELECT: its rows come off the wire
    return $behind;
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  is_deeply wire($conn), [qw( BEGIN doomed )], "$label: the second statement waits for the first";

  $doomed->cancel;
  is_deeply wire($conn), [qw( BEGIN doomed )],
    "$label: the cancel sends nothing -- the cancelled statement is still in flight";

  deliver($conn);   # the cancelled statement's result
  is_deeply wire($conn), [qw( BEGIN doomed behind )], "$label: the late result sends the statement behind it";
  is state_of($behind), 'pending', "$label: and does not settle it";

  deliver($conn);   # the second statement's own result
  is state_of($behind), 'done', "$label: the statement behind completes";
  is_deeply [ $behind->is_done ? $behind->get : () ], [ [ 'row-of', 'behind' ] ],
    "$label: with its own rows";
  is_deeply wire($conn), [qw( BEGIN doomed behind ROLLBACK )],
    "$label: then ROLLBACK -- a statement of the transaction was cancelled";
  is_deeply released($storage), [], "$label: the connection stays pinned";

  deliver($conn);   # ROLLBACK's
  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : '', $CANCELLED, "$label: saying a statement was cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
}

# --- 6. pinned: cancelled while it waits behind another statement ---------------

{
  my $label = 'txn, cancelled while queued';
  my ($storage, $conn) = fresh();

  my ($first, $queued);
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = insert($ctx, 'first');
    $queued = insert($ctx, 'queued');
    $queued->cancel;
    return $first;
  }));
  settle();
  ok !$ok, "$label: the transaction fails";
  like $ok ? '' : "$err", $CANCELLED, "$label: saying a statement was cancelled";
  is state_of($first), 'done', "$label: the statement in flight completed";
  is state_of($queued), 'cancelled', "$label: the cancelled one stays cancelled";
  is_deeply wire($conn), [qw( BEGIN first ROLLBACK )],
    "$label: the statement in flight ran, the one cancelled in the queue was skipped (karr k75), ROLLBACK ended it";
  ok !grep({ $_ eq 'COMMIT' } @{ wire($conn) }), "$label: COMMIT was never sent";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
}

# --- 6b. pinned: the COMMIT / ROLLBACK of core, cancelled in the queue, is sent --
#
# The queue knows it as the end of the transaction (karr k75). Skipping it would
# leave the backend idle in transaction, with its locks.

for my $end (qw( ROLLBACK COMMIT )) {
  my $label = "txn, $end cancelled while queued";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($first, $ending);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = insert($ctx, 'first');
    $ending = $storage->_query_async_pinned($conn, $end);
    $ending->cancel;
    return $first;
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  is_deeply wire($conn), [qw( BEGIN first )], "$label: the statement in flight is on the wire";
  deliver($conn);   # first's result: the queue goes on
  is state_of($ending), 'cancelled', "$label: the cancelled one stays cancelled";
  is_deeply wire($conn), [ qw( BEGIN first ), $end ],
    "$label: $end was sent all the same, the transaction does not stay open";
  deliver($conn);   # the ending's result
  settle();
  ok !$conn->{intrans}, "$label: no transaction open on the server";
}

# --- 8. the coderef returned the cancelled Future -------------------------------
#
# Future.pm runs no ->then callback of a cancelled Future, so the end of the
# transaction cannot hang off one. Core answers the cancel itself (core k274,
# ADR 0055 addendum): ROLLBACK best-effort and not waited for, the connection
# retired, the transaction failed. The late result of the cancelled statement
# then has no one to go to.

{
  my $label = 'txn, the coderef returned the cancelled Future';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = insert($ctx, 'doomed');
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  is_deeply wire($conn), [qw( BEGIN doomed )], "$label: the INSERT is in flight";
  $stmt->cancel;
  is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";

  # The wire answers whatever it still owes.
  for (1 .. 3) {
    last unless $conn->pending_count;
    $conn->t_deliver;
  }
  settle();
  is state_of($txn), 'failed', "$label: the transaction fails, it does not stay pending";
  like $txn->is_failed ? ($txn->failure)[0] : '', qr/Transaction cancelled/,
    "$label: saying it was cancelled";
  is_deeply released($storage), [], "$label: the connection is not released into the pool";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }),
    "$label: it is retired: the pool holds it no more";
  ok !$conn->is_connected, "$label: and closed, not left with the transaction open";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";

  # The slot went to a fresh connection: the next call is its own.
  $EV::Pg::HOLD = 0;
  my ($next_ok, @rows) = wait_for(select_named($storage, 'after'));
  ok $next_ok, "$label: the next call is served";
  is_deeply \@rows, [ [ 'row-of', 'after' ] ], "$label: with its own rows";
  isnt the_conn($storage)->{id}, $conn->{id}, "$label: on a fresh connection";
  nothing_warned($label);
}

# === karr k75: with EV::Pg's cancel_async (libpq 17+) a cancel asks the server ====
#
# Sections 1 to 8 ran on a stack WITHOUT cancel_async (`can` says no): the
# transport sends no request, the connection is held until the statement's
# result. From here the stack has it. The claims:
#   9.  pooled: the cancel sends exactly one request, never the blocking
#       cancel; the connection is released only once the statement's result AND
#       the request's answer are in, in either order; the next call, waiting on
#       a pool of one, is sent after that and gets its own rows -- the fake
#       lands a request that is still open on the next statement the
#       connection runs, as the server does (karr k75: 151 of 185 through the
#       pool when the release did not wait);
#   10. a request that is answered with an error retires the connection, in
#       either order; a connection lost with the request out is retired and
#       does not wait for an answer that will not come;
#   11. pinned: ROLLBACK, and the statement queued behind, go out only once
#       result and answer are in; a request that fails retires the connection
#       when the transaction hands it back;
#   12. no request for a statement that is not in flight (cancelled while it
#       waits in the pinned queue), none in pipeline mode, one per Future;
#   13. core k274 over the capability: a transaction's cancel, or the cancel
#       of the Future its coderef returned, with a request out, retires the
#       connection once and reports nothing dead that is not.
# The blocking cancel does not exist in the fake: a call to it dies.

EV::Pg->t_capability(1);
{
  no warnings 'once';
  *EV::Pg::cancel = sub { die "the blocking cancel was called\n" };
}

sub requests { scalar @{ $_[0]{cancels} || [] } }

# --- 9. pooled, with the capability ---------------------------------------------

for my $order ('the result, then the answer', 'the answer, then the result') {
  my $label = "capability, pool of one, $order";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  my $q2 = select_named($storage, 'q2');
  $q1->cancel;
  $q1->cancel;
  is state_of($q1), 'cancelled', "$label: the caller's Future is cancelled";
  is requests($conn), 1, "$label: exactly one cancel request, however often the Future is cancelled";
  is_deeply released($storage), [], "$label: nothing is released";
  is_deeply wire($conn), ['q1'], "$label: the next call is not sent";

  my $result = sub {
    deliver($conn);   # the cancelled statement's result: 57014
    is state_of($q1), 'cancelled', "$label: the Future stays cancelled, the 57014 is dropped";
  };
  my $answer = sub { $conn->t_answer_cancel(1) };
  my ($first, $second) = $order =~ /^the result/ ? ($result, $answer) : ($answer, $result);

  $first->();
  is_deeply released($storage), [],
    "$label: one of the two is in -- the connection is still held";
  is_deeply wire($conn), ['q1'], "$label: and the next call is still not sent";
  is $storage->pool->available, 0, "$label: nothing is idle";

  $second->();
  is_deeply released($storage), [ clean($conn) ],
    "$label: both are in: released, once, with nothing in flight";
  is_deeply wire($conn), [qw( q1 q2 )], "$label: the next call is sent now";

  deliver($conn);
  is state_of($q2), 'done', "$label: the next call completes -- the request did not reach it"
    or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it did not settle';
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ], "$label: with its own rows";
  is requests($conn), 1, "$label: and sent no request of its own";
  next_call_is_its_own($label, $storage, $conn);
}

{
  my $label = 'capability, no next call';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  $q1->cancel;
  deliver($conn);
  is $storage->pool->available, 0, "$label: the result alone does not release";
  $conn->t_answer_cancel(1);
  is_deeply released($storage), [ clean($conn) ], "$label: the answer completes it";
  next_call_is_its_own($label, $storage, $conn);
}

{
  my $label = 'capability, the statement finished before the cancel could stop it';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  $q1->cancel;
  $conn->{queue}[0]{cancelled} = 0;   # the server had already ended it
  deliver($conn);
  is_deeply released($storage), [], "$label: held for the answer all the same";
  $conn->t_answer_cancel(1);
  is_deeply released($storage), [ clean($conn) ], "$label: released with it";
  next_call_is_its_own($label, $storage, $conn);
}

# --- 10. a request that fails ---------------------------------------------------

for my $order ('the result, then the failed answer', 'the failed answer, then the result') {
  my $label = "capability, $order";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  my $q2 = select_named($storage, 'q2');
  $q1->cancel;

  my $result = sub { deliver($conn) };
  my $answer = sub { $conn->t_answer_cancel(undef, "could not send cancel request\n") };
  my ($first, $second) = $order =~ /^the result/ ? ($result, $answer) : ($answer, $result);
  $first->();
  is_deeply released($storage), [], "$label: held until both are in";
  $second->();

  is_deeply released($storage), [ clean($conn) ], "$label: handed back once";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: and retired, not idled";
  state_of($q1) eq 'cancelled' or fail "$label: the Future stays cancelled";

  my $fresh;
  ok spin_until(sub { ($fresh = the_conn($storage)) && @{ $fresh->{wire} } }),
    "$label: the waiting call got a connection"
    or last;
  isnt $fresh->{id}, $conn->{id}, "$label: a fresh one";
  is_deeply wire($conn), ['q1'], "$label: nothing more was sent on the retired one";
  deliver($fresh);
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ], "$label: it gets its own rows";
  @warnings = ();
}

{
  my $label = 'capability, connection lost with the request out';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $q1 = select_named($storage, 'q1');
  my $q2 = select_named($storage, 'q2');
  $q1->cancel;
  is requests($conn), 1, "$label: the request is out";

  $conn->t_lose($LOST);   # the request is never answered
  is_deeply released($storage), [ clean($conn) ], "$label: the connection is handed back, once, not waited for";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: and retired";
  state_of($q1) eq 'cancelled' or fail "$label: the Future stays cancelled";

  my $fresh;
  ok spin_until(sub { ($fresh = the_conn($storage)) && @{ $fresh->{wire} } }),
    "$label: the waiting call got a connection"
    or last;
  deliver($fresh);
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ], "$label: with its own rows";
  @warnings = ();
}

# --- 11. pinned: a transaction's statement cancelled in flight -------------------

for my $order ('the result, then the answer', 'the answer, then the result') {
  my $label = "capability, txn, $order";
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my ($doomed, $behind);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $doomed = insert($ctx, 'doomed');
    $behind = select_named($ctx, 'behind');
    return $behind;
  });
  deliver($conn);   # BEGIN's result: the coderef runs
  $doomed->cancel;
  is requests($conn), 1, "$label: one cancel request for the statement in flight";

  my $result = sub { deliver($conn) };
  my $answer = sub { $conn->t_answer_cancel(1) };
  my ($first, $second) = $order =~ /^the result/ ? ($result, $answer) : ($answer, $result);
  $first->();
  is_deeply wire($conn), [qw( BEGIN doomed )],
    "$label: the statement behind it is not sent while one of the two is missing";
  $second->();
  is_deeply wire($conn), [qw( BEGIN doomed behind )], "$label: it is sent when both are in";
  is state_of($behind), 'pending', "$label: and not settled by the late result";

  deliver($conn);
  # The server cancelled the INSERT inside the transaction: the transaction is
  # aborted, and that is what the statement behind is told. The request hit
  # nobody else -- "user request" would be its answer if it had.
  is state_of($behind), q{failed}, "$label: the statement behind is answered by the server";
  like $behind->is_failed ? $behind->failure : q{}, qr/current transaction is aborted/,
    "$label: with the aborted transaction, not with the cancel request -- the request did not reach it";
  deliver($conn);   # ROLLBACK
  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : q{}, qr/current transaction is aborted/, "$label: with that error";
  is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";
  is_deeply released($storage), [ clean($conn) ], "$label: the connection comes back once, idle";
  is $storage->pool->available, 1, "$label: and is kept";
  is requests($conn), 1, "$label: no further request";
}

{
  my $label = 'capability, txn, the request fails';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $doomed;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $doomed = insert($ctx, 'doomed');
    return 'gave up';
  });
  deliver($conn);
  $doomed->cancel;
  deliver($conn);
  $conn->t_answer_cancel(undef, "could not send cancel request\n");
  is_deeply wire($conn), [qw( BEGIN doomed ROLLBACK )], "$label: the transaction is still rolled back";
  deliver($conn);
  is state_of($txn), 'failed', "$label: the transaction fails";
  is_deeply released($storage), [ clean($conn) ], "$label: the connection comes back once";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: retired, not kept";
}

# --- 12. no request ----------------------------------------------------------------

{
  my $label = 'capability, cancelled while queued';
  my ($storage, $conn) = fresh();

  my ($first, $queued);
  wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = insert($ctx, 'first');
    $queued = insert($ctx, 'queued');
    $queued->cancel;
    return $first;
  }));
  settle();
  is state_of($queued), 'cancelled', "$label: the queued statement is cancelled";
  is requests($conn), 0, "$label: no request -- it was not in flight, and a request would hit a bystander";
  is_deeply released($storage), [ clean($conn) ], "$label: the connection comes back once";
}

{
  my $label = 'capability, pipeline mode';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $pg = (wait_for($storage->pool->acquire))[1];
  $storage->_pipeline_enter($pg);
  my $q = $storage->_query_async_pinned($pg, 'SELECT ?', ['piped']);
  is_deeply wire($conn), ['piped'], "$label: the statement is on the wire";
  $q->cancel;
  is state_of($q), 'cancelled', "$label: cancelled";
  is requests($conn), 0, "$label: no request in pipeline mode";
  deliver($conn);
  $conn->{busy} = 0;
  $storage->_pipeline_exit($pg);
  $storage->pool->release($pg);
  is requests($conn), 0, "$label: none afterwards either";
  @warnings = ();
}

# --- 13. core k274 over the capability: a cancel that retires the connection ----
#
# Core answers the cancel of a transaction's Future, or of the Future its
# coderef returned, by sending ROLLBACK unwaited and retiring the connection
# (core k274). With the capability the statement in flight must still be asked
# to stop: EV::Pg's finish drops a cancel request that is not through yet, so
# the pool's close of a retired connection with a statement in flight waits
# for the request's answer (Pool.pm _shutdown_connection). Measured live
# (t/61, section 10): 13 ms to the end of a pg_sleep(3) with the request
# answered first, 3 s without. What is claimed:
#   - exactly one request, whichever of the two ways noticed the cancel first;
#   - the connection leaves the pool at once -- never released, its slot to a
#     fresh connection -- but is closed only when the answer is in (or it was
#     lost), however that answer, or the cancelled statement's result, comes;
#   - what is owed on the retired connection reports nothing dead that is not,
#     no callback dies out of EV::Pg, nothing warns, and COMMIT is never sent.

for my $how ('the coderef returned the cancelled Future', 'the transaction itself is cancelled') {
  for my $case (
    [ 'the answer'                   => sub { $_[0]->t_answer_cancel(1) } ],
    [ 'a failed answer'              => sub { $_[0]->t_answer_cancel(undef, "could not send cancel request\n") } ],
    [ 'the result, then the answer'  => sub { deliver($_[0]); $_[0]->t_answer_cancel(1) } ],
    [ 'the connection lost'          => sub { $_[0]->t_lose($LOST); @warnings = () } ],
  ) {
    my ($owed, $arrives) = @$case;
    my $label = "capability, txn, $how, $owed";
    my ($storage, $conn) = fresh();
    local $EV::Pg::HOLD = 1;

    my $stmt;
    my $txn = $storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $stmt = insert($ctx, 'doomed');
    });
    deliver($conn);   # BEGIN's result: the coderef runs
    $how =~ /^the coderef/ ? $stmt->cancel : $txn->cancel;
    is requests($conn), 1, "$label: exactly one cancel request for the statement in flight";
    is state_of($txn), $how =~ /^the coderef/ ? 'failed' : 'cancelled',
      "$label: the transaction's Future is settled";
    ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: its connection is retired";
    is_deeply released($storage), [], "$label: and not released";
    ok $conn->is_connected, "$label: but not closed while the request is out -- finish would drop it unsent"
      unless $owed eq 'the connection lost';

    $arrives->($conn);
    ok !$conn->is_connected, "$label: closed once it is answered";
    ok !$conn->{cancel_dropped}, "$label: the request was never dropped unsent";
    is requests($conn), 1, "$label: and no second request";
    ok !grep({ $_ eq 'COMMIT' } @{ wire($conn) }), "$label: COMMIT was never sent";
    is_deeply \@EV::Pg::COMMITTED, [], "$label: nothing was committed";

    $EV::Pg::HOLD = 0;
    my ($ok, @rows) = wait_for(select_named($storage, 'after'));
    ok $ok, "$label: the next call is served";
    is_deeply \@rows, [ [ 'row-of', 'after' ] ], "$label: with its own rows";
    isnt the_conn($storage)->{id}, $conn->{id}, "$label: on a fresh connection";
    is_deeply released($storage), [ clean(the_conn($storage)) ],
      "$label: which is released once, after the call";
    ok !$storage->pool->_connection_is_dead(the_conn($storage)), "$label: and was not reported dead";
    nothing_warned($label);
  }
}

# Without a request out -- no capability -- the retired connection is closed at
# once, as before.
{
  EV::Pg->t_capability(0);
  my $label = 'no capability, txn, the coderef returned the cancelled Future';
  my ($storage, $conn) = fresh();
  local $EV::Pg::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = insert($ctx, 'doomed');
  });
  deliver($conn);
  $stmt->cancel;
  is state_of($txn), 'failed', "$label: the transaction fails";
  ok !$conn->is_connected, "$label: the retired connection is closed at once";
  EV::Pg->t_capability(1);
}

EV::Pg->t_capability(0);

done_testing;
