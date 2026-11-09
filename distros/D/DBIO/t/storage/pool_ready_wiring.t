use strict;
use warnings;
use Test::More;

# ADR 0030 section 4 ("Pool readiness-gating becomes a PoolBase
# default"): the readiness WIRING, not only its bookkeeping.
#
# t/storage/pool_readiness.t hoisted the side table and the
# _connection_ready_future seam, and left every async transport to hand-roll
# the same twelve lines: make a Future, wire on_connect/on_error onto it,
# register it, and override the seam to consult it. dbio-postgresql-ev and
# dbio-mysql-ev then wrote those lines byte-identically. This file pins the
# lifted version:
#
#   * _create_ready_connection builds the connection through _new_connection
#     with on_connect/on_error already wired onto a registered Future;
#   * the DEFAULT _connection_ready_future honours that registration, so an
#     async pool needs NO seam override at all;
#   * a synchronous pool is completely unaffected (the backwards-compat claim
#     the whole seam rests on -- an EV dist keeping its own version must not
#     break either, which is the same property from the other side).
#
# OFFLINE: no EV, no event loop, no database. The fake connection's connect
# is driven by hand, which is exactly why _new_connection is a named seam.

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

{
  package FakeConn;
  sub new {
    my ($class, %args) = @_;
    return bless {
      args        => \%args,
      connected   => 0,
      finished    => 0,
      close_count => 0,
    }, $class;
  }
  sub is_connected { $_[0]->{connected} }
  sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{args}{on_connect}->() }
  sub fire_error   { my $s = shift; $s->{args}{on_error}->($_[0]) }
  sub finish       { $_[0]->{finished} = 1; $_[0]->{close_count}++ }

  package DisconnectRecorder;
  sub new { bless { actions => [] }, $_[0] }
  sub _teardown_pool_connection { push @{ $_[0]->{actions} }, $_[1] }

  # The whole of an async pool after the lift: a _create_connection that
  # delegates to the core wiring, plus the raw-handle seam. No readiness
  # Future, no side table, no _connection_ready_future override.
  package WiredPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }

  sub _new_connection {
    my $self = shift;
    my $conn = FakeConn->new(@_);
    push @{ $self->{_built} }, $conn;
    return $conn;
  }

  sub _shutdown_connection { $_[1]->finish }

  # A pool that supplies neither _create_connection nor _new_connection.
  package BarePool;
  use base 'DBIO::Storage::PoolBase';

  # A pool that reaches the wiring without supplying the raw-handle seam.
  package NoHandlePool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { $_[0]->_create_ready_connection(conninfo => $_[1]) }
}

# ---------------------------------------------------------------------------
# 1. The wiring registers a readiness Future and passes the caller's args
#    through to the raw-handle seam.
# ---------------------------------------------------------------------------
{
  my $pool = WiredPool->new(
    conninfo     => 'dbname=x',
    size         => 2,
    future_class => 'DBIO::Test::Future',
  );

  my $f = $pool->acquire;
  ok !$f->is_ready,
    'acquire is pending on a cold connection with NO _connection_ready_future override';

  my $conn = $pool->{_built}[0];
  isa_ok $conn, 'FakeConn', 'the connection came from the _new_connection seam';
  is $conn->{args}{conninfo}, 'dbname=x',
    'caller arguments reached the constructor unchanged';
  ok $pool->_connection_ready_lookup($conn),
    'the readiness Future was registered by _create_ready_connection';
  is ref $conn->{args}{on_connect}, 'CODE', 'on_connect was wired by the base';
  is ref $conn->{args}{on_error},   'CODE', 'on_error was wired by the base';

  $conn->fire_connect;
  ok $f->is_ready, 'acquire resolves once on_connect fires';
  is $f->get, $conn, 'acquire resolved to the connection';
}

# ---------------------------------------------------------------------------
# 2. The wiring owns on_connect/on_error: a caller-supplied pair does not
#    survive, so nobody can silently disable the gate by passing their own.
#    (This is the shape of the bug the gate exists for: dbio-mysql-ev shipped
#    `on_connect => sub {}` and the first query on a cold pool died.)
# ---------------------------------------------------------------------------
{
  my $pool = WiredPool->new(
    conninfo     => 'x',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );
  my $mine = sub { die 'caller on_connect must not be installed' };
  my $conn = $pool->_create_ready_connection(
    conninfo   => 'x',
    on_connect => $mine,
    on_error   => $mine,
  );
  isnt $conn->{args}{on_connect}, $mine,
    'the readiness wiring overrides a caller-supplied on_connect';
  isnt $conn->{args}{on_error}, $mine,
    'the readiness wiring overrides a caller-supplied on_error';
}

# ---------------------------------------------------------------------------
# 3. The pool's own on_error still runs, and an error BEFORE connect fails the
#    acquire Future rather than hanging it. A never-ready handle is retired
#    without replaying disconnect actions.
# ---------------------------------------------------------------------------
{
  my @seen;
  my $disconnects = DisconnectRecorder->new;
  my $pool = WiredPool->new(
    conninfo     => 'x',
    size         => 1,
    storage      => $disconnects,
    on_error     => sub { push @seen, $_[0] },
    future_class => 'DBIO::Test::Future',
  );

  my $f = $pool->acquire;
  my $conn = $pool->{_built}[0];
  $conn->fire_error('could not connect to server');
  ok $f->is_ready,  'acquire became ready after a pre-connect error';
  ok $f->is_failed, 'acquire FAILED rather than hanging';
  eval { $f->get };
  like $@, qr/could not connect/, 'the failure carries the connect error';
  is_deeply \@seen, ['could not connect to server'],
    "the pool's own on_error ran as well as failing the readiness Future";
  is_deeply $disconnects->{actions}, [],
    'a never-ready connection does not run disconnect actions when retired';

  # After a pre-connect error, the failed handle does not occupy the one slot,
  # so this is a fresh connection rather than a queued waiter.
  my $g = $pool->acquire;
  my $ok = $pool->{_built}[1];
  ok $ok, 'the next acquire immediately spawned a replacement connection';
  if ($ok) {
    $ok->fire_connect;
    ok $g->is_ready && !$g->is_failed, 'second connection came up cleanly';
    $ok->fire_error('later runtime error');
    ok !$g->is_failed,
      'an error AFTER connect does not fail the already-resolved future';
    is scalar @seen, 2, 'the later error still reached the pool on_error';

    # The wiring does not take an error after connect for a dead connection
    # (ADR 0047, addenda 2026-09-27): which errors end a session is the
    # transport's knowledge -- EV::MariaDB, say, reports a failed secondary
    # result of a multi-statement query here, on a live session -- so the
    # transport reports a death through _mark_connection_dead itself.
    $pool->release($ok);
    my $again = $pool->acquire;
    ok $again->is_ready && !$again->is_failed && $again->get == $ok,
      'an error AFTER connect leaves the connection in the pool: it is handed out again';
  }
  else {
    fail 'second connection came up cleanly';
    fail 'an error AFTER connect does not fail the already-resolved future';
    fail 'the later error still reached the pool on_error';
    fail 'an error AFTER connect leaves the connection in the pool: it is handed out again';
  }
}

# ---------------------------------------------------------------------------
# 4. Idle reuse of a connected handle is ready at once, and shutdown clears the
#    side table (the driver's _shutdown_connection never touches it).
# ---------------------------------------------------------------------------
{
  my $pool = WiredPool->new(
    conninfo     => 'x',
    size         => 2,
    future_class => 'DBIO::Test::Future',
  );
  my $f = $pool->acquire;
  my $conn = $pool->{_built}[0];
  $conn->fire_connect;
  $f->get;

  $pool->release($conn);
  my $f2 = $pool->acquire;
  ok $f2->is_ready, 'idle reuse of a connected handle is ready at once';
  is $f2->get, $conn, 'idle reuse returned the same connection';

  $pool->shutdown;
  is $conn->{finished}, 1, '_shutdown_connection ran';
  is_deeply $pool->{_ready}, {}, 'shutdown cleared the readiness side table';
}

# ---------------------------------------------------------------------------
# 5. Shutdown settles a cold acquire terminally through the lifted wiring.
#    The cold handle is retired once, with no disconnect action, and a late
#    on_connect callback cannot restore either the Future or pool bookkeeping.
# ---------------------------------------------------------------------------
{
  my $disconnects = DisconnectRecorder->new;
  my $pool = WiredPool->new(
    conninfo     => 'x',
    size         => 1,
    storage      => $disconnects,
    future_class => 'DBIO::Test::Future',
  );

  my $acquire = $pool->acquire;
  ok !$acquire->is_ready,
    'wired acquire is readiness-pending before shutdown';
  my $conn = $pool->{_built}[0];
  isa_ok $conn, 'FakeConn', 'shutdown test has the cold wired connection';

  $pool->shutdown;
  ok $acquire->is_ready && $acquire->is_failed,
    'readiness-pending wired acquire fails during shutdown';
  eval { $acquire->get };
  like $@, qr/Connection pool has been shut down/,
    'wired acquire receives the stable shutdown diagnostic';
  is_deeply $pool->{_waiters}, [], 'no wired queue waiter remains after shutdown';
  is_deeply $pool->{_ready}, {}, 'wired readiness bookkeeping is empty after shutdown';
  is_deeply $pool->{_connections}, [],
    'cold wired connection is no longer registered after shutdown';
  is_deeply $disconnects->{actions}, [],
    'cold wired connection runs no disconnect action';

  if ($conn) {
    is $conn->{close_count}, 1, 'cold wired handle closes exactly once';
    $conn->fire_connect;
    ok $acquire->is_ready && $acquire->is_failed,
      'late wired connect callback cannot revive the failed acquire';
    is $conn->{close_count}, 1,
      'late wired callback cannot close the handle twice';
  }
  else {
    fail 'cold wired handle closes exactly once';
    fail 'late wired connect callback cannot revive the failed acquire';
    fail 'late wired callback cannot close the handle twice';
  }
}

# ---------------------------------------------------------------------------
# 6. Backwards compatibility, both directions.
#
#    a) _create_connection is STILL a required hook with the same message --
#       the lift adds a way in, it does not make the base guess one.
#    b) a pool that never registers readiness gets the old, unconditional
#       immediate done, and the default never auto-vivifies the side table.
# ---------------------------------------------------------------------------
{
  my $bare = BarePool->new(
    conninfo     => 'x',
    future_class => 'DBIO::Test::Future',
  );
  my $f = $bare->acquire;
  ok $f->is_failed, '_create_connection is still required (a failed Future)';
  eval { $f->get };
  like $@, qr/Subclass must override _create_connection/,
    'and still with the same message';

  my $conn = bless {}, 'PlainConn';
  my $ready = $bare->_connection_ready_future($conn);
  ok $ready->is_ready, 'default seam is an immediate done for an unregistered connection';
  is $ready->get, $conn, 'and resolves to that connection';
  is $bare->{_ready}, undef, 'the default never auto-vivified the readiness table';
}

# ---------------------------------------------------------------------------
# 7. Reaching the wiring without the raw-handle seam fails loud and by name.
# ---------------------------------------------------------------------------
{
  my $pool = NoHandlePool->new(
    conninfo     => 'x',
    future_class => 'DBIO::Test::Future',
  );
  my $f = $pool->acquire;
  ok $f->is_failed, '_create_ready_connection without _new_connection fails';
  eval { $f->get };
  like $@, qr/Subclass must override _new_connection/,
    'and names the seam that is missing';
}

# ---------------------------------------------------------------------------
# 8. The is_connected fast path can only ever short-circuit TO the old answer.
#    A handle that answers false falls through to the lookup; one that answers
#    true is done at once. Neither can make a synchronous pool worse.
# ---------------------------------------------------------------------------
{
  my $pool = WiredPool->new(
    conninfo     => 'x',
    future_class => 'DBIO::Test::Future',
  );

  my $unconnected = FakeConn->new;
  my $r1 = $pool->_connection_ready_future($unconnected);
  ok $r1->is_ready, 'is_connected false, nothing registered -> immediate done';

  $unconnected->{connected} = 1;
  my $r2 = $pool->_connection_ready_future($unconnected);
  ok $r2->is_ready, 'is_connected true -> immediate done';
  is $r2->get, $unconnected, 'and resolves to the connection';

  # A handle with no is_connected at all (the generic case core must tolerate).
  my $plain = bless {}, 'PlainConn';
  my $pending = DBIO::Test::Future->new;
  $pool->_register_connection_ready($plain, $pending);
  my $r3 = $pool->_connection_ready_future($plain);
  is $r3, $pending,
    'a handle without is_connected still resolves through the registered future';
}

done_testing;
