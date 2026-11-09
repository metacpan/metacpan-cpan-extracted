use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k30 on IO::Async: a blocking call that waits for a pool
# connection waits there too, driving the IO::Async loop through the
# Future::IO implementation (t/35 holds the same on the built-in one; a process
# loads one implementation, hence a file of its own). Skips without
# IO::Async / Future::IO::Impl::IOAsync.
#
# Only the waiting case is asserted. A wait that cannot end -- the holder is the
# caller itself -- hangs under a real loop instead of dying, and the
# reentrancy limit of the implementation (karr k37 / k38, t/34) is not worked
# around: nothing here blocks from the callback of a statement on the same
# connection.

BEGIN {
  eval { require IO::Async::Loop; require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync (and IO::Async) not installed';
}

use Future;
use Future::IO;
use DBIO::SQLMaker;
use DBIO::Async::Storage;
use DBIO::Async::Pool;

{
  package Wait36;
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

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    close $conn->{r};
    close $conn->{w};
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, [ $sql, $conn->{id} ];
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row', $conn->{id} ]);
  }
}

my $storage = Wait36->new(undef);
$storage->{_next_id} = 0;
$storage->{wire}     = [];
$storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
my $pool = $storage->pool;

my $held = $storage->_query_async('SELECT held', []);
is_deeply $storage->{wire}, [ [ 'SELECT held', 1 ] ],
  'io-async: the async query holds the one connection';

my $got = eval { [ $storage->_query_async('SELECT sync', [])->get ] };
is $@, '', 'io-async: the blocking call waiting for the pool does not croak';
is_deeply $got, [ [ 'row', 1 ] ],
  'io-async: ... it waited its turn and got the answer on the freed connection';
is_deeply $storage->{wire}, [ [ 'SELECT held', 1 ], [ 'SELECT sync', 1 ] ],
  'io-async: the held statement went first, the waiting one second';
ok $held->is_ready, 'io-async: the async caller\'s Future settled meanwhile';
is scalar @{ $pool->{_waiters} }, 0, 'io-async: nothing is left queued';

# core's sync wrapper
my $held2 = $storage->_query_async('SELECT held2', []);
my $ok = eval { $storage->update('artist', { name => 'x' }, { id => 1 }); 1 };
is $@, '', 'io-async: core\'s sync update waits for the held connection too';
ok $ok, '... and returns';

done_testing;
