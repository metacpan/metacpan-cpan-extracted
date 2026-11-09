use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k231. DBIO::Storage::PoolBase::_retire_in_use_connection is the release
# counterpart for a checked-out connection that must never be handed out again
# (a pipeline whose exit died leaves it in pipeline mode). It retires the
# connection through _retire_connection and hands the freed slot to the oldest
# queued waiter, because _retire_connection alone leaves the waiter queue alone:
# a waiter queued for the retired connection would then wait for a release that
# never comes -- in a pool of one, for good.

{
  package K231::PoolConn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K231::RetirePool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self) = @_;
    my $id = ++$self->{_next_id};
    die "spawn $id refused\n" if $self->{refuse_from} && $id >= $self->{refuse_from};
    die "spawn $id refused\n" if $self->{refuse_only} && $id == $self->{refuse_only};
    return K231::PoolConn->new($id);
  }

  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }
}

sub new_pool {
  my (%args) = @_;
  my $pool = K231::RetirePool->new(
    conninfo     => 'fake',
    size         => 1,
    future_class => 'DBIO::Test::Future',
  );
  $pool->{$_} = $args{$_} for keys %args;
  return $pool;
}

# ---------------------------------------------------------------------------
# No waiter queued. Asserts: the connection is closed once and dropped from the
# pool, nothing is spawned in its place, and the next acquire spawns a fresh
# connection on demand -- never the retired one.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  $pool->_retire_in_use_connection($conn);

  is_deeply $pool->{closed}, [ 1 ], 'no waiter: the connection is closed once';
  is $pool->size, 0, 'no waiter: the pool no longer counts it, and spawned nothing';
  is $pool->available, 0, 'no waiter: it is not idle either';

  my $next = $pool->acquire;
  ok $next->is_ready, 'no waiter: the next acquire resolves';
  is $next->is_ready && $next->get->{id}, 2,
    'no waiter: on a freshly spawned connection';
}

# ---------------------------------------------------------------------------
# A waiter queued for the pool's one connection. Asserts: the waiter resolves
# at once on a freshly spawned connection, not on the retired one, and the pool
# counts exactly that one.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'queued waiter: pending while the connection is out';

  $pool->_retire_in_use_connection($conn);

  is_deeply $pool->{closed}, [ 1 ], 'queued waiter: the retired connection is closed once';
  ok $waiter->is_ready, 'queued waiter: the waiter resolves';
  is $waiter->is_ready && $waiter->get->{id}, 2,
    'queued waiter: on a freshly spawned connection';
  is $pool->size, 1, 'queued waiter: the pool counts the fresh connection only';
}

# ---------------------------------------------------------------------------
# The replacement spawn is refused. Asserts: the waiter fails with the spawn's
# own error instead of waiting for a release that will never come, and the
# refused spawn takes no slot.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(refuse_from => 2);
  my $conn = $pool->acquire->get;
  my $waiter = $pool->acquire;

  $pool->_retire_in_use_connection($conn);

  ok $waiter->is_failed, 'refused spawn: the waiter fails instead of hanging';
  eval { $waiter->get };
  like "$@", qr/spawn 2 refused/, 'refused spawn: with the spawn\'s own error';
  is $pool->size, 0, 'refused spawn: no slot is taken';
}

# ---------------------------------------------------------------------------
# The replacement spawn is refused with a second waiter queued behind the
# first (karr k260). The refused spawn takes no slot, so the slot is still
# free and nobody is left to release into it. Asserts: the first waiter fails
# with its spawn's error and the second gets the next attempt -- a connection
# when that spawn succeeds, its error when it is refused too. Before, the
# second waiter stayed queued in an empty pool, for good.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool(refuse_only => 2);
  my $conn = $pool->acquire->get;
  my ($first, $second) = map { $pool->acquire } 1 .. 2;

  $pool->_retire_in_use_connection($conn);

  eval { $first->get };
  like "$@", qr/spawn 2 refused/, 'refused spawn, two waiters: the first fails with its spawn\'s error';
  ok $second->is_ready, 'refused spawn, two waiters: the second is not left waiting';
  is $second->is_ready && !$second->is_failed && $second->get->{id}, 3,
    'refused spawn, two waiters: it gets the next spawn';
  is $pool->size, 1, 'refused spawn, two waiters: the pool counts that connection only';
  is scalar @{ $pool->{_waiters} }, 0, 'refused spawn, two waiters: the queue is empty';
}

{
  my $pool = new_pool(refuse_from => 2);
  my $conn = $pool->acquire->get;
  my ($first, $second) = map { $pool->acquire } 1 .. 2;

  $pool->_retire_in_use_connection($conn);

  eval { $first->get };
  like "$@", qr/spawn 2 refused/, 'every spawn refused: the first waiter fails with its spawn\'s error';
  ok $second->is_failed, 'every spawn refused: the second fails too instead of hanging';
  eval { $second->get };
  like "$@", qr/spawn 3 refused/, 'every spawn refused: with the error of the spawn made for it';
  is $pool->size, 0, 'every spawn refused: no slot is taken';
  is scalar @{ $pool->{_waiters} }, 0, 'every spawn refused: the queue is empty';
}

# ---------------------------------------------------------------------------
# After shutdown. Asserts: like a late release it is a no-op -- the connection
# shutdown already closed is not closed a second time, and nothing is spawned.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  $pool->shutdown;
  is_deeply $pool->{closed}, [ 1 ], 'after shutdown: shutdown closed the connection';

  $pool->_retire_in_use_connection($conn);
  is_deeply $pool->{closed}, [ 1 ], 'after shutdown: it is not closed again';
  is $pool->size, 0, 'after shutdown: nothing is spawned';
}

done_testing;
