use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k55 (core karr k230, core ADR 0047 addendum
# 2026-09-27): a pooled connection that is gone is retired, never handed out
# again.
#
# WHY IT MATTERS. The pool cannot see a connection die. A session the server
# ended -- KILL, a restart, wait_timeout -- fails the statement that finds it
# so, and the transport then hands the handle back like any other. Back on the
# idle list, it goes to the next caller, whose statement fails the same way,
# and to the one after that: one dead session turns into a row of failed calls
# for as long as the process lives. Core's pool retires a connection reported
# to it through _mark_connection_dead instead of putting it back -- this file
# holds that the transport makes that report, and only for a connection that
# is in fact gone: a statement error the session survives must leave the
# connection in the pool, or every duplicate key would cost a reconnect.
#
# THE DECISION this file pins (section 1): the HANDLE decides, never the error
# text. A connection is gone when
#   - its handle has no socket (EV::MariaDB's socket is -1: never connected,
#     finished, or the client library gave the socket up when an operation
#     found the server gone), or
#   - nothing is in flight on it and its socket is readable. A MySQL server
#     never speaks unasked, so that is the server hanging up.
# Not consulted: is_connected, which stays true after the server ended the
# session and after an operation failed on it (ADR 0010, fact 3, measured);
# and the message, whose wording is the client library's, or the server's in
# its lc_messages.
#
# What this file claims:
#   1. the decision above, each criterion with an example either way;
#   2. a pooled statement that fails on a gone connection -- by either
#      criterion -- has it retired: the pool holds the connection no longer
#      and frees the handle, the next call runs on a newly opened one, and a
#      caller queued for the slot gets a newly opened one too -- never the
#      dead handle, which is what "reported BEFORE the release" buys;
#   3. a statement error the session survives -- whatever its text says --
#      leaves the connection in the pool, and the next call runs on it;
#   4. the same two for insert_async, whose INSERT and LAST_INSERT_ID() run
#      pinned on one pooled connection, whichever of the two finds it gone;
#   5. the same two for a transaction: a connection that dies in the middle of
#      one is retired when the transaction hands it back;
#   6. a statement EV::MariaDB refuses to dispatch ("not connected") on a
#      handle that is gone is reported as well, pooled and pinned;
#   7. the connection's on_error: a loss it reports retires an idle connection
#      at once and a checked-out one when it is handed back; an error it
#      reports on a session that is still there (EV::MariaDB sends the error
#      of a secondary result set this way) retires nothing; the pool's own
#      error report runs either way;
#   8. a statement that fails on a handle of a storage that has no pool fails
#      with its own error and builds no pool to report to;
#   9. a connection that is gone while it sits idle -- by either criterion --
#      is not handed out (karr k58, core karr k241): the call that would have
#      found it gone completes on the next idle connection that is still
#      there, or on a newly opened one, and no call fails. A connection that
#      is still there is handed out as it is: the check sends nothing, reads
#      nothing, and performs no operation on the handle.
#
# WHAT RUNS FOR REAL: core's pool and transaction machinery, this dist's
# Storage, Pool (_new_connection included -- the fake is the class it
# constructs), QueryExecutor and Future, and EV. THE ONE SUBSTITUTION is
# EV::MariaDB. The fake answers every operation from an EV timer and models
# what the real client does around a lost session, each as measured for ADR
# 0010 (fact 3) or read from EV::MariaDB 0.08's XS:
#   - its socket is one end of a real socketpair; the server ending the
#     session closes the other end, so the client end reads EOF;
#   - the operation that finds the session ended fails through its callback
#     and the socket is given up (-1); is_connected stays true;
#   - pending_count is taken down before a callback runs;
#   - an operation on a handle without a connection croaks "not connected";
#   - close_async without a callback croaks, as the XS does.

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Socket ();
  use Scalar::Util ();

  our @MADE;    # every handle made, in order (weak)
  our @FREED;   # the serial of every handle that was freed
  our @WIRE;    # [ serial, sql ] of every statement that reached a handle
  our @TRIED;   # [ serial, sql ] of every ROLLBACK handed to a handle, refused or not
  my $serial = 0;

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $self = bless {
      serial     => ++$serial,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      client     => $client,
      server     => $server,
      conn       => 1,
      connected  => 0,
      pending    => 0,
      stmts      => {},
      next       => 0,
      fail       => [],
      ops        => 0,
    }, $class;
    push @MADE, $self;
    Scalar::Util::weaken($MADE[-1]);
    _later(sub { $self->{connected} = 1; $self->{on_connect}->() if $self->{on_connect} });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub _answer {
    my ($sql) = @_;
    return ([ [ 7 ] ])        if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ]) if $sql =~ /^SELECT/;
    return (1)                if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub serial        { $_[0]{serial} }
  sub is_connected  { $_[0]{conn} && $_[0]{connected} ? 1 : 0 }   # true after death, as the real one
  sub pending_count { $_[0]{pending} }
  sub socket        { $_[0]{conn} && $_[0]{client} ? fileno $_[0]{client} : -1 }

  # One operation. $sql is undef for one that sends no statement text.
  sub _op {
    my ($self, $sql, $cb, $answer) = @_;
    $self->{ops}++;
    push @TRIED, [ $self->{serial}, $sql ] if defined $sql && $sql =~ /^ROLLBACK/;
    Carp::croak('not connected') unless $self->{conn};
    $self->t_end_session if defined $sql && $self->{end_before} && $sql =~ $self->{end_before};
    $self->t_hang_up     if defined $sql && $self->{hang_up_before} && $sql =~ $self->{hang_up_before};
    push @WIRE, [ $self->{serial}, $sql ] if defined $sql;
    $self->{pending}++;
    _later(sub {
      $self->{pending}--;
      $cb->($self->_outcome($answer));
    });
    return;
  }

  sub _outcome {
    my ($self, $answer) = @_;
    if ($self->{ended}) {
      # The client library finds the session ended and gives its socket up.
      my $had = delete $self->{client};
      close $had if $had;
      return (undef, $self->{lost_text} // ($had ? 'Lost connection to server during query' : 'Server has gone away'));
    }
    if (defined(my $msg = shift @{ $self->{fail} })) { return (undef, $msg) }
    return $answer->();
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    return $self->_op($sql, $cb, sub { _answer($sql) });
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    return $self->_op($sql, $cb, sub { my $id = ++$self->{next}; $self->{stmts}{$id} = $sql; ($id) });
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    return $self->_op(undef, $cb, sub { _answer($sql) });
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    return $self->_op(undef, $cb, sub { delete $self->{stmts}{$id}; (1) });
  }

  # COM_RESET_CONNECTION, sent by the pool at the end of every borrow (karr
  # k100, core k398): no statement text, so not on the wire. A session that
  # ended answers it with the error every operation gets (_outcome).
  sub reset_connection {
    my ($self, $cb) = @_;
    return $self->_op(undef, $cb, sub { (1) });
  }

  sub finish {
    my ($self) = @_;
    Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1;
    $self->{ops}++;
    $self->{conn} = 0;
    my $had = delete $self->{client};
    close $had if $had;
    return;
  }

  sub close_async {
    my ($self, $cb) = @_;
    $self->{ops}++;
    Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2;
    Carp::croak('not connected') unless $self->{conn};
    $self->finish;
    $cb->(1);
    return;
  }

  sub DESTROY { push @FREED, $_[0]{serial} }

  # --- the server's side, and the client library's ---------------------------

  # The server ends the session (KILL, a restart, wait_timeout): the client's
  # socket reads EOF, and every operation from here on finds the session gone.
  sub t_end_session {
    my ($self) = @_;
    my $server = delete $self->{server};
    close $server if $server;
    $self->{ended} = 1;
    return;
  }

  # The server closes its end and nothing else: the client's socket reads EOF,
  # and the client library has not found out.
  sub t_hang_up {
    my ($self) = @_;
    my $server = delete $self->{server};
    close $server if $server;
    return;
  }

  # The server ends the session just before the first statement matching $re:
  # after the pool looked at the idle connection and handed it out, which is
  # the death a statement finds and the borrow-time check cannot (section 9).
  sub t_end_before { $_[0]{end_before} = $_[1]; return }

  # The server closes its end, and nothing else, at that same moment.
  sub t_hang_up_before { $_[0]{hang_up_before} = $_[1]; return }

  # The next operation is answered with an error; the session goes on.
  sub t_fail_next { push @{ $_[0]{fail} }, $_[1]; return }

  # The client library gives its socket up, outside any statement of ours.
  sub t_lose_socket {
    my ($self) = @_;
    my $had = delete $self->{client};
    close $had if $had;
    return;
  }

  # EV::MariaDB calls the handle's on_error.
  sub t_error { $_[0]{on_error}->($_[1]) if $_[0]{on_error}; return }

  $INC{'EV/MariaDB.pm'} = __FILE__;
}

use Scalar::Util 'refaddr';
use DBIO::Storage::PoolBase;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

plan skip_all => 'the installed DBIO core predates _mark_connection_dead (core k230)'
  unless DBIO::Storage::PoolBase->can('_mark_connection_dead');

alarm 120;

my @POOLS;
# A real storage, pool and executor over the fake handle.
sub pool_of {
  my ($size) = @_;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => $size }, {} ]);
  push @POOLS, $storage->pool;
  Scalar::Util::weaken($POOLS[-1]);
  return $storage;
}

# The sessions of released connections are reset before the connections go on
# (karr k100, core k398): a call has ended for the pool when no reset is left.
sub reset_done {
  my $dog = EV::timer(2, 0, sub {});
  EV::run(EV::RUN_ONCE()) while $dog->is_active
    && grep { $_ && %{ $_->{_resetting} || {} } } @POOLS;
  return;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run one call to its end: ($ok, \@result_or_error, \@serials), the serials
# being those of the handles its statements reached, in order, each once.
sub run_call {
  my ($call) = @_;
  @EV::MariaDB::WIRE = ();
  my ($ok, @r) = wait_for($call->());
  reset_done();
  my (%seen, @serials);
  for my $sent (@EV::MariaDB::WIRE) { push @serials, $sent->[0] unless $seen{ $sent->[0] }++ }
  return ($ok, \@r, \@serials);
}

sub freed { my ($serial) = @_; return scalar grep { $_ == $serial } @EV::MariaDB::FREED }

# A storage with a pool of $size and one connection, warmed and idle. Returns
# the storage and that connection's serial; the handle itself is reached
# through the pool, so that nothing here keeps it alive.
sub warmed {
  my ($size) = @_;
  my $storage = pool_of($size);
  my ($ok, $r, $serials) = run_call(sub { $storage->select_async('artist', [qw( id name )]) });
  die "warming the pool failed: $r->[0]" unless $ok;
  return ($storage, $serials->[0]);
}

# The one idle handle of $storage's pool.
sub idle_handle { $_[0]->pool->{_idle}[0] }

# A connected handle no pool holds.
sub free_handle {
  my $h = EV::MariaDB->new(host => 'fake');
  EV::run(EV::RUN_ONCE()) until $h->is_connected;
  return $h;
}

my %CALL = (
  select => sub { my $s = shift; sub { $s->select_async('artist', [qw( id name )]) } },
  update => sub { my $s = shift; sub { $s->update_async('artist', { name => 'x' }, { id => 1 }) } },
  insert => sub { my $s = shift; sub { $s->insert_async('artist', { name => 'y' }) } },
);
my %EXPECT = (
  select => [ [ 1, 'one' ] ],
  update => [ 1 ],
  insert => [ { name => 'y' } ],
);

# The claims for a call that finds its connection gone: it fails with its own
# error, the pool holds and idles nothing, the handle is freed, and the next
# call completes on a newly opened handle.
sub retired_after {
  my ($label, $storage, $dead, $fails, $error, $next, $expect) = @_;
  my $pool = $storage->pool;

  my ($ok, $r, $serials) = run_call($fails);
  ok !$ok, "$label: the call fails";
  like $r->[0], $error, "$label: with its own error";
  is $pool->available, 0, "$label: the dead connection is not put back on the idle list";
  is $pool->size, 0, "$label: the pool holds it no longer";
  ok freed($dead), "$label: and its handle is freed";

  ($ok, $r, $serials) = run_call($next);
  ok $ok, "$label: the next call completes"
    or diag "it failed: $r->[0]";
  is_deeply $r, $expect, "$label: with its result";
  ok @$serials == 1 && $serials->[0] != $dead,
    "$label: on a newly opened connection, not the dead one"
    or diag "served by handle(s) @$serials, the dead one is $dead";
  is $pool->size, 1, "$label: which is the one connection the pool now has";
}

# The claims for a call that fails on a connection that is still there: it
# fails with its own error, the connection is idle again, nothing was freed,
# and the next call completes on the same handle.
sub reused_after {
  my ($label, $storage, $serial, $fails, $error, $next, $expect) = @_;
  my $pool = $storage->pool;

  my ($ok, $r, $serials) = run_call($fails);
  ok !$ok, "$label: the call fails";
  like $r->[0], $error, "$label: with its own error";
  is $pool->available, 1, "$label: its connection is back on the idle list";
  ok !freed($serial), "$label: and was not closed";

  ($ok, $r, $serials) = run_call($next);
  ok $ok, "$label: the next call completes"
    or diag "it failed: $r->[0]";
  is_deeply $r, $expect, "$label: with its result";
  is_deeply $serials, [ $serial ], "$label: on the same connection";
  is $pool->size, 1, "$label: the only one the pool ever opened";
}

# ---------------------------------------------------------------------------
# 1. The decision: the handle decides, never the error text.
# ---------------------------------------------------------------------------

my $check = DBIO::MySQL::EV::Pool->can('_mysql_connection_gone');
ok $check, 'the pool has the socket check, _mysql_connection_gone';

SKIP: {
  skip 'no socket check to ask', 10 unless $check;
  my $pool = pool_of(1)->pool;
  my $gone = sub { $pool->_mysql_connection_gone($_[0]) ? 1 : 0 };

  # -- no socket: gone
  {
    my $h = free_handle();
    is $gone->($h), 0, 'idle, connected, nothing to read: not gone';

    $h->finish;
    is $h->socket, -1, 'premise: a finished handle has no socket';
    is $gone->($h), 1, 'no socket: gone';
  }
  {
    my $h = free_handle();
    $h->t_end_session;
    my $err;
    $h->query('SELECT 1', sub { $err = $_[1] });
    EV::run(EV::RUN_ONCE()) until defined $err;
    ok $h->is_connected && $h->socket == -1,
      'premise: after an operation found the session ended, is_connected is still true and the socket is given up';
    is $gone->($h), 1, 'no socket after a failed operation: gone, whatever is_connected says';
  }

  # -- nothing in flight and the socket readable: gone
  {
    my $h = free_handle();
    $h->t_hang_up;
    ok $h->socket >= 0 && $h->pending_count == 0,
      'premise: the server hung up on an idle handle that still has its socket';
    is $gone->($h), 1, 'idle and the socket readable (the server hung up): gone';
  }

  # -- a statement in flight: its reply is due on the socket
  {
    my $h = free_handle();
    my $answered;
    $h->query('SELECT 1', sub { $answered = 1 });
    syswrite $h->{server}, 'x';
    is $gone->($h), 0, 'a statement in flight and its socket readable: not gone, the reply is due there';
    EV::run(EV::RUN_ONCE()) until $answered;
  }

  # -- the text does not decide
  {
    my $h = free_handle();
    $h->t_fail_next('Lost connection to server during query');
    my $err;
    $h->query('SELECT 1', sub { $err = $_[1] });
    EV::run(EV::RUN_ONCE()) until defined $err;
    like $err, qr/Lost connection/, 'premise: a statement failed with the text of a lost connection';
    is $gone->($h), 0, '... on a handle whose socket is there and quiet: not gone, the text does not decide';
  }
}

# ---------------------------------------------------------------------------
# 2. A pooled statement finds its connection gone.
# ---------------------------------------------------------------------------
#
# In sections 2 to 6 the session ends AFTER the pool handed the connection
# out: a connection that is gone while it sits idle never gets that far
# (section 9), so the death a statement finds is the one in between.

for my $op (qw( select update )) {
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_end_before(qr/^\U$op/);
  retired_after(
    "pooled $op, session ended",
    $storage, $dead,
    $CALL{$op}->($storage), qr/^Lost connection to server during query/,
    $CALL{$op}->($storage), $EXPECT{$op},
  );
}

# The text is not what retires it: a lost session reported in other words.
{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->{lost_text} = 'MySQL server has gone away';
  idle_handle($storage)->t_end_before(qr/^SELECT/);
  retired_after(
    'pooled select, session ended, another wording',
    $storage, $dead,
    $CALL{select}->($storage), qr/^MySQL server has gone away/,
    $CALL{select}->($storage), $EXPECT{select},
  );
}

# The second criterion at work: the statement is answered with an error and
# the server then hangs up. The handle still has its socket, and it reads EOF.
{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_fail_next('Connection was killed');
  idle_handle($storage)->t_hang_up_before(qr/^SELECT/);
  retired_after(
    'pooled select, answered with an error by a server that then hung up',
    $storage, $dead,
    $CALL{select}->($storage), qr/^Connection was killed/,
    $CALL{select}->($storage), $EXPECT{select},
  );
}

# Reported BEFORE the release: a caller queued for the slot of a pool of one
# gets a newly opened connection. Reported after it, the release would have
# handed the dead handle to that caller.
{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_end_before(qr/^SELECT/);

  @EV::MariaDB::WIRE = ();
  my $first  = $storage->select_async('artist', [qw( id name )]);
  my $queued = $storage->select_async('artist', [qw( id name )]);

  my ($ok, @r) = wait_for($first);
  ok !$ok, 'a queued caller: the call that found the connection gone fails';

  ($ok, @r) = wait_for($queued);
  ok $ok, 'a queued caller: the caller waiting for the slot completes'
    or diag "it failed: $r[0]";
  is_deeply \@r, $EXPECT{select}, 'a queued caller: with its result';
  my @served = grep { $_ != $dead } map { $_->[0] } @EV::MariaDB::WIRE;
  is scalar @served, 1, 'a queued caller: on a newly opened connection';
  is $storage->pool->size, 1, 'a queued caller: the pool is back at one connection';
  ok freed($dead), 'a queued caller: the dead handle is freed';
}

# ---------------------------------------------------------------------------
# 3. A statement error the session survives.
# ---------------------------------------------------------------------------

for my $case (
  [ select => "Table 'fake.artist' doesn't exist",        qr/^Table 'fake\.artist' doesn't exist/ ],
  # The statement's own error arrives, with the value masked (ADR 0075 of the core).
  [ update => "Duplicate entry '1' for key 'PRIMARY'",   qr/^Duplicate entry '\*\*\*'/ ],
  [ select => 'Lost connection to server during query',   qr/^Lost connection/ ],
  [ update => 'Server has gone away',                     qr/^Server has gone away/ ],
) {
  my ($op, $msg, $error) = @$case;
  my ($storage, $serial) = warmed(1);
  idle_handle($storage)->t_fail_next($msg);
  reused_after(
    "pooled $op fails with \"$msg\", session still there",
    $storage, $serial,
    $CALL{$op}->($storage), $error,
    $CALL{$op}->($storage), $EXPECT{$op},
  );
}

# ---------------------------------------------------------------------------
# 4. insert_async: INSERT and LAST_INSERT_ID() pinned on one pooled connection.
# ---------------------------------------------------------------------------

{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_end_before(qr/^INSERT/);
  retired_after(
    'insert_async, session ended before the INSERT',
    $storage, $dead,
    $CALL{insert}->($storage), qr/^Lost connection to server during query/,
    $CALL{insert}->($storage), $EXPECT{insert},
  );
}
{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_end_before(qr/LAST_INSERT_ID/);
  retired_after(
    'insert_async, session ended before LAST_INSERT_ID()',
    $storage, $dead,
    $CALL{insert}->($storage), qr/^Lost connection to server during query/,
    $CALL{insert}->($storage), $EXPECT{insert},
  );
}
{
  my ($storage, $serial) = warmed(1);
  idle_handle($storage)->t_fail_next("Duplicate entry 'y' for key 'name'");
  reused_after(
    'insert_async, duplicate key',
    $storage, $serial,
    $CALL{insert}->($storage), qr/^Duplicate entry '\*\*\*'/,
    $CALL{insert}->($storage), $EXPECT{insert},
  );
}

# ---------------------------------------------------------------------------
# 5. A transaction: its connection is handed back by core, at its end.
# ---------------------------------------------------------------------------

# Two updates in one transaction; $between runs on the pinned handle after the
# first has completed.
sub txn_of_two {
  my ($storage, $between) = @_;
  return sub {
    $storage->txn_do_async(sub {
      my $ctx = shift;
      return $ctx->update_async('artist', { name => 'a' }, { id => 1 })->then(sub {
        $between->($ctx->txn_conn);
        return $ctx->update_async('artist', { name => 'b' }, { id => 2 });
      });
    });
  };
}

{
  my ($storage, $dead) = warmed(1);
  @EV::MariaDB::TRIED = ();
  retired_after(
    'transaction, session ended in the middle',
    $storage, $dead,
    txn_of_two($storage, sub { $_[0]->t_end_session }),
    qr/\A(?!.*(?:Rollback failed|Transaction aborted)).*Lost connection to server during query/s,
    $CALL{select}->($storage), $EXPECT{select},
  );
  is_deeply \@EV::MariaDB::TRIED, [],
    'transaction, session ended in the middle: no ROLLBACK was sent on the dead connection';
}
{
  my ($storage, $dead) = warmed(1);
  idle_handle($storage)->t_end_before(qr/^BEGIN/);
  retired_after(
    'transaction, session ended before BEGIN',
    $storage, $dead,
    txn_of_two($storage, sub { }),
    qr/^BEGIN failed: Lost connection to server during query/,
    $CALL{select}->($storage), $EXPECT{select},
  );
}
{
  my ($storage, $serial) = warmed(1);
  reused_after(
    'transaction, a statement error in the middle',
    $storage, $serial,
    txn_of_two($storage, sub { $_[0]->t_fail_next("Duplicate entry '2' for key 'PRIMARY'") }),
    qr/^Duplicate entry '\*\*\*'/,
    $CALL{select}->($storage), $EXPECT{select},
  );
}

# ---------------------------------------------------------------------------
# 6. EV::MariaDB refuses to dispatch on a handle that is gone.
# ---------------------------------------------------------------------------

# Pooled: the handle is finished while it is checked out, and handed back to
# a pool of one with a caller queued for it. Since core k398 (karr k100) the
# release does not hand it to that caller: the session is reset first, and
# EV::MariaDB refuses the reset of a handle that is gone. A reset that fails
# retires the connection, so the queued caller never sees the dead handle -- its
# statement runs on a newly opened one. (The refusal of a statement on a gone
# handle is the pinned case below.)
{
  my ($storage, $dead) = warmed(1);
  my $pool = $storage->pool;
  my ($ok, $r, $serials) = run_call(sub {
    my ($ok, $conn) = wait_for($pool->acquire);
    my $queued = $storage->select_async(q{artist}, [qw( id name )]);
    $conn->finish;
    $pool->release($conn);
    return $queued;
  });
  ok $ok, q{pooled select, the handle was finished: the queued call completes}
    or diag "it failed: $r->[0]";
  is_deeply $r, $EXPECT{select}, q{pooled select, the handle was finished: with its result};
  ok @$serials == 1 && $serials->[0] != $dead,
    q{pooled select, the handle was finished: on a newly opened connection, not the dead one};
  ok freed($dead), q{pooled select, the handle was finished: the dead handle is freed};
  is $pool->size, 1, q{pooled select, the handle was finished: the pool holds the one connection};
}
# Pinned: the handle is finished in the middle of a transaction, whose next
# statement is refused. The pool has been told the connection is dead, so no
# ROLLBACK goes onto it (core karr dbio-async k47): the transaction fails with
# the statement's own error alone.
{
  my ($storage, $dead) = warmed(1);
  @EV::MariaDB::TRIED = ();
  retired_after(
    'transaction, the handle was finished',
    $storage, $dead,
    txn_of_two($storage, sub { $_[0]->finish }),
    qr/\A(?!.*(?:Rollback failed|Transaction aborted)).*not connected at /s,
    $CALL{select}->($storage), $EXPECT{select},
  );
  is_deeply \@EV::MariaDB::TRIED, [],
    'transaction, the handle was finished: no ROLLBACK was handed to the dead handle';
}

# ---------------------------------------------------------------------------
# 7. The connection's on_error.
# ---------------------------------------------------------------------------

{
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };

  # -- an idle connection: retired at once
  {
    my ($storage, $dead) = warmed(1);
    my $pool = $storage->pool;
    idle_handle($storage)->t_lose_socket;
    @warned = ();
    idle_handle($storage)->t_error('Lost connection to server during query');

    is $pool->available, 0, 'on_error, idle and gone: taken off the idle list at once';
    is $pool->size, 0, 'on_error, idle and gone: the pool holds it no longer';
    ok freed($dead), 'on_error, idle and gone: its handle is freed';
    is scalar(grep { /pool error: Lost connection to server during query/ } @warned), 1,
      'on_error, idle and gone: the pool\'s own error report still runs, once';

    my ($ok, $r, $serials) = run_call($CALL{select}->($storage));
    ok $ok, 'on_error, idle and gone: the next call completes'
      or diag "it failed: $r->[0]";
    ok @$serials == 1 && $serials->[0] != $dead,
      'on_error, idle and gone: on a newly opened connection';
  }

  # -- a checked-out connection: retired when it is handed back
  {
    my ($storage, $dead) = warmed(1);
    my $pool = $storage->pool;
    my ($ok, $conn) = wait_for($pool->acquire);
    $conn->t_lose_socket;
    $conn->t_error('Lost connection to server during query');
    is $pool->size, 1, 'on_error, checked out and gone: still the caller\'s until it hands it back';

    $pool->release($conn);
    undef $conn;
    is $pool->available, 0, 'on_error, checked out and gone: the release does not idle it';
    is $pool->size, 0, 'on_error, checked out and gone: the pool holds it no longer';
    ok freed($dead), 'on_error, checked out and gone: its handle is freed';
  }

  # -- an error on a session that is still there: nothing is retired
  {
    my ($storage, $serial) = warmed(1);
    my $pool = $storage->pool;
    @warned = ();
    idle_handle($storage)->t_error("Table 'fake.nope' doesn't exist");

    is $pool->available, 1, 'on_error, session still there: the connection stays on the idle list';
    is scalar(grep { /pool error: Table 'fake\.nope' doesn't exist/ } @warned), 1,
      'on_error, session still there: the pool\'s own error report runs';

    my ($ok, $r, $serials) = run_call($CALL{select}->($storage));
    ok $ok, 'on_error, session still there: the next call completes'
      or diag "it failed: $r->[0]";
    is_deeply $serials, [ $serial ], 'on_error, session still there: on the same connection';
  }
}

# ---------------------------------------------------------------------------
# 8. No pool, nobody to report to.
# ---------------------------------------------------------------------------

{
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $h = free_handle();
  $h->t_end_session;
  my ($ok, @r) = wait_for($storage->_query_async_pinned($h, 'SELECT 1', []));
  ok !$ok, 'no pool: a statement on a gone handle fails';
  like $r[0], qr/^Lost connection to server during query/, 'no pool: with its own error';
  ok !$storage->{pool}, 'no pool: and none was built to report to';
}

# ---------------------------------------------------------------------------
# 9. A connection that is gone while it sits idle is not handed out (k58).
# ---------------------------------------------------------------------------
#
# Core's pool asks _idle_connection_alive about every idle connection it is
# about to hand out (core k241), and retires one the seam does not vouch for.
# Sections 2 to 6 cost a caller one failed call; here no call fails at all.
# Everything below but the first block goes through the pool's acquire: that
# core asks the seam, and acts on its answer, is part of the claim.

# Is there something to read on $fh, asked without waiting?
sub readable {
  my ($fh) = @_;
  my $rin = '';
  vec($rin, fileno $fh, 1) = 1;
  return select($rin, undef, undef, 0) > 0 ? 1 : 0;
}

# A storage with a pool of two, both connections warmed and idle.
sub warmed_two {
  my $storage = pool_of(2);
  my ($ok, @r) = wait_for(DBIO::MySQL::EV::Future->needs_all(
    map { $storage->select_async('artist', [qw( id name )]) } 1, 2
  ));
  die "warming the pool failed: $r[0]" unless $ok;
  reset_done();
  die 'warming the pool left ' . $storage->pool->available . ' idle connections, not 2'
    unless $storage->pool->available == 2;
  return $storage;
}

# The claims for a call whose idle connection is gone before the pool hands
# it out: the call completes with its result, on a connection opened for it;
# no statement reached the dead handle, which is freed; and nothing was
# reported as an error -- an idle connection the server ended is no fault.
sub replaced_before {
  my ($label, $storage, $dead, $call, $expect) = @_;
  my $pool = $storage->pool;
  my $made = @EV::MariaDB::MADE;
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };

  my ($ok, $r, $serials) = run_call($call);
  ok $ok, "$label: the call completes"
    or diag "it failed: $r->[0]";
  is_deeply $r, $expect, "$label: with its result";
  ok !(grep { $_->[0] == $dead } @EV::MariaDB::WIRE),
    "$label: no statement reached the dead connection";
  is scalar(@EV::MariaDB::MADE), $made + 1, "$label: one connection was opened";
  is_deeply $serials, [ $made + 1 ], "$label: and the call ran on it";
  ok freed($dead), "$label: the dead handle is freed";
  is $pool->size, 1, "$label: the pool holds the new connection only";
  is_deeply \@warned, [], "$label: nothing was reported as an error";
}

SKIP: {
  skip 'the installed DBIO core predates _idle_connection_alive (core k241)', 1
    unless DBIO::Storage::PoolBase->can('_idle_connection_alive');

  # -- the answer, by criterion: _mysql_connection_gone's, of an idle connection
  {
    my $pool  = pool_of(1)->pool;
    my $alive = sub { $pool->_idle_connection_alive($_[0]) ? 1 : 0 };

    my $h = free_handle();
    is $alive->($h), 1, 'the seam: connected, nothing to read: alive';
    $h->t_hang_up;
    is $alive->($h), 0, 'the seam: the server hung up: not alive';

    $h = free_handle();
    $h->t_lose_socket;
    is $alive->($h), 0, 'the seam: no socket: not alive';
  }

  # -- gone while idle, either way the handle can show it; every kind of call
  my %died = (
    'the server ended the session' => sub { $_[0]->t_end_session },
    'the handle has no socket'     => sub { $_[0]->t_lose_socket },
  );
  for my $how (sort keys %died) {
    for my $op (qw( select update insert )) {
      my ($storage, $dead) = warmed(1);
      $died{$how}->(idle_handle($storage));
      replaced_before("idle, $how, then $op", $storage, $dead, $CALL{$op}->($storage), $EXPECT{$op});
    }
    my ($storage, $dead) = warmed(1);
    $died{$how}->(idle_handle($storage));
    replaced_before("idle, $how, then a transaction", $storage, $dead, txn_of_two($storage, sub { }), $EXPECT{update});
  }

  # -- the next idle connection that is still there is taken before one is opened
  {
    my $storage = warmed_two();
    my $pool    = $storage->pool;
    my ($dead, $next) = map { $_->serial } @{ $pool->{_idle} };
    $pool->{_idle}[0]->t_end_session;
    my $made = @EV::MariaDB::MADE;

    my ($ok, $r, $serials) = run_call($CALL{select}->($storage));
    ok $ok, 'two idle, the first gone: the call completes'
      or diag "it failed: $r->[0]";
    is_deeply $serials, [ $next ], 'two idle, the first gone: on the other idle connection';
    is scalar(@EV::MariaDB::MADE), $made, 'two idle, the first gone: no connection was opened';
    ok freed($dead), 'two idle, the first gone: the dead handle is freed';
    is $pool->size, 1, 'two idle, the first gone: the pool holds the live one only';
  }

  # -- every idle connection gone, as after a server restart: one call, none fails
  {
    my $storage = warmed_two();
    my $pool    = $storage->pool;
    my @dead    = map { $_->serial } @{ $pool->{_idle} };
    $_->t_end_session for @{ $pool->{_idle} };
    my $made = @EV::MariaDB::MADE;

    my ($ok, $r, $serials) = run_call($CALL{select}->($storage));
    ok $ok, 'every idle connection gone: the call completes'
      or diag "it failed: $r->[0]";
    is_deeply $serials, [ $made + 1 ], 'every idle connection gone: on a newly opened connection';
    is scalar(grep { freed($_) } @dead), 2, 'every idle connection gone: both dead handles are freed';
    is $pool->size, 1, 'every idle connection gone: the pool holds the new connection only';
  }

  # -- a connection that is still there is handed out as it is, and untouched
  {
    my ($storage, $serial) = warmed(1);
    my $pool = $storage->pool;
    my $h    = idle_handle($storage);
    my ($made, $ops) = (scalar @EV::MariaDB::MADE, $h->{ops});
    @EV::MariaDB::WIRE = ();

    my ($ok, $conn) = wait_for($pool->acquire);
    ok $ok && refaddr($conn) == refaddr($h), 'idle and still there: the same connection is handed out';
    is scalar(@EV::MariaDB::MADE), $made, 'idle and still there: no connection was opened';
    is $h->{ops}, $ops, 'idle and still there: the handle saw no operation';
    is_deeply \@EV::MariaDB::WIRE, [], 'idle and still there: no statement was sent';
    ok !readable($h->{server}), 'idle and still there: nothing was written to its socket';
    $pool->release($conn);
    undef $conn;
    undef $h;

    my @served;
    for (1 .. 5) {
      my ($ok, $r, $serials) = run_call($CALL{select}->($storage));
      push @served, $ok ? @$serials : "failed: $r->[0]";
    }
    is_deeply \@served, [ ($serial) x 5 ], 'idle and still there: five calls in a row run on it';
    is scalar(@EV::MariaDB::MADE), $made, 'idle and still there: and none of them opened a connection';
    ok !freed($serial), 'idle and still there: it was never closed';
  }

  # -- the check only looks: what the server said before it hung up stays unread
  {
    my ($storage, $dead) = warmed(1);
    my $pool = $storage->pool;
    # A dup of the socket outlives the handle: retiring it now finishes the
    # handle (karr k67), which closes its own descriptor, as the real one does.
    open(my $sock, '<&', idle_handle($storage)->{client}) or die "dup: $!";
    syswrite idle_handle($storage)->{server}, 'bye';
    idle_handle($storage)->t_end_session;

    my ($ok, $conn) = wait_for($pool->acquire);
    ok $ok && $conn->serial != $dead, 'the server said why and hung up: another connection is handed out';
    ok freed($dead), 'the server said why and hung up: the dead handle is freed';
    my $buf = '';
    sysread $sock, $buf, 16 if readable($sock);
    is $buf, 'bye', 'the server said why and hung up: what it sent was not read';
    $pool->release($conn);
  }

  # -- an operation in flight on an idle connection: its reply is due on the
  #    socket, so a readable socket says nothing. Nothing of the transport's
  #    leaves one behind; a caller that kept the handle can.
  {
    my ($storage, $serial) = warmed(1);
    my $pool = $storage->pool;
    my $h    = idle_handle($storage);
    my $answered;
    $h->query('SELECT 1', sub { $answered = 1 });
    syswrite $h->{server}, 'x';
    my $ops = $h->{ops};

    my ($ok, $conn) = wait_for($pool->acquire);
    ok $ok && refaddr($conn) == refaddr($h),
      'idle with an operation in flight: handed out, the socket being readable says nothing';
    is $h->{ops}, $ops, 'idle with an operation in flight: the handle saw no further operation';
    my $buf = '';
    sysread $h->{client}, $buf, 16 if readable($h->{client});
    is $buf, 'x', 'idle with an operation in flight: its reply was not read';
    EV::run(EV::RUN_ONCE()) until $answered;
    $pool->release($conn);
  }

  # -- a process that inherited the pool: its first acquire drops the parent's
  #    connections (core k233) before any is asked about, so a parent's
  #    connection is never closed from here, gone or not.
  {
    my ($storage, $serial) = warmed(1);
    my $pool = $storage->pool;
    my $h    = idle_handle($storage);
    $h->t_hang_up;
    my $ops = $h->{ops};
    $pool->{_owner_pid} = $$ + 1;   # the pool was built by another process

    my ($ok, $conn) = wait_for($pool->acquire);
    ok $ok && $conn->serial != $serial, 'an inherited pool: the caller gets a connection of its own';
    is $h->{ops}, $ops, 'an inherited pool: the parent\'s connection was not closed';
    $pool->release($conn);
  }
}

done_testing;
