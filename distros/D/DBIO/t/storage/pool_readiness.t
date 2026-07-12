use strict;
use warnings;
use Test::More;

# karr #75: connection-readiness-before-handoff, hoisted into the shared pool.
#
# The bug this guards against (production: dbio-mysql-ev karr #20): an async
# pool must not resolve acquire()'s Future until the connection has actually
# finished connecting -- an event-loop transport (EV::Pg, EV::MariaDB) returns
# a handle before its background connect completes, and the first bound query
# on that cold handle dies "not connected". dbio-postgresql-ev fixed this for
# itself (karr #9); this ticket hoists the mechanism into DBIO::Storage::PoolBase
# so every async transport gets it by overriding ONE seam
# (_connection_ready_future) instead of re-inventing acquire() + a refaddr side
# table per driver.
#
# OFFLINE unit test, in the style of dbio-postgresql-ev t/04-pool-readiness.t:
# no EV, no real DB, no event loop. Fake connections whose connect completes on
# a later tick, driven by hand, so the test fails if acquire ever stops routing
# a path through the readiness seam, or if the base ever stops clearing the
# readiness side table at shutdown.

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Storage::PoolBase;

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
      connected  => 0,
      finished   => 0,
    }, $class;
  }
  sub is_connected { $_[0]->{connected} }
  sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{on_connect}->() }
  sub fire_error   { my $s = shift; $s->{on_error}->($_[0]) }
  sub finish       { $_[0]->{finished} = 1 }

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
    $self->_register_connection_ready($conn, $ready);
    return $conn;
  }

  # Deliberately does NOT delete from the readiness table -- proving the base
  # clears it for us at shutdown.
  sub _shutdown_connection { $_[1]->finish }
}

# ---------------------------------------------------------------------------
# 1. Bookkeeping primitives round-trip by refaddr (register / lookup / clear).
# ---------------------------------------------------------------------------
{
  my $pool = SyncPool->new(conninfo => 'x');
  my $ca = bless {}, 'Dummy';
  my $cb = bless {}, 'Dummy';

  is $pool->_connection_ready_lookup($ca), undef,
    'lookup before any register is undef (no side table yet)';

  my $fa = Future->done($ca);
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
#    the queued-waiter path (karr #75, scope point 2).
# ---------------------------------------------------------------------------
{
  my $cp = CountPool->new(conninfo => 'x', size => 1);

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
  my $pool = AsyncPool->new(conninfo => 'dummy', size => 2);

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
# 4. A connect ERROR fails the acquire Future (does not hang), and a later
#    reacquire of the broken connection fails fast rather than hanging on a
#    stale pending readiness future.
# ---------------------------------------------------------------------------
{
  my $pool = AsyncPool->new(
    conninfo => 'dummy',
    size     => 2,
    on_error => sub { },   # swallow the failing-connect warning
  );

  my $ef = $pool->acquire;
  ok !$ef->is_ready, 'acquire pending before the connect attempt resolves';

  my $bad = $pool->{_connections}[0];
  $bad->fire_error('could not connect to server');

  ok $ef->is_ready, 'acquire Future becomes ready after a connect error';
  ok $ef->failure,  'acquire Future FAILED (rather than hanging) on connect error';
  like $ef->failure, qr/could not connect/, 'failure carries the connect error';

  $pool->release($bad);
  my $ef2 = $pool->acquire;
  ok $ef2->is_ready && $ef2->failure,
    'reacquiring a failed connection fails fast (no hang on a stale future)';
}

# ---------------------------------------------------------------------------
# 5. The DEFAULT seam is a pure no-op for synchronous pools: acquire is ready
#    immediately AND the default never touches the readiness bookkeeping.
# ---------------------------------------------------------------------------
{
  my $pool = SyncPool->new(conninfo => 'x', size => 2);

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
