use strict;
use warnings;
use Test::More;

# OFFLINE unit test for the karr k9 connection-readiness gating in
# DBIO::PostgreSQL::EV::Pool. No EV::Pg, no real DB.
#
# WHY this can encode intent without a live server: the bug is that acquire()
# resolved its Future BEFORE the connection's on_connect fired. The gating
# logic that fixes it -- core DBIO::Storage::PoolBase::acquire chaining
# through the _connection_ready_future seam (core k75; this pool's own
# acquire() override was removed once the gating moved to the base), with
# _create_connection wiring on_connect/on_error to a per-connection readiness
# Future via core's _register_connection_ready -- is pure Perl and does not
# depend on EV::Pg's internals. We swap in a fake connection via core's
# _new_connection seam and drive on_connect/on_error by hand on a *later* tick,
# so this test fails if acquire ever stops waiting for readiness, stops
# short-circuiting an already-connected (idle-reused) connection, or stops
# failing on a connect error.
#
# karr k34 -- WHAT THESE FOUR ASSERTIONS SAMPLE HAS CHANGED, though not one of
# them was reworded. Before k34 they proved this driver IMPLEMENTS the gate (a
# hand-written _connection_ready_future plus its own on_connect/on_error
# wiring). Core now owns both, so they prove this driver SELECTS it -- that
# _create_connection still routes through _create_ready_connection. That is
# worth keeping, because _create_connection remains a REQUIRED hook in core: a
# pool that quietly stopped calling _create_ready_connection would go back to
# handing out unconnected handles, and nothing else in this suite would notice.

# A minimal EV::Pg stand-in: captures the constructor callbacks, exposes
# is_connected, and lets the test fire on_connect / on_error explicitly.
package FakePg;
sub new {
  my ($class, %args) = @_;
  return bless {
    on_connect => $args{on_connect},
    on_error   => $args{on_error},
    connected  => 0,
  }, $class;
}
sub is_connected { $_[0]->{connected} }
# Asked of an idle handle before it is handed out again (karr k72): nothing in
# flight, and no socket to look at.
sub pending_count { 0 }
sub socket        { -1 }
sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{on_connect}->() }
sub fire_error   { my $s = shift; $s->{on_error}->($_[0]) }
sub finish       { }

# Pool subclass that builds FakePg instead of a real EV::Pg handle. Only the
# constructor seam is overridden — the readiness wiring under test is the real
# DBIO::PostgreSQL::EV::Pool code.
package TestPool;
use base 'DBIO::PostgreSQL::EV::Pool';
sub _new_connection { shift; FakePg->new(@_) }
sub _transform_conninfo { $_[1] }   # pass the dummy conninfo through unchanged

package main;

use DBIO::PostgreSQL::EV::Pool;

# --- 1. acquire stays pending until on_connect fires (cold connection) ---

my $pool = TestPool->new(conninfo => 'dummy', size => 2);
my $f = $pool->acquire;
ok !$f->is_ready, 'acquire Future is pending while the connection is cold';

# The fake connection now finishes its async connect on a later tick.
my $conn = $pool->{_connections}[0];
isa_ok $conn, 'FakePg', 'pool spawned a (fake) connection';
$conn->fire_connect;

ok $f->is_ready, 'acquire Future resolves once on_connect fires';
is $f->get, $conn, 'acquire resolves to the now-connected connection';

# --- 2. idle reuse is ready IMMEDIATELY (no re-waiting / no hang) ---

$pool->release($conn);
my $f2 = $pool->acquire;
ok $f2->is_ready, 'reacquiring an already-connected idle connection is ready at once';
is $f2->get, $conn, 'idle reuse returns the same connected connection';

# --- 3. a connect ERROR fails the acquire Future (does not hang forever) ---

my $err_pool = TestPool->new(
  conninfo => 'dummy',
  size     => 2,
  on_error => sub { },   # swallow so the failing-connect warning stays quiet
);
my $ef = $err_pool->acquire;
ok !$ef->is_ready, 'acquire pending before the connect attempt resolves';

my $bad = $err_pool->{_connections}[0];
$bad->fire_error('could not connect to server');

ok $ef->is_ready, 'acquire Future becomes ready after a connect error';
ok $ef->failure, 'acquire Future FAILED (rather than hanging) on connect error';
like $ef->failure, qr/could not connect/, 'failure carries the connect error';

# CORE k197/k198 ADOPTION. The pre-k197 reclaim path tested here -- release the
# never-connected $bad back to idle, then reacquire and watch the recycled
# broken handle fail fast -- no longer exists: after a connect error, core
# PoolBase::_retire_readiness_failure removes the broken handle from BOTH
# _connections AND _ready synchronously, so release($bad) on a handle that was
# retired before it was ever checked out pushes an orphan back onto _idle that
# the next acquire then hands out as a normal connection (broken, yes, but
# structurally a normal future). The post-k197 guarantee is stronger: the
# broken handle is permanently removed from the pool, and a fresh acquire
# spawns a brand-new connection that goes through the normal readiness gate.

# 3a. The connect-error retired the broken handle from the pool's connection
# inventory (k197 _retire_readiness_failure removes the conn from _connections).
is scalar @{ $err_pool->{_connections} }, 0,
  'connect-error retires the broken connection (k197)';

# 3b. Fresh acquire -- no prior release of the broken handle -- spawns a
# NEW conn. The new conn is cold, so acquire is pending; firing on_connect
# on the new conn resolves the acquire Future (k198 shutdown is terminal so
# re-spawn is the supported way to recover from a connect failure).
my $ef3 = $err_pool->acquire;
my $recovered = $err_pool->{_connections}[0];
isa_ok $recovered, 'FakePg', 'fresh acquire after retire spawned a new (fake) connection';
$recovered->fire_connect;
ok $ef3->is_ready && !$ef3->failure,
  'fresh acquire after retire resolves to a non-failed future';

# --- 4. shutdown clears the readiness side table (no leak) ---

$pool->shutdown;
is_deeply $pool->{_ready}, {}, 'shutdown emptied the readiness side table';

done_testing;
