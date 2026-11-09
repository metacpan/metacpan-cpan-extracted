use strict;
use warnings;
use Test::More;

use Future;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for core k398: the session of a pooled connection is reset
# before anyone else gets it.
#
# WHY IT MATTERS. A connection that goes back to the pool carries what its
# borrower left on the session (SET, temp tables, an open advisory lock). The
# next borrower must not inherit it, so the pool asks the owning storage's
# _reset_pool_connection when a borrow ends, and a storage that cannot reset
# retires the connection -- the next borrow gets a fresh one. DBIO::Async ships
# no reset of its own (a driver whose server can reset a session supplies it),
# so a transport without one has to give a fresh connection to every borrow
# and close the old one through the transport's _shutdown_pool_connection.
#
# WHAT IS REAL. The whole transport -- _query_async, the release, the Future::IO
# watcher seam on a real pipe -- and the real DBIO::Async::Pool, size 1, with
# core's release and retirement. The mock owns the DB-specific seams and
# nothing else; Reset39 adds the one reset seam the control section needs.

{
  package Plain39;
  use base 'DBIO::Async::Storage';
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
    push @{ $self->{shutdown} }, $conn->{id};
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

{
  package Reset39;
  use base 'Plain39';
  use lib 't/lib';
  use AsyncResetStub;
}

sub new_storage {
  my ($class) = @_;
  my $storage = $class->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown);
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# ---------------------------------------------------------------------------
# 0. The dist ships no reset: the seam is core's, which fails.
# ---------------------------------------------------------------------------

is refaddr(Plain39->can('_reset_pool_connection')),
  refaddr(DBIO::Storage::Async->can('_reset_pool_connection')),
  'no reset in DBIO::Async::Storage: the seam is core\'s, a driver supplies the reset';
isnt refaddr(Reset39->can('_reset_pool_connection')),
  refaddr(DBIO::Storage::Async->can('_reset_pool_connection')),
  'the control mock answers a reset of its own';

# ---------------------------------------------------------------------------
# 1. Without a reset the connection is retired when the borrow ends.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Plain39');
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT first', []);
  ok eval { $f->get; 1 }, 'first statement: it completed' or diag $@;

  is_deeply $storage->{shutdown}, [1],
    'first statement: its connection was closed through the transport when the borrow ended';
  is $pool->available, 0, '... and nothing idle is left in the pool';
  is $pool->size, 0, '... the slot is free again';

  my $g = $storage->_query_async('SELECT second', []);
  ok eval { $g->get; 1 }, 'second statement: it completed' or diag $@;
  is_deeply $storage->{wire}, [ [ 'SELECT first', 1 ], [ 'SELECT second', 2 ] ],
    'second statement: it ran on a fresh connection, not on the first';
  is_deeply $storage->{shutdown}, [ 1, 2 ],
    '... which was closed in turn';
}

# ---------------------------------------------------------------------------
# 2. Control: with a reset that succeeds the connection is kept and reused.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('Reset39');
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT first', [])->get;
  is $pool->available, 1, 'with a reset: the connection is idle again';
  $storage->_query_async('SELECT second', [])->get;
  is_deeply $storage->{wire}, [ [ 'SELECT first', 1 ], [ 'SELECT second', 1 ] ],
    '... and the next statement reuses it';
  is_deeply $storage->{shutdown}, [], '... nothing was closed';
}

done_testing;
