use strict;
use warnings;
use Test::More;

use Future;

use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mocks' sql_maker_class
use DBIO::Storage::PoolBase;
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k28 (core k241, core ADR 0047 addendum 2026-09-27): a
# driver on this transport can tell the pool that an idle connection died
# before the pool hands it out.
#
# WHY IT MATTERS. A connection whose server session ended while it sat idle --
# a server restart, an idle timeout, an administrator's kill -- was handed out
# unchecked, and only the caller's failed query reported it (k26,
# _conn_error_is_fatal). After a server restart every idle connection is dead,
# so the pool failed one caller per idle connection before it recovered. Core
# k241 gave PoolBase a borrow-time seam, _idle_connection_alive, asked about
# each idle connection acquire is about to hand out. But core asks the POOL,
# and a future_io driver writes a storage adapter, never a pool: without
# DBIO::Async::Pool delegating the question to the storage, a driver could not
# answer it at all. That delegation, and the storage seam it lands on, is what
# this file pins.
#
# WHAT IS REAL. The pool is the real DBIO::Async::Pool that
# DBIO::Async::Storage::pool builds, with core's real acquire, _acquire_slot,
# _idle_connection_usable (which catches the throw and routes it to on_error)
# and _retire_connection (this pool adds one step after core's, karr k49); its on_error is the storage's real one, which warns.
# The readiness gate is the transport's real _await_conn_ready. The mocks own
# the DB-specific seams and nothing else, which section 0 pins.
#
# THE SUBSTITUTIONS. A connection is a hashref whose 'alive' flag stands for
# the local state a driver would read; no socket, no event loop, no database.

# --- Plain23: the DB-specific seams, no liveness check ----------------------

{
  package Plain23;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }

  sub _create_pool_connection {
    my $self = shift;
    return { id => ++$self->{_next_id}, alive => 1 };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
  }
}

# --- Vouch23: the same driver, with the seam filled -------------------------

{
  package Vouch23;
  our @ISA = ('Plain23');

  # Answers the way the contract asks: from local state only. Records who
  # was asked (the invocant) and about what.
  sub _idle_connection_alive {
    my ($self, $conn) = @_;
    push @{ $self->{asked} }, [ $self, $conn ];
    die "probe broke\n" if $conn->{probe_dies};
    return $conn->{alive};
  }
}

sub new_storage {
  my ($class, $size) = @_;
  my $storage = $class->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(shutdown asked);
  $storage->connect_info([{ host => 'localhost', pool_size => $size }]);
  return $storage;
}

# Check out $n connections and put them back, so they sit idle in id order
# (the pool hands out the longest-idle one first).
sub fill_idle {
  my ($pool, $n) = @_;
  my @conns = map { $pool->acquire->get } 1 .. $n;
  $pool->release($_) for @conns;
  return @conns;
}

sub asked_ids { [ map { $_->[1]{id} } @{ $_[0]->{asked} } ] }

# Run $code, returning the warnings it raised -- the storage's pool reports
# through on_error, and its on_error warns.
sub warnings_of {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $code->();
  return \@warnings;
}

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the pool is the
#    real DBIO::Async::Pool, deciding with core's own acquire and throw
#    handling; the mocks fill DB-specific seams only.
# ---------------------------------------------------------------------------

is ref(new_storage('Vouch23', 1)->pool), 'DBIO::Async::Pool',
  'the storage builds the real DBIO::Async::Pool';
isnt refaddr(DBIO::Async::Pool->can('_idle_connection_alive')),
     refaddr(DBIO::Storage::PoolBase->can('_idle_connection_alive')),
  'DBIO::Async::Pool overrides core\'s _idle_connection_alive -- the delegation '
  . 'under test';
for my $method (qw(acquire _acquire_slot _idle_connection_usable)) {
  is refaddr(DBIO::Async::Pool->can($method)),
     refaddr(DBIO::Storage::PoolBase->can($method)),
    "DBIO::Async::Pool does NOT override $method -- core's pool decides";
}
is refaddr(Plain23->can('_idle_connection_alive')),
   refaddr(DBIO::Async::Storage->can('_idle_connection_alive')),
  'Plain23 keeps the storage default -- the "driver does not check" case';

# ---------------------------------------------------------------------------
# 1. The driver says an idle connection is dead: it is retired through the
#    storage, never handed out, and the live idle one behind it is.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Vouch23', 2);
  my $pool    = $storage->pool;
  my ($conn_a) = fill_idle($pool, 2);
  $conn_a->{alive} = 0;

  my $got = $pool->acquire;
  ok $got->is_done, 'dead idle A: acquire resolves';
  is $got->get->{id}, 2, 'dead idle A: ... to B, the live idle connection';
  is_deeply $storage->{shutdown}, [1],
    'dead idle A: A was shut down through the storage, once';
  is_deeply asked_ids($storage), [1, 2],
    'dead idle A: the storage was asked about A, then about B';
  is $storage->{_next_id}, 2,
    'dead idle A: nothing was spawned -- a live idle connection was there';
  is $pool->size, 1, 'dead idle A: A no longer counts against the pool size';

  $pool->release($got->get);
  is $pool->acquire->get->{id}, 2,
    'dead idle A: the next borrow gets B again -- A is gone from the pool, '
    . 'never handed out';
}

# ---------------------------------------------------------------------------
# 2. The only idle connection is dead: the caller gets a freshly spawned one,
#    not a failed query first.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Vouch23', 1);
  my $pool    = $storage->pool;
  my ($conn) = fill_idle($pool, 1);
  $conn->{alive} = 0;

  my $got = $pool->acquire;
  ok $got->is_done, 'only idle dead: acquire resolves';
  is $got->get->{id}, 2, 'only idle dead: ... on a freshly spawned connection';
  is $storage->{_next_id}, 2, 'only idle dead: exactly one connection was spawned';
  is_deeply $storage->{shutdown}, [1],
    'only idle dead: the dead one was shut down, once';
}

# ---------------------------------------------------------------------------
# 3. A driver that does not fill the seam: the storage default vouches for
#    every idle connection without looking -- the behaviour from before k28.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Plain23', 1);
  my $pool    = $storage->pool;
  my ($conn) = fill_idle($pool, 1);
  $conn->{alive} = 0;   # nobody looks at it by default

  ok $storage->_idle_connection_alive($conn),
    'default: the storage seam answers true, dead or not';
  ok $pool->_idle_connection_alive($conn),
    'default: ... and so does the pool, which asks it';
  is $pool->acquire->get->{id}, 1,
    'default: the idle connection is handed out, unchecked';
  is_deeply $storage->{shutdown}, [], 'default: nothing is retired';
  is $storage->{_next_id}, 1, 'default: nothing is spawned';
}

# ---------------------------------------------------------------------------
# 4. A check that throws. The pool does not catch it -- core does, counts it as
#    not vouching, reports it to the pool's on_error, and retires the
#    connection. A throw swallowed in the pool would have to answer SOMETHING:
#    true hands out a connection nothing vouched for, false hides a broken
#    check that turns every borrow into a spawn.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Vouch23', 2);
  my $pool    = $storage->pool;
  my ($conn_a) = fill_idle($pool, 2);
  $conn_a->{probe_dies} = 1;

  eval { $pool->_idle_connection_alive($conn_a) };
  is $@, "probe broke\n",
    'throwing check: the pool passes the storage\'s throw through, untouched';
  $storage->{asked} = [];

  my $got;
  my $warnings = warnings_of(sub { $got = $pool->acquire });

  ok $got->is_done, 'throwing check: acquire still resolves';
  is $got->get->{id}, 2, 'throwing check: ... to the next idle connection';
  is_deeply $storage->{shutdown}, [1],
    'throwing check: the connection it could not vouch for was retired';
  is scalar @$warnings, 1,
    'throwing check: the pool\'s on_error was called once';
  like $warnings->[0] // '',
    qr/DBIO::Async pool error: Idle connection liveness check failed: probe broke/,
    'throwing check: ... with core\'s report and the check\'s own error';
}

{
  my $storage = new_storage('Vouch23', 1);
  my $pool    = $storage->pool;
  my ($conn) = fill_idle($pool, 1);
  $conn->{probe_dies} = 1;

  my $got;
  my $warnings = warnings_of(sub { $got = $pool->acquire });

  is $got->get->{id}, 2,
    'throwing check, only idle: the caller gets a fresh connection';
  is_deeply $storage->{shutdown}, [1],
    'throwing check, only idle: the one it could not vouch for was retired';
  is scalar @$warnings, 1, 'throwing check, only idle: on_error was called once';
}

# ---------------------------------------------------------------------------
# 5. What the seam is handed, and when it is asked. The owning storage is the
#    invocant, the connection about to be handed out the argument. It is asked
#    about idle connections only: a freshly spawned one has just come up, and
#    one released straight to a queued caller was in use a moment ago -- a
#    check on either would only add cost to the paths that need none.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Vouch23', 1);
  my $pool    = $storage->pool;

  my $first = $pool->acquire->get;
  is_deeply $storage->{asked}, [],
    'only idle: not asked about a freshly spawned connection';

  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'only idle: the second caller queues -- the pool is full';
  $pool->release($first);
  ok $waiter->is_done, 'only idle: the queued caller gets the released connection';
  is_deeply $storage->{asked}, [],
    'only idle: not asked about a connection handed straight to a queued caller';

  $pool->release($waiter->get);
  my $again = $pool->acquire->get;
  is scalar @{ $storage->{asked} }, 1,
    'only idle: asked once, when an idle connection is borrowed';
  my ($self, $conn) = @{ $storage->{asked}[0] };
  is refaddr($self), refaddr($storage),
    'args: asked on the storage that owns the pool';
  is refaddr($conn), refaddr($first),
    'args: ... about the very connection that sat idle';
  is refaddr($again), refaddr($first),
    'args: ... which is the one handed out, since it vouched for it';
}

# ---------------------------------------------------------------------------
# 6. The storage reference is gone (the pool holds it weakly; DESTROY paths).
#    The pool answers true without asking, like _await_conn_ready's
#    short-circuit. A call on the lost reference would die instead, and core
#    would take that for a failed check: every idle connection retired, and a
#    spawn that cannot happen without a storage.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Vouch23', 1);
  # Built directly, not through $storage->pool: the storage's DESTROY shuts
  # down the pool it owns, and this pool must outlive its storage.
  my $pool = DBIO::Async::Pool->new(
    storage  => $storage,
    conninfo => { host => 'localhost' },
    size     => 1,
  );
  my ($conn) = fill_idle($pool, 1);
  $conn->{alive} = 0;   # would be retired, were anyone asking

  undef $storage;
  ok !defined $pool->{storage},
    'storage lost: precondition -- the pool\'s weak reference is gone';

  my ($alive, $got);
  my $warnings = warnings_of(sub {
    $alive = eval { $pool->_idle_connection_alive($conn) };
    $got   = $pool->acquire;
  });

  is $@, '', 'storage lost: asking the pool does not die';
  ok $alive, 'storage lost: ... it answers true, without asking anyone';
  ok $got->is_done, 'storage lost: acquire resolves';
  is $got->is_done ? $got->get->{id} : undef, 1,
    'storage lost: ... to the idle connection -- nothing retired, no spawn';
  is_deeply $warnings, [], 'storage lost: no pool error';
}

done_testing;
