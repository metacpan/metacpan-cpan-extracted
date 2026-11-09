use strict;
use warnings;
use Test::More;

# Connection-readiness-before-handoff, hoisted into the shared pool.
#
# The bug this guards against (seen in production in dbio-mysql-ev): an async
# pool must not resolve acquire()'s Future until the connection has actually
# finished connecting -- an event-loop transport (EV::Pg, EV::MariaDB) returns
# a handle before its background connect completes, and the first bound query
# on that cold handle dies "not connected". dbio-postgresql-ev fixed this for
# itself; core hoists the mechanism into DBIO::Storage::PoolBase
# so every async transport gets it by overriding ONE seam
# (_connection_ready_future) instead of re-inventing acquire() + a refaddr side
# table per driver.
#
# OFFLINE unit test, in the style of dbio-postgresql-ev t/04-pool-readiness.t:
# no EV, no real DB, no event loop. Fake connections whose connect completes on
# a later tick, driven by hand, so the test fails if acquire ever stops routing
# a path through the readiness seam, or if the base ever stops clearing the
# readiness side table at shutdown.

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# --- a synchronous pool: never overrides the readiness seam -----------------
{
  package SyncPool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]->{_n} }, 'SyncConn' }
}

# --- a pool that counts how often the seam is invoked -----------------------
# Still a no-op (returns done), but records every call, so we can prove acquire
# routes ALL THREE slot paths (spawn / idle-reuse / waiter) through the seam.
{
  package CountPool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]->{_n} }, 'CountConn' }
  sub _connection_ready_future {
    my ($self, $conn) = @_;
    $self->{ready_calls}++;
    return $self->future_class->done($conn);
  }
}

# --- an async-style pool built ONLY from the core bookkeeping primitives -----
# This is the shape a real async driver (mysql-ev, postgresql-ev) reduces to
# after adopting the hoist: wire on_connect/on_error onto a Future, register it
# with the core, and consult it from the seam. No hand-rolled side table, and
# _shutdown_connection does NOT touch the table -- the base clears it.
{
  package FakeAsyncConn;
  sub new {
    my ($class, %args) = @_;
    return bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      connected   => 0,
      finished    => 0,
      close_count => 0,
    }, $class;
  }
  sub is_connected { $_[0]->{connected} }
  sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{on_connect}->() }
  sub fire_error   { my $s = shift; $s->{on_error}->($_[0]) }
  sub finish       { $_[0]->{finished} = 1; $_[0]->{close_count}++ }

  package ReadinessDisconnectRecorder;
  sub new { bless { actions => [] }, $_[0] }
  sub _teardown_pool_connection { push @{ $_[0]->{actions} }, $_[1] }

  package AsyncPool;
  use base 'DBIO::Storage::PoolBase';

  sub _connection_ready_future {
    my ($self, $conn) = @_;
    return $self->future_class->done($conn) if $conn->is_connected;
    return $self->_connection_ready_lookup($conn)
        || $self->future_class->done($conn);
  }

  sub _create_connection {
    my ($self, $conninfo) = @_;
    my $ready    = $self->future_class->new;
    my $on_error = $self->{on_error};
    my $conn;
    $conn = FakeAsyncConn->new(
      on_connect => sub { $ready->done($conn) unless $ready->is_ready },
      on_error   => sub {
        $ready->fail($_[0]) unless $ready->is_ready;
        $on_error->(@_);
      },
    );
    push @{ $self->{_built} }, $conn;
    $self->_register_connection_ready($conn, $ready);
    return $conn;
  }

  # Deliberately does NOT delete from the readiness table -- proving the base
  # clears it for us at shutdown.
  sub _shutdown_connection { $_[1]->finish }

  package ThrowingReadyPool;
  use base 'AsyncPool';
  sub _connection_ready_future {
    my ($self, $conn) = @_;
    die 'readiness seam threw synchronously' if $self->{throw_ready};
    return $self->SUPER::_connection_ready_future($conn);
  }

  package ReentrantAsyncConn;
  sub new {
    my ($class, %args) = @_;
    return bless {
      on_error       => $args{on_error},
      close_count    => 0,
      callback_count => 0,
      error_fired    => 0,
    }, $class;
  }
  sub is_connected { 0 }
  sub finish {
    my $self = shift;
    $self->{close_count}++;
    return if $self->{error_fired}++;
    $self->{callback_count}++;
    $self->{on_error}->('connection closed while waiting for readiness');
  }

  package ReentrantAsyncPool;
  use base 'AsyncPool';
  sub _create_connection {
    my ($self, $conninfo) = @_;
    my $ready = $self->future_class->new;
    my $conn;
    $conn = ReentrantAsyncConn->new(
      on_error => sub {
        $ready->fail($_[0]) unless $ready->is_ready;
        $self->_retire_connection($conn);
      },
    );
    push @{ $self->{_built} }, $conn;
    $self->_register_connection_ready($conn, $ready);
    return $conn;
  }
}

# ---------------------------------------------------------------------------
# 1. Bookkeeping primitives round-trip by refaddr (register / lookup / clear).
# ---------------------------------------------------------------------------
{
  my $pool = SyncPool->new(
    conninfo     => 'x',
    future_class => 'DBIO::Test::Future',
  );
  my $ca = bless {}, 'Dummy';
  my $cb = bless {}, 'Dummy';

  is $pool->_connection_ready_lookup($ca), undef,
    'lookup before any register is undef (no side table yet)';

  my $fa = DBIO::Test::Future->done($ca);
  is $pool->_register_connection_ready($ca, $fa), $fa,
    '_register_connection_ready returns the future it stored';
  is $pool->_connection_ready_lookup($ca), $fa,
    'lookup returns the registered future, keyed by refaddr';
  is $pool->_connection_ready_lookup($cb), undef,
    'lookup for an unregistered connection is undef';

  $pool->_clear_connection_ready($ca);
  is $pool->_connection_ready_lookup($ca), undef,
    '_clear_connection_ready removes the entry';
}

# ---------------------------------------------------------------------------
# 2. acquire ALWAYS routes through the seam -- fresh spawn, idle reuse, AND
#    the queued-waiter path.
# ---------------------------------------------------------------------------
{
  my $cp = CountPool->new(
    conninfo     => 'x',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );

  my $c1 = $cp->acquire->get;                      # fresh-spawn path
  is $cp->{ready_calls}, 1, 'seam runs on the fresh-spawn path';

  $cp->release($c1);
  my $c2 = $cp->acquire->get;                       # idle-reuse path
  is $cp->{ready_calls}, 2, 'seam runs on the idle-reuse path';
  is $c2, $c1, 'idle reuse returned the same connection';

  my $pending = $cp->acquire;                        # pool full -> queued waiter
  ok !$pending->is_ready, 'concurrent acquire on a full pool queues a waiter';
  is $cp->{ready_calls}, 2, 'seam has NOT run for the still-queued waiter';

  $cp->release($c2);                                 # hands straight to waiter
  ok $pending->is_ready, 'waiter resolved on release';
  is $cp->{ready_calls}, 3, 'seam runs on the waiter path too';
  is $pending->get, $c2, 'waiter received the connection through the seam';
}

# ---------------------------------------------------------------------------
# 3. Async gating end-to-end via the core primitives: acquire stays pending
#    until on_connect fires; idle reuse is ready at once; a connect error fails
#    the Future; shutdown clears the readiness table via the BASE hook.
# ---------------------------------------------------------------------------
{
  my $pool = AsyncPool->new(
    conninfo     => 'dummy',
    size         => 2,
    future_class => 'DBIO::Test::Future',
  );

  my $f = $pool->acquire;
  ok !$f->is_ready, 'acquire Future is pending while the connection is cold';

  my $conn = $pool->{_connections}[0];
  isa_ok $conn, 'FakeAsyncConn', 'pool spawned a (fake) async connection';
  ok $pool->_connection_ready_lookup($conn),
    'the core side table holds a readiness future for the cold connection';

  $conn->fire_connect;
  ok $f->is_ready, 'acquire Future resolves once on_connect fires';
  is $f->get, $conn, 'acquire resolves to the now-connected connection';

  # idle reuse: already connected -> ready immediately, no re-waiting
  $pool->release($conn);
  my $f2 = $pool->acquire;
  ok $f2->is_ready, 'reacquiring an already-connected idle connection is ready at once';
  is $f2->get, $conn, 'idle reuse returns the same connected connection';

  # shutdown must clear the side table even though _shutdown_connection did not
  $pool->shutdown;
  is $conn->{finished}, 1, '_shutdown_connection ran (connection finished)';
  is_deeply $pool->{_ready}, {},
    'shutdown cleared the readiness side table via the base hook '
    . '(driver _shutdown_connection never touched it)';
}

# ---------------------------------------------------------------------------
# 4. Shutdown is terminal even while readiness is pending: the acquire fails,
#    all internal bookkeeping is empty before a late connect callback can run,
#    and the never-ready handle is retired without disconnect actions.
# ---------------------------------------------------------------------------
{
  my $disconnects = ReadinessDisconnectRecorder->new;
  my $pool = AsyncPool->new(
    conninfo     => 'dummy',
    size         => 1,
    storage      => $disconnects,
    future_class => 'DBIO::Test::Future',
  );

  my $acquire = $pool->acquire;
  ok !$acquire->is_ready,
    'readiness-pending acquire is cold before shutdown';
  my $conn = $pool->{_built}[0];
  isa_ok $conn, 'FakeAsyncConn',
    'shutdown test has the cold fake connection';

  $pool->shutdown;
  ok $acquire->is_ready && $acquire->is_failed,
    'readiness-pending acquire fails during shutdown';
  eval { $acquire->get };
  like $@, qr/Connection pool has been shut down/,
    'readiness-pending acquire receives the stable shutdown diagnostic';
  is_deeply $pool->{_waiters}, [], 'no queue waiter remains after shutdown';
  is_deeply $pool->{_ready}, {}, 'readiness bookkeeping is empty after shutdown';
  is_deeply $pool->{_connections}, [],
    'cold connection is no longer registered after shutdown';
  is_deeply $disconnects->{actions}, [],
    'cold connection runs no disconnect action';

  if ($conn) {
    is $conn->{close_count}, 1, 'cold handle closes exactly once';
    $conn->fire_connect;
    ok $acquire->is_ready && $acquire->is_failed,
      'late connect callback cannot revive the failed acquire';
    is $conn->{close_count}, 1, 'late callback cannot close the handle twice';
  }
  else {
    fail 'cold handle closes exactly once';
    fail 'late connect callback cannot revive the failed acquire';
    fail 'late callback cannot close the handle twice';
  }
}

# ---------------------------------------------------------------------------
# 5. A readiness ERROR preserves the failed Future while retiring its counted
#    slot exactly once, so the next acquire can spawn immediately.
# ---------------------------------------------------------------------------
{
  my $pool = AsyncPool->new(
    conninfo     => 'dummy',
    size         => 1,
    on_error     => sub { },   # swallow the failing-connect warning
    future_class => 'DBIO::Test::Future',
  );

  my $failed = $pool->acquire;
  ok !$failed->is_ready, 'acquire pending before the connect attempt resolves';

  my $bad = $pool->{_built}[0];
  $bad->fire_error('could not connect to server');
  ok $failed->is_ready && $failed->is_failed,
    'readiness failure settles acquire as a failed Future';
  is $pool->size, 0, 'failed readiness retires the occupied slot';
  is $pool->_connection_ready_lookup($bad), undef,
    'failed readiness bookkeeping was cleared';
  is_deeply $pool->{_ready}, {}, 'the readiness bookkeeping is empty after retirement';
  is $bad->{close_count}, 1, 'bad handle was closed exactly once';

  $pool->_retire_connection($bad);
  is $bad->{close_count}, 1,
    'second retirement does not close the same handle again';
  eval { $failed->get };
  like $@, qr/could not connect to server/,
    'acquire Future preserves the readiness error';

  my $replacement = $pool->acquire;
  my $good = $pool->{_built}[1];
  ok $good, 'the next acquire immediately spawns a replacement connection';
  $good->fire_connect if $good;
  ok $replacement->is_ready && !$replacement->is_failed,
    'next acquire immediately uses replacement capacity';
}

# ---------------------------------------------------------------------------
# 6. A synchronous readiness-seam throw stays inside acquire's Future contract:
#    it retires the one occupied slot, and a later healthy seam can replace it.
# ---------------------------------------------------------------------------
{
  my $pool = ThrowingReadyPool->new(
    conninfo     => 'dummy',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );
  $pool->{throw_ready} = 1;

  my $failed;
  my $acquired = eval {
    $failed = $pool->acquire;
    1;
  };
  ok $acquired, 'a synchronous readiness-seam throw does not escape acquire';
  isa_ok $failed, 'DBIO::Test::Future',
    'acquire still returns a DBIO::Test::Future after a synchronous throw';
  ok $failed->is_ready && $failed->is_failed,
    'the synchronous readiness-seam throw becomes a failed Future';
  eval { $failed->get };
  like $@, qr/readiness seam threw synchronously/,
    'the failed Future preserves the original readiness-seam diagnostic';

  my $bad = $pool->{_built}[0];
  is $pool->size, 0, 'the synchronous readiness failure retires the one slot';
  is $pool->_connection_ready_lookup($bad), undef,
    'the synchronous readiness failure clears its readiness bookkeeping';
  is_deeply $pool->{_ready}, {},
    'the synchronous readiness failure leaves no readiness bookkeeping';
  is $bad->{close_count}, 1,
    'the synchronous readiness failure closes its handle exactly once';

  $pool->{throw_ready} = 0;
  my $replacement = $pool->acquire;
  my $good = $pool->{_built}[1];
  ok $good,
    'disabling the throw lets the next acquire immediately spawn a replacement';
  if ($good) {
    $good->fire_connect;
    ok $replacement->is_ready && !$replacement->is_failed,
      'the replacement succeeds once its readiness callback fires';
  }
  else {
    fail 'the replacement succeeds once its readiness callback fires';
  }
}

# ---------------------------------------------------------------------------
# 7. shutdown can reenter retirement from a cold handle's synchronous close
#    callback. The reentrant path must not close that same handle twice.
# ---------------------------------------------------------------------------
{
  my $pool = ReentrantAsyncPool->new(
    conninfo     => 'dummy',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );

  my $failed = $pool->acquire;
  ok !$failed->is_ready, 'cold reentrant handle leaves acquire pending';
  my $conn = $pool->{_built}[0];

  $pool->shutdown;
  ok $failed->is_ready && $failed->is_failed,
    'shutdown-time readiness callback fails the pending acquire Future';
  eval { $failed->get };
  like $@, qr/Connection pool has been shut down/,
    'terminal shutdown diagnostic wins before the synchronous close callback';
  is $conn->{callback_count}, 1,
    'finish synchronously invokes its reentrant retirement callback once';
  is $conn->{close_count}, 1,
    'reentrant retirement closes the cold handle exactly once';
  is_deeply $pool->{_connections}, [],
    'reentrant shutdown leaves no connection registered';
  is_deeply $pool->{_ready}, {},
    'reentrant shutdown leaves no readiness bookkeeping';
}

# ---------------------------------------------------------------------------
# 8. Direct retirement of an idle, ready connection removes it from both pool
#    registries and closes it once.
# ---------------------------------------------------------------------------
{
  my $pool = AsyncPool->new(
    conninfo     => 'dummy',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );

  my $acquired = $pool->acquire;
  my $conn = $pool->{_built}[0];
  $conn->fire_connect;
  is $acquired->get, $conn, 'ready connection was acquired before retirement';

  $pool->release($conn);
  is $pool->available, 1, 'released ready connection is idle before retirement';
  $pool->_retire_connection($conn);
  is $pool->available, 0, 'retirement removes the ready connection from idle';
  is $pool->size, 0, 'retirement removes the ready connection from the pool';
  is $conn->{close_count}, 1, 'retirement closes the ready idle handle once';
}

# ---------------------------------------------------------------------------
# 9. The DEFAULT seam is a pure no-op for synchronous pools: acquire is ready
#    immediately AND the default never touches the readiness bookkeeping.
# ---------------------------------------------------------------------------
{
  my $pool = SyncPool->new(
    conninfo     => 'x',
    size         => 2,
    future_class => 'DBIO::Test::Future',
  );

  my $f = $pool->acquire;
  ok $f->is_ready, 'synchronous pool acquire resolves immediately (default no-op seam)';
  isa_ok scalar $f->get, 'SyncConn', 'resolved to the connection object';

  is $pool->{_ready}, undef,
    'default seam never auto-vivifies the readiness side table for a sync pool';

  # and a no-op _connection_ready_future returns a done future straight away
  my $conn = bless {}, 'SyncConn';
  my $ready = $pool->_connection_ready_future($conn);
  ok $ready->is_ready, 'default _connection_ready_future is an immediate done';
  is $ready->get, $conn, 'default _connection_ready_future resolves to the connection';
}

done_testing;
