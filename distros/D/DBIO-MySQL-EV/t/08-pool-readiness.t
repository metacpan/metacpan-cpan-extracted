use strict;
use warnings;
use Test::More;

# OFFLINE unit test for the karr #20 connection-readiness gating of
# DBIO::MySQL::EV::Pool. No EV::MariaDB, no real DB.
#
# WHY this can encode intent without a live server: the bug was that acquire()
# (inherited from core DBIO::Storage::PoolBase, karr #75) resolved its Future
# BEFORE the connection's on_connect fired -- DBIO::MySQL::EV::Pool wired
# on_connect => sub {}, a pure no-op, so the base's readiness gate had nothing
# to wait on. The gating logic is pure Perl and does not depend on
# EV::MariaDB's internals, so a fake connection swapped in through the
# _new_connection seam, with on_connect/on_error driven by hand on a *later*
# tick, exercises it fully. Mirrors dbio-postgresql-ev's t/04-pool-readiness.t
# (karr #9, the reference fix this mirrors).
#
# WHAT THIS SAMPLES CHANGED WITH karr k33, the observable claims did NOT. The
# wiring itself now lives in core (_create_ready_connection registers the
# per-connection readiness Future; PoolBase's default _connection_ready_future
# looks it back up), and this pool's _create_connection merely delegates to it.
# So these four assertions no longer prove that this driver IMPLEMENTS the
# gate -- they prove it SELECTS it, which is the driver-visible contract and
# the thing a future edit here could silently drop: core's _create_connection
# is a required hook, and a pool that stops calling _create_ready_connection
# hands out unconnected handles again with nothing else to notice.

# A minimal EV::MariaDB stand-in: captures the constructor callbacks, exposes
# is_connected, and lets the test fire on_connect / on_error explicitly. It
# answers what the pool asks of an idle connection before handing it out
# (karr k58): a socket -- one end of a real socketpair, with nothing to read,
# which is what a session that is still there looks like -- and nothing in
# flight.
package FakeMariaDB;
use Socket ();
sub new {
  my ($class, %args) = @_;
  socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
    or die "socketpair: $!";
  return bless {
    on_connect => $args{on_connect},
    on_error   => $args{on_error},
    connected  => 0,
    client     => $client,
    server     => $server,
  }, $class;
}
sub is_connected { $_[0]->{connected} }
sub socket        { fileno $_[0]->{client} }
sub pending_count { 0 }
sub fire_connect { my $s = shift; $s->{connected} = 1; $s->{on_connect}->() }
sub fire_error   { my $s = shift; $s->{on_error}->($_[0]) }
# As strict as EV::MariaDB 0.08 (karr k67): close_async needs a callback and a connected handle.
sub close_async  { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
sub finish       { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }

# Pool subclass that builds FakeMariaDB instead of a real EV::MariaDB handle.
# Only the raw-handle seam is overridden — everything else is the real
# DBIO::MySQL::EV::Pool, i.e. the real choice of core's readiness wiring.
package TestPool;
use base 'DBIO::MySQL::EV::Pool';
sub _new_connection { shift; FakeMariaDB->new(@_) }
sub _transform_conninfo { $_[1] }   # pass the dummy conninfo through unchanged

package main;

use DBIO::MySQL::EV::Pool;

# --- 1. acquire stays pending until on_connect fires (cold connection) ---

my $pool = TestPool->new(conninfo => { host => 'dummy' }, size => 2);
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
  conninfo => { host => 'dummy' },
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
#
# karr k197/k198 (core 3c9994a9 "retire readiness failures", 183a9dfa "guard
# reentrant readiness retirement", 0f1c6207 "make shutdown terminal"): the
# readiness Future failing no longer leaves the broken connection pooled. Core's
# PoolBase now calls _retire_readiness_failure when the readiness Future
# fails, and _retire_connection drops $conn from BOTH _connections AND _idle
# (and clears the readiness bookkeeping) -- the broken handle is GONE from
# the pool, not parked for retry. The OLD assertion ("releasing the broken
# conn and reacquiring it fails fast") sampled a path that no longer exists:
# release() re-introduces $bad into _idle, but the next acquire either finds
# the slot empty (and spawns a fresh conn) or hands out a still-broken one
# without a registered readiness Future -- never the "stale pending Future
# the OLD test was guarding against" scenario. We pin the NEW claim instead
# (retirement evidence + no-hang consequence on a fresh acquire), which is
# the contract that matters: a retry loop that re-issues a broken handle is
# exactly the bug k197 closes, and proving the loop is closed means proving
# the broken handle has left the pool.
ok !(grep { $_ == $bad } @{ $err_pool->{_connections} }),
  'a failed connection is RETIRED from _connections (k197)';
ok !(grep { $_ == $bad } @{ $err_pool->{_idle} }),
  'a failed connection is RETIRED from _idle (k197)';

# Consequence the old assertion was a proxy for: the next acquire does NOT
# hang. The pool has an open capacity slot (the broken conn was dropped), so
# _acquire_slot spawns a FRESH connection that is not $bad; once its
# on_connect fires, the readiness Future resolves and the new acquire
# succeeds. No retry loop, no stale readiness Future.
my $ef2 = $err_pool->acquire;
ok !$ef2->is_ready, 'a subsequent acquire is pending (the fresh conn is cold)';
my $fresh = $err_pool->{_connections}[-1];
isnt $fresh, $bad,
  'a fresh connection was spawned, not the retired one reused';
$fresh->fire_connect;
ok $ef2->is_ready && !$ef2->failure,
  'a subsequent acquire succeeds against the fresh connection (no hang)';

# --- 4. shutdown clears the readiness side table (no leak) ---
# core DBIO::Storage::PoolBase::shutdown clears it centrally (karr #75) -- this
# driver's _shutdown_connection never has to.

$pool->shutdown;
is_deeply $pool->{_ready}, {}, 'shutdown emptied the readiness side table';

done_testing;
