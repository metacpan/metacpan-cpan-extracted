use strict;
use warnings;
use Test::More;

use Future;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k50 (core karr k275): the pool's release is given the
# lease of the borrow it ends, so a release that arrives after its connection
# went on is a silent no-op and cannot give one session to two callers.
#
# WHY IT MATTERS. A pooled statement's connection goes back to the pool when
# its Future settles -- possibly long after somebody else already handed that
# connection on (a holder releasing it ahead of the statement's completion, a
# retirement, a second release). A release that carries no lease is taken as
# the current holder's: it would pass the connection to the next waiter, or put
# it on the idle list, while another caller still holds it -- one session, two
# callers, each seeing the other's statements and transaction state.
#
# WHAT IS REAL. The whole transport -- _query_async, the lease taken right
# after the acquire, _release_on_ready, the Future::IO watcher seam on a real
# pipe -- and the real DBIO::Async::Pool, size 1, with its idle list and waiter
# queue. The pool only records its releases. The mock owns the DB-specific
# seams and nothing else.
#
# WHAT IS ASSERTED. Not that a lease is passed for its own sake but what it is
# for: a statement that completes after its connection went on gives back
# nothing the new holder has. The three situations of core k275:
#
#  (a) the connection was handed to a waiter, and another waiter queues behind
#  (b) the connection was handed to a waiter, nobody queues behind
#  (c) the connection went idle and was borrowed again from the idle list
#
# In each: the statement's caller still gets its answer; the connection is
# not handed on, idle or given out again while its new holder has it; and the
# new holder's own release then passes it on exactly once. Beside them, the
# plain case: the release the transport makes carries the lease of its borrow.

{
  package RecPool37;
  use Scalar::Util qw(refaddr);
  use base 'DBIO::Async::Pool';

  # Every release, with the lease it was given next to the connection's
  # current one at that moment.
  sub release {
    my ($self, $conn, @rest) = @_;
    push @{ $self->{release_log} }, {
      args    => scalar(@rest),
      lease   => $rest[0],
      current => $self->{_leases}{ refaddr($conn) },
    };
    return $self->SUPER::release($conn, @rest);
  }
}

{
  package LeaseStorage37;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= RecPool37->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { die "pool error: $_[0]" },
    );
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, { sql => $sql, conn => $conn };
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row-for', $self->{wire}[-1]{sql} ]);
  }
}

sub new_storage {
  my $storage = LeaseStorage37->new(undef);
  $storage->{_next_id} = 0;
  $storage->{wire}     = [];
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# Run the loop until the Future settles, without dying on a failure.
sub settle { my $f = shift; eval { $f->get }; return $f }

# A statement on its way, on the pool's only connection: dispatched, its
# answer still on the pipe -- not collected until the loop runs.
sub statement_in_flight {
  my ($storage) = @_;
  my $f = $storage->_query_async('SELECT 1', []);
  ok !$f->is_ready, 'the statement is in flight, its answer not yet collected';
  return ($f, $storage->{wire}[0]{conn});
}

# ---------------------------------------------------------------------------
# 0. The transport releases with the lease of the borrow it ends.
# ---------------------------------------------------------------------------
{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = settle($storage->_query_async('SELECT 1', []));
  ok $f->is_done, 'plain statement: it completed';

  my $log = $pool->{release_log} || [];
  is scalar @$log, 1, '... and its connection went back once';
  is $log->[0]{args}, 1, '... with a lease handed along';
  ok defined $log->[0]{lease}, '... a defined one';
  is $log->[0]{lease}, $log->[0]{current},
    '... the one of the borrow it ended, not an older or invented one';
  is $pool->available, 1, '... and the release was taken: the connection is idle';
}

# ---------------------------------------------------------------------------
# (a) handed to a waiter, another waiter queued behind it
# ---------------------------------------------------------------------------
{
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my ($f, $conn) = statement_in_flight($storage);

  my $w1 = $pool->acquire;
  my $w2 = $pool->acquire;
  ok !$w1->is_ready && !$w2->is_ready, '(a) both waiters queue: the pool of one is out';

  # The connection leaves the statement's borrow some other way than the
  # statement's own completion.
  $pool->release($conn);
  ok $w1->is_done && !$w2->is_ready, '(a) ... it went to the first waiter';
  my $lease = $pool->_lease($w1->get);

  settle($f);
  ok $f->is_done, '(a) the statement completes after that and its caller gets the answer';
  is_deeply $f->get, [ 'row-for', 'SELECT 1' ], '(a) ... the one its connection gave';

  ok !$w2->is_ready,
    '(a) the statement\'s late release did not hand the connection to the second waiter';
  is $pool->available, 0, '(a) ... nor put it on the idle list while the first waiter has it';
  my $extra = $pool->acquire;
  ok !$extra->is_ready, '(a) ... a further acquire is not served either';

  $pool->release($w1->get, $lease);
  ok $w2->is_done, '(a) the first waiter\'s own release passes it on';
  is refaddr($w2->get), refaddr($conn), '(a) ... to the second waiter, the one session';
  $extra->cancel;
}

# ---------------------------------------------------------------------------
# (b) handed to a waiter, nobody queued behind it
# ---------------------------------------------------------------------------
{
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my ($f, $conn) = statement_in_flight($storage);

  my $w1 = $pool->acquire;
  $pool->release($conn);
  ok $w1->is_done, '(b) the connection went to the waiter';
  my $lease = $pool->_lease($w1->get);

  settle($f);
  ok $f->is_done, '(b) the statement completes after that and its caller gets the answer';

  is $pool->available, 0,
    '(b) the statement\'s late release did not put the connection on the idle list';
  my $again = $pool->acquire;
  ok !$again->is_ready,
    '(b) ... so a further acquire does not get the session its holder still has';

  $pool->release($w1->get, $lease);
  ok $again->is_done, '(b) the holder\'s own release passes it on';
  is refaddr($again->get), refaddr($conn), '(b) ... once';
  is $pool->available, 0, '(b) ... and it is not idle as well';
}

# ---------------------------------------------------------------------------
# (c) idle, then borrowed again from the idle list
# ---------------------------------------------------------------------------
{
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my ($f, $conn) = statement_in_flight($storage);

  $pool->release($conn);
  is $pool->available, 1, '(c) the connection went idle';
  my $w1 = $pool->acquire;
  ok $w1->is_done && refaddr($w1->get) == refaddr($conn),
    '(c) ... and was borrowed again from the idle list';
  my $lease = $pool->_lease($w1->get);

  settle($f);
  ok $f->is_done, '(c) the statement completes after that and its caller gets the answer';

  is $pool->available, 0,
    '(c) the statement\'s late release did not put the connection back on the idle list';
  my $again = $pool->acquire;
  ok !$again->is_ready,
    '(c) ... so a further acquire does not get the session its holder still has';

  $pool->release($w1->get, $lease);
  ok $again->is_done, '(c) the holder\'s own release passes it on';
  is refaddr($again->get), refaddr($conn), '(c) ... once';
}

done_testing;
