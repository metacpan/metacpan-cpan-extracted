use strict;
use warnings;
use Test::More;

use Config;
use POSIX ();
use Future;
use Future::IO qw( POLLIN );
use Scalar::Util qw( refaddr weaken );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test (karr k43, k39): the storage is disconnected, or its pool shut
# down, while a statement is on the wire of a checked-out connection.
#
# WHY IT MATTERS. A pool's shutdown is pinned for the callers it can see: the
# ones queued for a connection, the ones whose connection is still coming up
# (t/27), a release that comes late. A statement in flight is none of those.
# Its connection is checked out, so the pool closes it and knows no Future to
# fail; the Future that does exist is this transport's -- a Future::IO poll on
# the dup of the connection's socket, with the collect chained onto it -- and
# until k39 nothing told it: it stayed pending, the loop went on watching the
# dup of a socket whose connection was closed, a late answer ran
# _collect_result on that closed connection, and the completion asked
# $storage->pool for a pool to release into -- which built a new one on a
# storage just disconnected. disconnect is also what DESTROY runs, and what
# connect_info runs before it takes new connect info, so "a statement was
# still running" is an ordinary moment to be torn down in, not an exotic one.
#
# What holds since k39 (ADR 0007). The storage keeps every statement it put on
# the wire in a register until it settles. When the pool closes a connection
# -- at its shutdown, which is what disconnect runs, or when it retires one --
# the statement in flight on that connection ends there:
#   * its caller's Future FAILS, at the teardown, with an error saying the
#     connection was closed under the statement and that whether it took
#     effect is unknown;
#   * the Future::IO poll is let go of: the loop watches nothing afterwards;
#   * nothing is read off the closed connection, and a late answer changes
#     nothing, warns nothing, kills nothing;
#   * the statements waiting behind it on a pinned connection fail without
#     being sent;
#   * nothing more is sent on a connection the pool closed -- whether or not a
#     statement was in flight on it: what is issued on it afterwards is
#     refused by the transport and never reaches the driver;
#   * no completion builds a pool: a disconnected storage has none afterwards;
#   * the teardown itself does not die, does not warn, closes the connection
#     exactly once, and is harmless to repeat;
#   * a forked child that tears down what it inherited settles nothing of the
#     parent's, and one whose own loop is handed the parent's poll does
#     nothing with it -- above all it does not read the parent's answer;
#   * a process that exits with a statement in flight settles nothing in
#     global destruction.
# And a storage DROPPED with a statement in flight is not torn down under it:
# the statement completes, the caller's Future settles, the storage is freed.
#
# WHAT IS REAL. The transport's query path -- _query_async and
# _query_async_pinned, _await_query_result, the Future::IO poll on the dup(2)
# of a real fd, _release_on_ready, _mark_dead_on_fail -- its pool(), the real
# DBIO::Async::Pool, core's disconnect, shutdown and release, and core's
# txn_do_async. Future::IO's built-in implementation does the polling. Section
# 0 pins that the mock owns the DB-specific seams and nothing else.
#
# THE MOCK SERVER. A connection is the read end of a pipe; the write end is
# the server's, and not the connection's to close. _submit_query records the
# statement and puts nothing on the pipe: the statement is in flight until the
# test has the server answer. Closing the connection closes the driver's own
# handle only, as a DBD's disconnect does -- the transport's dup keeps the
# socket open, which is why an answer can still arrive on it. A closed
# connection behaves the way the drivers' do: _submit_query and
# _collect_result die on it (a DBD refuses a handle it disconnected) and
# _conn_error_is_fatal answers that it is dead (dbio-postgresql asks whether
# libpq still has a socket).

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# A server answering a connection none of whose handles is open any more gets
# EPIPE; that has to show in the assertions, not kill the test with SIGPIPE.
$SIG{PIPE} = 'IGNORE';

# --- LoopSpy30: every poll the transport makes, on the built-in loop --------
#
# Keeps each poll Future and delegates to the built-in implementation by
# localising $Future::IO::IMPL away for the call, as t/12 and t/27 do, so the
# poll that happens is the real one.

{
  package LoopSpy30;
  our @POLLS;

  sub poll {
    my ($class, $fh, $events) = @_;
    local $Future::IO::IMPL;     # -> the built-in impl for this one call
    my $f = Future::IO->poll($fh, $events);
    push @POLLS, $f;
    return $f;
  }

  sub sleep {
    my ($class, $seconds) = @_;
    local $Future::IO::IMPL;
    return Future::IO->sleep($seconds);
  }
}
$Future::IO::IMPL = 'LoopSpy30';

sub polls { return @LoopSpy30::POLLS }

# --- Flight30: the DB-specific seams over a pipe -----------------------------

{
  package Flight30;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Scalar::Util ();

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # What a transaction context's CRUD needs from its owning storage (as in
  # t/24): this mock is its own owner, and proves ownership as core does.
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context does not belong to this storage generation\n"
      unless Scalar::Util::refaddr($self->_context_owner_token)
          == Scalar::Util::refaddr($ctx->_context_owner_token);
    return $ctx;
  }
  sub _select_args { my ($self, @args) = @_; return ('select', @args) }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    my $id = ++$self->{_next_id};
    $self->{server}{$id} = $w;
    return { id => $id, r => $r };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->{id};
    close $conn->{r};
    $conn->{closed} = 1;
  }

  # A DBD refuses a handle it disconnected. Not every client library does:
  # {lenient} is the driver whose submit on a closed handle does not die, and
  # which would therefore wait for an answer that cannot come.
  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, [ main::label($sql), $conn->{id} ];
    die "Flight30: connection $conn->{id} is closed\n"
      if $conn->{closed} && !$self->{lenient};
    return;
  }

  # Every collect is recorded with the state of its connection: one on a closed
  # connection is the finding. It never blocks: a collect that finds nothing to
  # read -- somebody else took the answer -- fails saying so. With {two_step}
  # an answer comes in two parts, and the driver waits for the second the way
  # the real ones do: _await_readable, then itself again.
  sub _collect_result {
    my ($self, $conn) = @_;
    push @{ $self->{collected} }, [ $conn->{id}, $conn->{closed} ? 'closed' : 'open' ];
    die "Flight30: connection $conn->{id} is closed\n" if $conn->{closed};

    my $rin = '';
    vec($rin, fileno $conn->{r}, 1) = 1;
    return Future->fail("Flight30: nothing to read on connection $conn->{id}\n")
      unless select($rin, undef, undef, 0);
    sysread $conn->{r}, my $byte, 1;

    if ($self->{two_step} && !$conn->{half}++) {
      return $self->_await_readable($conn)->then(sub { $self->_collect_result($conn) });
    }
    delete $conn->{half};
    return Future->done([ 'row-for', $self->{wire}[-1][0], $conn->{id} ]);
  }

  sub _conn_error_is_fatal { $_[1]{closed} ? 1 : 0 }

  # What pipeline() and deploy_async() need of a driver (section 2c): the
  # sync is a statement of its own, in flight until the server answers.
  sub _pipeline_enter { return 1 }
  sub _pipeline_sync  { my ($self, $conn) = @_; return $self->_query_async_pinned($conn, 'SYNC', []) }
  sub _pipeline_exit  { return 1 }
  sub _ddl_class      { 'FakeDDL30' }
  # This mock is its own owner (above), and the capability delegates to the
  # owner: left alone it asks itself for ever.
  sub _use_transactional_ddl { 0 }
}

{
  package FakeDDL30;
  sub install_ddl { return "CREATE TABLE artist (id INTEGER);\n" }
}

sub new_storage {
  my %args = @_;
  my $storage = Flight30->new(undef);
  $storage->{_next_id} = 0;
  $storage->{server}   = {};
  $storage->{$_} = [] for qw(closed wire collected);
  $storage->{$_} = delete $args{$_} for qw(lenient two_step);
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %args }]);
  @LoopSpy30::POLLS = ();
  return $storage;
}

# The table a statement names, or the statement itself (BEGIN, ROLLBACK): what
# the wire log records.
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# What went onto the wire, without the connection ids.
sub sent { my ($storage) = @_; return [ map { $_->[0] } @{ $storage->{wire} } ] }

# The server answers the statement in flight on a connection: its socket
# turns readable.
sub answer { my ($server) = @_; syswrite $server, 'R'; return }

# Turn the built-in loop. The zero timer makes it select() for real instead of
# presuming a lone read poll ready (Future::IO 0.23, _await_once), so a poll
# resolves here only when its socket really is readable.
sub turn { Future::IO->sleep(0)->get for 1 .. 3; return }

# Is the built-in loop watching nothing -- no poll and no timer? One round of
# it refuses to run when it has nothing to wait for, and that refusal is the
# answer (t/27). Asked only where nothing should be watched.
sub loop_is_idle {
  return 0 if eval { Future::IO::_DefaultImpl::F::_await_once(); 1 };
  return 1 if $@ =~ /Cowardly refusing to sit idle/;
  diag "a round of the loop died: $@";
  return 0;
}

sub outcome {
  my $f = shift;
  return 'never issued'  unless $f;
  return 'still pending' unless $f->is_ready;
  return 'cancelled'     if $f->is_cancelled;
  return 'failed: ' . $f->failure if $f->is_failed;
  return [ $f->get ];
}

# The teardown under test: the storage's disconnect, or its pool's shutdown.
sub tear_down {
  my ($via, $storage, $pool) = @_;
  return eval { $via eq 'disconnect' ? $storage->disconnect : $pool->shutdown; 1 };
}

# Did the torn down storage get a pool it did not have? After the pool's own
# shutdown the shut down pool is still on the storage; after disconnect the
# storage has none.
sub no_new_pool {
  my ($storage, $pool) = @_;
  my $now = $storage->{pool};
  return !defined $now || refaddr($now) == refaddr($pool);
}

# What the statement in flight fails with at the teardown, and what a
# statement that was never sent fails with.
my $IN_FLIGHT = qr/^failed: Statement abandoned in flight: .*connection was closed.*whether it took effect is unknown/s;
my $NOT_SENT  = qr/^failed: not sent: this connection was closed .*nothing more is sent on it/s;

# ---------------------------------------------------------------------------
# 0. The guards that give every other assertion its meaning: the mock
#    overrides none of the transport's query path nor its pool().
#
#    And where the teardown lives. Until k39 this section claimed that the
#    teardown under test is core's alone -- "neither this transport nor its
#    pool has one of its own". The first half still holds and is still pinned:
#    disconnect, shutdown and release are core's, not overridden. The second
#    half is what k39 replaced: the transport now has a part in every close.
#    Core's pool closes a connection through its _shutdown_connection seam,
#    which is this dist's, and that is where the statement in flight on the
#    connection is ended (DBIO::Async::Storage::_abandon_flights_on) before the
#    driver closes its handle.
# ---------------------------------------------------------------------------

for my $method (qw( _query_async _query_async_pinned _await_query_result
                    _collect_on_readable _release_on_ready _mark_dead_on_fail
                    _await_readable _conn_poll_fh pool _abandon_flights_on )) {
  ok defined DBIO::Async::Storage->can($method), "the transport has $method";
  is refaddr(Flight30->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
is refaddr(DBIO::Async::Storage->can('disconnect')),
   refaddr(DBIO::Storage::Async->can('disconnect')),
  'disconnect is core\'s -- this transport does not override it';
for my $method (qw( shutdown release )) {
  is refaddr(DBIO::Async::Pool->can($method)),
     refaddr(DBIO::Storage::PoolBase->can($method)),
    "DBIO::Async::Pool does NOT override $method -- core's pool decides";
}
isnt refaddr(DBIO::Async::Pool->can('_shutdown_connection')),
     refaddr(DBIO::Storage::PoolBase->can('_shutdown_connection')),
  'the close of one connection IS this dist\'s -- where a flight on it ends';

# The control: a statement in flight that nobody disturbs. It is what the
# sections below take away.
{
  my $l       = 'undisturbed';
  my $storage = new_storage();

  my $f = $storage->_query_async('SELECT * FROM a', []);
  turn();
  is outcome($f), 'still pending',
    "$l: a statement stays in flight for as long as the server has not answered";

  answer($storage->{server}{1});
  turn();
  is_deeply outcome($f), [ [ 'row-for', 'a', 1 ] ],
    "$l: ... and resolves with the result once it has";
  is_deeply $storage->{collected}, [ [ 1, 'open' ] ], "$l: ... read off an open connection";
  is $storage->pool->available, 1, "$l: ... its connection back in the pool";
  ok loop_is_idle(), "$l: nothing is watched afterwards";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 1. Torn down with a statement in flight: a pooled query and a pinned one (a
#    transaction's statement), by disconnect and by the pool's own shutdown.
# ---------------------------------------------------------------------------

for my $mode (qw( pooled pinned )) {
  for my $via (qw( disconnect shutdown )) {
    my $l       = "$mode, $via";
    my $storage = new_storage();
    my $pool    = $storage->pool;

    my ($conn, $f);
    if ($mode eq 'pooled') {
      $f = $storage->_query_async('SELECT * FROM a', []);
    }
    else {
      $conn = $pool->acquire->get;
      $f    = $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);
    }
    my ($poll) = polls();

    is outcome($f), 'still pending', "$l: the statement is in flight";
    is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: ... on the wire of connection 1";
    ok $poll && !$poll->is_ready, "$l: ... its socket watched";
    is_deeply [ $pool->size, $pool->available ], [ 1, 0 ],
      "$l: ... its connection checked out";

    # --- the teardown ---
    ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
    is_deeply $storage->{closed}, [1],
      "$l: the checked-out connection is closed, once";
    is_deeply [ $pool->size, $pool->available ], [ 0, 0 ],
      "$l: the pool is left holding nothing";
    is_deeply [ splice @warnings ], [], "$l: the teardown warned nothing";

    like outcome($f), $IN_FLIGHT,
      "$l: the statement in flight fails at the teardown, saying what happened";
    my $failed_with = outcome($f);
    ok $poll && $poll->is_ready,
      "$l: ... and the transport let go of its poll";
    ok loop_is_idle(),
      "$l: ... so the loop no longer watches the closed connection's socket";
    ok no_new_pool($storage, $pool), "$l: the teardown left the storage no new pool";

    # --- nothing more goes onto a pinned connection that was torn down ---
    if ($mode eq 'pinned') {
      my $later = $storage->_query_async_pinned($conn, 'SELECT * FROM later', []);
      like outcome($later), $NOT_SENT,
        "$l: a statement issued on the connection afterwards is refused";
      is_deeply $storage->{wire}, [ [ 'a', 1 ] ],
        "$l: ... and not sent onto the closed connection";
    }

    # --- the server answers after all ---
    answer($storage->{server}{1});
    ok eval { turn(); 1 }, "$l: the answer arrives late and the loop turns: nothing dies"
      or diag $@;
    is outcome($f), $failed_with,
      "$l: the late answer changes nothing about the statement's outcome";
    is_deeply $storage->{collected}, [],
      "$l: nothing was read off the closed connection";
    ok no_new_pool($storage, $pool),
      "$l: the late answer built no new pool on the torn down storage";

    # Whatever pool there is, the closed connection is in none of them: the
    # next caller would be handed it.
    my %pools = map { refaddr($_) => $_ } grep { defined } $pool, $storage->{pool};
    is scalar(grep { $_->size || $_->available } values %pools), 0,
      "$l: the closed connection was put into no pool";
    is_deeply $storage->{closed}, [1], "$l: ... and was not closed a second time";
    ok loop_is_idle(), "$l: the loop is left watching nothing";
    is_deeply [ splice @warnings ], [], "$l: the late answer warned nothing";
  }
}

# ---------------------------------------------------------------------------
# 2. A pinned connection with statements WAITING behind the one in flight
#    (the pinned statement queue, t/24). The one in flight fails as in section
#    1; the ones waiting were never sent and fail saying so, in the order they
#    were issued; so does one issued from the failure's own callback.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  my $l       = "queued, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my (@order, $from_callback);
  my %f = map {
    my $table = $_;
    my $f = $storage->_query_async_pinned($conn, "SELECT * FROM $table", []);
    $f->on_ready(sub { push @order, $table });
    ($table => $f);
  } qw( a b c );
  $f{a}->on_fail(sub {
    $from_callback = $storage->_query_async_pinned($conn, 'SELECT * FROM d', []);
  });
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ],
    "$l: one statement is in flight, two wait behind it";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;

  like outcome($f{a}), $IN_FLIGHT, "$l: the statement in flight fails";
  like outcome($f{$_}), $NOT_SENT,
    "$l: the waiting statement $_ fails, saying it was not sent" for qw( b c );
  like outcome($from_callback), $NOT_SENT,
    "$l: a statement issued from the failure's callback is refused as well";
  is_deeply \@order, [qw( a b c )],
    "$l: they fail in the order they were issued";
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ],
    "$l: nothing but the statement in flight ever reached the wire";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok no_new_pool($storage, $pool), "$l: the storage got no new pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 3. A transaction (core's txn_do_async), torn down at three moments. What it
#    does with a failed statement is core's and unchanged: BEGIN's failure
#    fails it, a statement's failure sends ROLLBACK -- which the torn down
#    connection refuses unsent -- and the finalizer hands the connection back
#    to a pool that no longer takes it.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  my $l       = "txn, BEGIN in flight, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $ran = 0;
  my $f = $storage->txn_do_async(sub { $ran++; return Future->done('block') });
  is_deeply sent($storage), ['BEGIN'], "$l: BEGIN is in flight";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
  like outcome($f), qr/^failed: BEGIN failed: Statement abandoned in flight: /,
    "$l: the transaction fails at the teardown, with BEGIN's failure";
  is $ran, 0, "$l: its block never ran";
  is_deeply sent($storage), ['BEGIN'], "$l: nothing more was sent";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok no_new_pool($storage, $pool), "$l: the storage got no new pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  answer($storage->{server}{1});
  ok eval { turn(); 1 }, "$l: a late answer kills nothing" or diag $@;
  is_deeply $storage->{collected}, [], "$l: ... and is not read";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

for my $via (qw( disconnect shutdown )) {
  my $l       = "txn, statement in flight, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $stmt;
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = $ctx->select_async('a', ['*'], {});
  });
  answer($storage->{server}{1});      # BEGIN
  turn();
  is_deeply sent($storage), [ 'BEGIN', 'a' ],
    "$l: the block's statement is in flight";
  is outcome($f), 'still pending', "$l: ... and the transaction waits for it";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
  like outcome($stmt), $IN_FLIGHT, "$l: the statement fails at the teardown";
  like outcome($f),
    qr/^failed: .*Transaction aborted: Statement abandoned in flight: .*Rollback failed: not sent: /s,
    "$l: ... and so does the transaction, saying its ROLLBACK was not sent";
  is_deeply sent($storage), [ 'BEGIN', 'a' ],
    "$l: ROLLBACK did not go onto the closed connection";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok no_new_pool($storage, $pool),
    "$l: the transaction's hand-back built no new pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  answer($storage->{server}{1});
  ok eval { turn(); 1 }, "$l: a late answer kills nothing" or diag $@;
  is_deeply $storage->{collected}, [ [ 1, 'open' ] ],
    "$l: ... and is not read: BEGIN's result is all that ever was";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# Between two statements nothing is in flight, so the teardown has nothing to
# fail: the transaction learns of it when its block goes on. It must still end
# -- failed, not hanging -- and leave nothing behind.
#
# This section first claimed that the transaction learns of the teardown "from
# the driver's closed handle": after a bare pool shutdown its next statement,
# and core's ROLLBACK after it, were still handed to the driver, which refused
# them. That claim is replaced. A connection the pool closed is finished: the
# TRANSPORT refuses what is issued on it, and nothing reaches _submit_query --
# a driver whose submit does not die on a closed handle would otherwise be
# left with a poll on a dead socket (section 3b).
for my $via (qw( disconnect shutdown )) {
  my $l       = "txn, between two statements, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $pause = Future->new;
  my $second;
  my $f = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('a', ['*'], {})->then(sub {
      return $pause->then(sub { $second = $ctx->select_async('b', ['*'], {}) });
    });
  });
  answer($storage->{server}{1});      # BEGIN
  turn();
  answer($storage->{server}{1});      # a
  turn();
  is_deeply sent($storage), [ 'BEGIN', 'a' ], "$l: the first statement is answered";
  ok loop_is_idle(), "$l: ... and nothing is in flight";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
  is outcome($f), 'still pending',
    "$l: no statement was in flight, so nothing fails at the teardown";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";

  ok eval { $pause->done; 1 }, "$l: the block goes on: nothing dies" or diag $@;
  like outcome($f), qr/^failed: .*Rollback failed: not sent: this connection was closed /s,
    "$l: ... and the transaction ends, failed: its ROLLBACK was refused unsent";
  is_deeply sent($storage), [ 'BEGIN', 'a' ],
    "$l: nothing was handed to the driver for the closed connection -- neither "
    . "the block's next statement nor core's ROLLBACK";
  # After a disconnect core's context refuses the statement before the
  # transport sees it; after a bare shutdown the context is still valid, and
  # the refusal is the transport's.
  like outcome($second), $NOT_SENT,
    "$l: the block's next statement is refused by the transport"
    if $via eq 'shutdown';
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";

  # After a disconnect the storage has no pool, and the transaction that ends
  # afterwards hands its connection back to the pool it was acquired from
  # (core, dbio 4aa01dc67), not through $storage->pool, which would build one.
  ok no_new_pool($storage, $pool),
    "$l: the transaction's hand-back built no new pool";
}

# ---------------------------------------------------------------------------
# 2c. The other two pieces of core work that hold a pooled connection across
#     statements -- a pipeline waiting for its sync, a DDL statement in flight
#     -- end after a disconnect as a transaction does: they hand the
#     connection back to the pool they acquired it from, and build no new
#     pool on the disconnected storage (dbio 4aa01dc67, karr k46). Probe only
#     what is this transport's: the statement fails at the teardown, the work
#     ends, and the storage is left without a pool.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  my $l       = "pipeline, sync in flight, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->pipeline(sub {
    my ($ctx) = @_;
    $ctx->select_async('a', ['*'], {});
    return;
  });
  answer($storage->{server}{1});      # a
  turn();
  is_deeply sent($storage), [ 'a', 'SYNC' ], "$l: the sync is in flight";
  is outcome($f), 'still pending', "$l: ... and the pipeline waits for it";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
  like outcome($f), qr/^failed: .*Statement abandoned in flight: /s,
    "$l: the pipeline fails at the teardown";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok no_new_pool($storage, $pool), "$l: the pipeline's end built no new pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  answer($storage->{server}{1});
  ok eval { turn(); 1 }, "$l: a late answer kills nothing" or diag $@;
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

for my $via (qw( disconnect shutdown )) {
  my $l       = "deploy_async, DDL in flight, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f;
  {
    local $SIG{__WARN__} = sub { };    # the one-shot notice on non-transactional DDL
    $f = $storage->deploy_async(undef);
  }
  is_deeply sent($storage), [ 'CREATE TABLE artist (id INTEGER)' ],
    "$l: the DDL statement is in flight";

  ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
  like outcome($f), qr/^failed: .*Statement abandoned in flight: /s,
    "$l: the deploy fails at the teardown";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok no_new_pool($storage, $pool), "$l: the deploy's end built no new pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  answer($storage->{server}{1});
  ok eval { turn(); 1 }, "$l: a late answer kills nothing" or diag $@;
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 3b. A pinned connection that is IDLE when the pool closes it -- a holder
#     between two statements, or one that has not issued any yet. Nothing is
#     in flight, so nothing fails at the close; but the connection is finished,
#     and a statement issued on it afterwards is refused by the transport,
#     with a reason that is true without a statement in flight too. The
#     driver here is the lenient one, whose submit on a closed handle does not
#     die: handed the statement, it would leave a poll on a dead socket and a
#     Future that never settles.
#
#     And the mark stays where it belongs: a connection handed back and NOT
#     closed carries no queue state into the pool.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  for my $used (qw( unused used )) {
    my $l       = "idle pinned connection ($used), $via";
    my $storage = new_storage(lenient => 1);
    my $pool    = $storage->pool;
    my $conn    = $pool->acquire->get;

    if ($used eq 'used') {
      my $first = $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);
      answer($storage->{server}{1});
      turn();
      is_deeply outcome($first), [ [ 'row-for', 'a', 1 ] ],
        "$l: a statement on it is answered";
    }
    my @before = @{ $storage->{wire} };
    ok !exists $conn->{_dbio_async_queue},
      "$l: idle, the connection carries no queue state";

    ok tear_down($via, $storage, $pool), "$l: the teardown does not die" or diag $@;
    is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";

    my $later = $storage->_query_async_pinned($conn, 'SELECT * FROM later', []);
    like outcome($later), $NOT_SENT,
      "$l: a statement issued on it afterwards is refused";
    unlike outcome($later), qr/in flight/,
      "$l: ... with a reason that claims no statement in flight";
    is_deeply $storage->{wire}, \@before,
      "$l: ... and is not handed to the driver";
    ok loop_is_idle(), "$l: so nothing waits on the closed connection's socket";
    ok no_new_pool($storage, $pool), "$l: the storage got no new pool";
    is_deeply [ splice @warnings ], [], "$l: nothing warned";
  }
}

{
  my $l       = 'handed back, not closed';
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $first = $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);
  answer($storage->{server}{1});
  turn();
  $pool->release($conn);
  ok !exists $conn->{_dbio_async_queue},
    "$l: a connection that goes back to the pool open carries no queue state";

  my $next = $storage->_query_async('SELECT * FROM b', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: ... and takes the next borrower's statement";
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($next), [ [ 'row-for', 'b', 1 ] ], "$l: ... which resolves";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 4. Harmless to repeat. A second disconnect, a second shutdown, and the
#    pool's shutdown after the storage's disconnect change nothing.
# ---------------------------------------------------------------------------

{
  my $l       = 'twice';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT * FROM a', []);
  my $settled = 0;
  $f->on_ready(sub { $settled++ });

  ok tear_down(disconnect => $storage, $pool), "$l: disconnect";
  my $failed_with = outcome($f);
  like $failed_with, $IN_FLIGHT, "$l: the statement fails";

  ok tear_down(disconnect => $storage, $pool), "$l: a second disconnect does not die"
    or diag $@;
  ok tear_down(shutdown => $storage, $pool),
    "$l: nor does the old pool's shutdown, twice"
    for 1, 2;

  is $settled, 1, "$l: the statement's Future settled once";
  is outcome($f), $failed_with, "$l: ... and kept its failure";
  is_deeply $storage->{closed}, [1], "$l: the connection was closed once";
  ok !defined $storage->{pool}, "$l: the storage has no pool";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 5. A callback on the caller's Future that DIES as the statement is failed.
#    It runs inside the pool's shutdown, between two connections: its death
#    may not stop the teardown -- every other statement still fails, every
#    connection is still closed, every poll let go of -- and it is not
#    swallowed either: it goes to the pool's on_error (this transport's pool
#    warns it).
# ---------------------------------------------------------------------------

{
  my $l       = 'dying callback';
  my $storage = new_storage(pool_size => 2);
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 2 ] ],
    "$l: two statements in flight, on two connections";
  $_->on_fail(sub { die "the caller's callback broke\n" }) for $fa, $fb;

  ok tear_down(disconnect => $storage, $pool), "$l: the teardown does not die"
    or diag $@;
  like outcome($_), $IN_FLIGHT, "$l: the statement fails" for $fa, $fb;
  is_deeply [ sort @{ $storage->{closed} } ], [ 1, 2 ],
    "$l: both connections are closed";
  ok loop_is_idle(), "$l: both polls are let go of";

  my @reports = splice @warnings;
  is scalar @reports, 2, "$l: each death is reported";
  like $_, qr/DBIO::Async pool error: .*callback died.*the caller's callback broke/s,
    "$l: ... through the pool's on_error, naming it" for @reports;
}

# ---------------------------------------------------------------------------
# 6. Not only a shutdown closes a connection: the pool also retires one that
#    is checked out (core's hand-back of a transaction connection a pipeline
#    left unusable, k232, sends a ROLLBACK it does not wait for and retires).
#    A statement in flight on a connection retired under it ends the same way.
# ---------------------------------------------------------------------------

{
  my $l       = 'retired in flight';
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $f = $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);
  ok eval { $pool->_retire_in_use_connection($conn); 1 },
    "$l: retiring the connection does not die" or diag $@;

  like outcome($f), $IN_FLIGHT, "$l: the statement in flight fails at the close";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  ok loop_is_idle(), "$l: the loop no longer watches it";
  is $pool->size, 0, "$l: the pool no longer counts it";

  my $next = $storage->_query_async('SELECT * FROM b', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 2 ] ],
    "$l: the pool lives on: the next query runs on a fresh connection";
  answer($storage->{server}{2});
  turn();
  is_deeply outcome($next), [ [ 'row-for', 'b', 2 ] ], "$l: ... and resolves";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 6b. A statement on a connection the pool does NOT hold -- the listen
#     connection an emulated _listen_drain queries is one. The pool closes
#     only its own, so such a statement flies on through a disconnect and
#     completes afterwards, on a storage that has no pool. Its completion has
#     things to say to a pool -- the connection died, or was abandoned by a
#     cancel -- and must find nobody to tell, not build a pool to tell it to.
# ---------------------------------------------------------------------------

for my $how (qw( fails cancelled )) {
  my $l       = "outside the pool, $how";
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $outside = $storage->_create_pool_connection;   # built as _listen_open would

  my $f = $storage->_query_async_pinned($outside, 'SELECT * FROM a', []);
  my $waiting = $storage->_query_async_pinned($outside, 'SELECT * FROM b', []);
  ok tear_down(disconnect => $storage, $pool), "$l: disconnect does not die" or diag $@;
  is outcome($f), 'still pending',
    "$l: the pool closed nothing of this connection's: its statement flies on";
  ok !defined $storage->{pool}, "$l: the storage has no pool";

  if ($how eq 'fails') {
    $outside->{closed} = 1;           # the session dies under the statement
    answer($storage->{server}{1});
    turn();
    like outcome($f), qr/^failed: Flight30: connection 1 is closed/,
      "$l: the statement fails with its own error";
  }
  else {
    $f->cancel;
    is outcome($f), 'cancelled', "$l: the statement is cancelled in flight";
  }
  like outcome($waiting), qr/^failed: /, "$l: the statement behind it ends too";
  ok !defined $storage->{pool},
    "$l: the completion built no pool on the disconnected storage";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

# ---------------------------------------------------------------------------
# 7. A forked child that inherited the storage and tears it down. The
#    connections are the parent's and so are the statements on them: the child
#    closes nothing and settles nothing -- no callback of the parent's runs
#    there (core k233, k234 for the pool's own state). The parent's statement
#    is untouched and completes.
# ---------------------------------------------------------------------------

SKIP: {
  skip 'fork is not available', 2 * 9 unless $Config{d_fork};

  for my $via (qw( disconnect shutdown )) {
    my $l       = "forked child, $via";
    my $storage = new_storage();
    my $pool    = $storage->pool;

    my $f = $storage->_query_async('SELECT * FROM a', []);
    my $settled = 0;
    $f->on_ready(sub { $settled++ });

    pipe(my $from_child, my $to_parent) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) {
      close $from_child;
      splice @warnings;
      my $torn = tear_down($via, $storage, $pool);
      my $report = join "\n",
        'torn=' . ($torn ? 1 : 0),
        'settled=' . $settled,
        'future=' . (ref outcome($f) ? 'done' : outcome($f)),
        'closed=' . scalar @{ $storage->{closed} },
        'warned=' . scalar @warnings,
        '';
      syswrite $to_parent, $report;
      POSIX::_exit(0);            # no END blocks, no destructors: a child's exit
    }
    close $to_parent;
    my $report = do { local $/; <$from_child> };
    waitpid $pid, 0;
    my %child = $report =~ /^(\w+)=(.*)$/mg;

    is $child{torn}, 1, "$l: the teardown does not die in the child";
    is $child{future}, 'still pending',
      "$l: the parent's statement is not settled in the child";
    is $child{settled}, 0, "$l: ... so none of the parent's callbacks ran there";
    is $child{closed}, 0, "$l: the child closed none of the parent's connections";
    is $child{warned}, 0, "$l: the child warned nothing";

    is outcome($f), 'still pending', "$l: in the parent the statement is still in flight";
    answer($storage->{server}{1});
    turn();
    is_deeply outcome($f), [ [ 'row-for', 'a', 1 ] ],
      "$l: ... and resolves with its result";
    is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
      "$l: its connection back in the parent's pool";
    is_deeply [ splice @warnings ], [], "$l: nothing warned in the parent";
  }
}

# ---------------------------------------------------------------------------
# 7b. A forked child whose OWN loop turns while the parent's statement is in
#     flight. The child inherited the loop's watch list with the rest, and the
#     socket is as readable there as in the parent: its loop resolves the
#     parent's poll. Nothing may follow from that in the child -- no collect,
#     which would read the parent's answer off the shared socket and leave the
#     parent waiting for good; no release; no settled Future; no callback of
#     the parent's. As the listen watch loop already refuses a poll made in
#     another process. Asked for the first poll of a statement and for the
#     re-poll a driver makes from _collect_result when an answer comes in
#     parts.
# ---------------------------------------------------------------------------

SKIP: {
  skip 'fork is not available', 2 * 9 unless $Config{d_fork};

  for my $stage (qw( first-poll re-poll )) {
    my $l       = "forked child turns its loop, $stage";
    my $storage = new_storage(two_step => $stage eq 're-poll');
    my $pool    = $storage->pool;

    my $f = $storage->_query_async('SELECT * FROM a', []);
    my $settled = 0;
    $f->on_ready(sub { $settled++ });
    if ($stage eq 're-poll') {
      answer($storage->{server}{1});  # the first part: the driver polls again
      turn();
    }
    my $collects = scalar @{ $storage->{collected} };
    is outcome($f), 'still pending', "$l: the statement is in flight";

    answer($storage->{server}{1});    # readable in parent and child alike
    pipe(my $from_child, my $to_parent) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) {
      close $from_child;
      splice @warnings;
      my $turned = eval { turn(); 1 };
      my $report = join "\n",
        'turned=' . ($turned ? 1 : 0),
        'collects=' . (scalar(@{ $storage->{collected} }) - $collects),
        'settled=' . $settled,
        'future=' . (ref outcome($f) ? 'done' : outcome($f)),
        'warned=' . scalar @warnings,
        '';
      syswrite $to_parent, $report;
      POSIX::_exit(0);
    }
    close $to_parent;
    my $report = do { local $/; <$from_child> };
    waitpid $pid, 0;
    my %child = $report =~ /^(\w+)=(.*)$/mg;

    is $child{turned}, 1, "$l: the child's loop turns without dying";
    is $child{collects}, 0,
      "$l: the child does not collect -- it reads nothing off the parent's socket";
    is $child{future}, 'still pending',
      "$l: the parent's statement is not settled in the child";
    is $child{settled}, 0, "$l: ... so none of the parent's callbacks ran there";
    is $child{warned}, 0, "$l: the child warned nothing";

    turn();
    is_deeply outcome($f), [ [ 'row-for', 'a', 1 ] ],
      "$l: the parent reads its answer, untouched, and the statement resolves";
    is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
      "$l: its connection back in the parent's pool";
    is_deeply [ splice @warnings ], [], "$l: nothing warned in the parent";

    $storage->disconnect;             # nothing is left behind, whatever happened
    splice @warnings;
  }
}

# ---------------------------------------------------------------------------
# 8. A process that EXITS with a statement in flight. The pool is shut down
#    from DESTROY in global destruction, where Perl frees objects in no
#    particular order and no loop runs any more: nothing is settled there
#    (core k254 for the pool's own Futures) -- no callback runs, nothing warns.
#    Run in a child of its own, which owns the pool it exits with; what it
#    writes to stderr or reports arrives through a raw descriptor that no Perl
#    handle owns, so it still works while handles are being destroyed.
# ---------------------------------------------------------------------------

SKIP: {
  skip 'fork is not available', 3 unless $Config{d_fork};

  my $l = 'global destruction';
  pipe(my $from_child, my $to_parent) or die "pipe: $!";
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  unless ($pid) {
    close $from_child;
    my $raw = POSIX::dup(fileno $to_parent);
    POSIX::dup2($raw, 2);
    $SIG{__WARN__} = 'DEFAULT';

    our $KEPT_STORAGE = new_storage();
    our $KEPT_FUTURE  = $KEPT_STORAGE->_query_async('SELECT * FROM a', []);
    $KEPT_FUTURE->on_ready(sub { POSIX::write($raw, "SETTLED\n", 8) });
    POSIX::write($raw, "in flight\n", 10) unless $KEPT_FUTURE->is_ready;
    exit 0;                       # END blocks, then global destruction
  }
  close $to_parent;
  my $report = do { local $/; <$from_child> };
  waitpid $pid, 0;

  is $? >> 8, 0, "$l: the process exits cleanly";
  like $report, qr/\Ain flight\n/, "$l: it exited with a statement in flight";
  is $report, "in flight\n",
    "$l: ... and settled nothing and warned nothing on the way out";
}

# ---------------------------------------------------------------------------
# 9. The storage is DROPPED with a statement in flight. Nobody tears it down:
#    the statement in flight keeps it alive, completes, and only then is the
#    storage freed and its connection closed by the disconnect DESTROY runs.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped';
  my $storage = new_storage();

  my $f = $storage->_query_async('SELECT * FROM a', []);
  is outcome($f), 'still pending', "$l: the statement is in flight";

  my ($closed, $server) = ($storage->{closed}, $storage->{server}{1});
  weaken(my $weak_storage = $storage);
  undef $storage;

  answer($server);
  ok eval { turn(); 1 }, "$l: the storage is dropped, the answer arrives: nothing dies"
    or diag $@;

  is_deeply outcome($f), [ [ 'row-for', 'a', 1 ] ],
    "$l: the caller's Future settles, with the statement's result";
  ok !defined $weak_storage, "$l: the storage is gone";
  is_deeply $closed, [1], "$l: its connection is closed, once";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

ok loop_is_idle(), 'at the end of the file the loop watches nothing';
is_deeply \@warnings, [], '... and nothing warned on the way out of a section';

done_testing;
