use strict;
use warnings;
use Test::More;

# OFFLINE unit test for the karr #20 connection-readiness gating in
# DBIO::MySQL::EV::Pool. No EV::MariaDB, no real DB.
#
# WHY this can encode intent without a live server: the bug was that acquire()
# (inherited from core DBIO::Storage::PoolBase, karr #75) resolved its Future
# BEFORE the connection's on_connect fired -- DBIO::MySQL::EV::Pool wired
# on_connect => sub {}, a pure no-op, so the base's readiness gate had nothing
# to wait on. The gating logic under test here (_create_connection wiring
# on_connect/on_error to a per-connection readiness Future registered via
# core's _register_connection_ready, and _connection_ready_future looking it
# back up) is pure Perl and does not depend on EV::MariaDB's internals. We
# swap in a fake connection via the _new_ev_mariadb seam and drive
# on_connect/on_error by hand on a *later* tick, mirroring
# dbio-postgresql-ev's t/04-pool-readiness.t (karr #9, the reference fix this
# mirrors).

# A minimal EV::MariaDB stand-in: captures the constructor callbacks, exposes
# is_connected, and lets the test fire on_connect / on_error explicitly.
package FakeMariaDB;
sub new {
  my ($class, %args) = @_;
  return bless {
    on_connect => $args{on_connect},
    on_error   => $args{on_error},
    connected  => 0,
  }, $class;
}
sub is_connected { $_[0]->{connected} }
sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{on_connect}->() }
sub fire_error   { my $s = shift; $s->{on_error}->($_[0]) }
sub close_async  { }

# Pool subclass that builds FakeMariaDB instead of a real EV::MariaDB handle.
# Only the constructor seam is overridden — the readiness wiring under test is
# the real DBIO::MySQL::EV::Pool code.
package TestPool;
use base 'DBIO::MySQL::EV::Pool';
sub _new_ev_mariadb { shift; FakeMariaDB->new(@_) }
sub _transform_conninfo { $_[1] }   # pass the dummy conninfo through unchanged

package main;

use DBIO::MySQL::EV::Pool;

# --- 1. acquire stays pending until on_connect fires (cold connection) ---

my $pool = TestPool->new(conninfo => 'dummy', size => 2);
my $f = $pool->acquire;
ok !$f->is_ready, 'acquire Future is pending while the connection is cold';

# The fake connection now finishes its async connect on a later tick.
my $conn = $pool->{_connections}[0];
isa_ok $conn, 'FakeMariaDB', 'pool spawned a (fake) connection';
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

# A later reacquire of the same broken (never-connected) connection must also
# fail fast rather than hang on a stale pending readiness Future.
$err_pool->release($bad);
my $ef2 = $err_pool->acquire;
ok $ef2->is_ready && $ef2->failure, 'reacquiring a failed connection fails fast (no hang)';

# --- 4. shutdown clears the readiness side table (no leak) ---
# core DBIO::Storage::PoolBase::shutdown clears it centrally (karr #75) -- this
# driver's _shutdown_connection never has to.

$pool->shutdown;
is_deeply $pool->{_ready}, {}, 'shutdown emptied the readiness side table';

done_testing;
