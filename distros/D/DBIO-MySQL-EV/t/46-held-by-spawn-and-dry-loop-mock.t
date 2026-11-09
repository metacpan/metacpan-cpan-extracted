use strict;
use warnings;
use Test::More;
use Socket ();

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

use DBIO::MySQL::EV::Future;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;

alarm 60;

# OFFLINE. Two claims about the blocking wait that is queued for a pooled
# connection (DBIO::MySQL::EV::Future::await, karr k53):
#
# 1. karr k90 (item 2): a spawn in flight is not "held by callbacks". Core
#    counts a spawn against the pool's size from before the first code it calls
#    that is not the pool's (core k277), so a caller can be queued while the
#    pool holds fewer connections than its size; the connection the spawn makes
#    may serve that caller. _mysql_held_by_callbacks must not call such a pool
#    hopeless, or a wait that could end is refused.
#
# 2. karr k69: a wait that dies -- the loop has run dry with nothing left to
#    settle the Future -- takes the
#    caller it was queued as out of the pool's queue. Left there, the next
#    release hands the connection to a caller nobody waits for, and the pool
#    loses it ("lost a sequence Future").

{
  package FakeConn;
  sub new {
    my ($class) = @_;
    socketpair(my $a, my $b, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    return bless { a => $a, b => $b }, $class;
  }
  sub is_connected  { 1 }
  sub socket        { fileno $_[0]{a} }
  sub pending_count { 0 }
}

{
  package FakePool;
  use base 'DBIO::MySQL::EV::Pool';
  sub _create_connection { FakeConn->new }
}

sub pool_of {
  my ($size) = @_;
  return FakePool->new(
    conninfo     => { host => 'fake' },
    size         => $size,
    future_class => 'DBIO::MySQL::EV::Future',
  );
}

my @WARN;
local $SIG{__WARN__} = sub { push @WARN, $_[0] };

# --- 1. a spawn in flight ------------------------------------------------------

{
  no warnings 'redefine';
  local *DBIO::MySQL::EV::QueryExecutor::_waits_for_callback = sub { 1 };

  my $pool = pool_of(1);
  my $conn = $pool->acquire->get;
  ok !$pool->available, 'pool of one: its only connection is checked out';
  ok $pool->_mysql_held_by_callbacks,
    'control: every connection held by a running callback, no spawn -> held';

  $pool->{_spawning}{1} = 1;
  ok !$pool->_mysql_held_by_callbacks,
    'a spawn in flight can still serve the queued caller -> not held (karr k90)';

  my $waiter = $pool->acquire;
  my $chain  = $waiter->then(sub { $_[0] });
  ok !$chain->_refuse_queued,
    '... and the wait for a caller queued behind it is not refused';
  ok !$waiter->is_ready, '... the caller stays queued';

  delete $pool->{_spawning}{1};
  ok $chain->_refuse_queued, 'once the spawn is over, the same wait is refused';
  ok $waiter->is_failed, '... failing the queued caller';
  $pool->release($conn);
}

# --- 2. a wait that dies leaves nothing queued ---------------------------------

{
  my $pool   = pool_of(1);
  my $conn   = $pool->acquire->get;
  my $waiter = $pool->acquire;
  my $chain  = $waiter->then(sub { $_[0] });
  is scalar @{ $pool->{_waiters} }, 1, 'a caller is queued behind the only connection';

  my $ok = eval { $chain->await; 1 };
  ok !$ok, 'the wait dies: nothing in the loop could complete it';
  like $@, qr/nothing left that could complete it/, '... with the loop-dry message';
  is scalar @{ $pool->{_waiters} }, 0, '... and the caller is out of the pool\'s queue (karr k69)';
  ok $waiter->is_failed, '... failed, not left pending';

  $pool->release($conn);
  is $pool->available, 1, 'a later release keeps the connection: idle, not handed to a dead caller';
  my $again = $pool->acquire;
  ok $again->is_ready && !$again->is_failed, '... and the next acquire gets it';
  $pool->release($again->get);
  is_deeply [ grep { /lost a sequence Future/ } @WARN ], [], 'no sequence Future was lost';
}

done_testing;
