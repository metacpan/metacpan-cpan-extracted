use strict;
use warnings;
use Test::More;

use Future;
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k54: the connect option max_pending_pinned.
#
# WHY IT MATTERS. A pinned connection runs one statement at a time and queues
# the rest, SQL and bind values included (THE PINNED STATEMENT QUEUE). Nothing
# bounded that queue: a connection that hangs, or a producer faster than the
# server, grew it without end. max_pending_pinned is the bound. A statement
# issued when that many already wait fails at once, and the queue is as it was
# -- nothing appended, nothing lost, the order kept -- so the statements that
# did get in still run, in the order issued.
#
# WHAT IS REAL. The whole transport -- _query_async_pinned, the statement queue
# on the connection, the Future::IO watcher seam on a real pipe -- and the real
# DBIO::Async::Pool. The mock owns the DB-specific seams and nothing else; its
# server answers a statement when the test says so (answer_one).

{
  package Queue41;
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

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, $sql;
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row', $self->{wire}[-1] ]);
  }
}

sub new_storage {
  my (%opts) = @_;
  my $storage = Queue41->new(undef);
  $storage->{_next_id} = 0;
  $storage->{wire} = [];
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %opts }]);
  return $storage;
}

# The server answers the statement in flight on $conn.
sub answer_one { syswrite $_[0]{w}, 'R' }

sub settle { my $f = shift; eval { $f->get }; return $f }

# What is queued on the connection, in order: the SQL of every live entry.
sub waiting_sql {
  my ($conn) = @_;
  return [ map { $_->[1] } grep { @$_ } @{ $conn->{_dbio_async_queue}{waiting} } ];
}

my $SECRET_BIND = 'bind-VALUE-7731-xyzzy';

# ---------------------------------------------------------------------------
# 0. Declared by the backend class, and its value is checked.
# ---------------------------------------------------------------------------

ok scalar(grep { $_ eq 'max_pending_pinned' } Queue41->async_option_names),
  'max_pending_pinned is one of the backend\'s async_option_names';
ok scalar(grep { $_ eq 'max_pending_pinned' } Queue41->declared_async_option_names),
  '... and of its declared_async_option_names';
is new_storage(max_pending_pinned => 3)->async_option('max_pending_pinned'), 3,
  'a value given is readable with async_option';

for my $bad (0, -2, 1.5, 'SECRET-many', [ 3 ], { a => 1 }) {
  my $s  = Queue41->new(undef);
  my $ok = eval {
    $s->connect_info([{ host => 'localhost', pool_size => 1, max_pending_pinned => $bad }]);
    1;
  };
  my $label = 'a value that is ' . (ref $bad ? lc ref $bad . ' ref' : "'$bad'");
  ok !$ok, "$label is refused";
  like $@, qr/max_pending_pinned.*takes a positive integer/,
    '... naming the option and the form it takes';
  unlike $@, qr/SECRET|-2|1\.5|ARRAY|HASH/, '... and not the value';
}

# ---------------------------------------------------------------------------
# 1. Below the limit statements queue as ever; at it the new one fails at once
#    and the queue is untouched.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(max_pending_pinned => 2);
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $inflight = $storage->_query_async_pinned($conn, 'SELECT 0', []);
  my $w1 = $storage->_query_async_pinned($conn, 'SELECT 1', [ 'one' ]);
  ok !$w1->is_ready, 'below the limit: the first waiting statement is queued';
  my $w2 = $storage->_query_async_pinned($conn, 'SELECT 2', [ 'two' ]);
  ok !$w2->is_ready, '... and so is the second, which reaches the limit';
  is_deeply waiting_sql($conn), [ 'SELECT 1', 'SELECT 2' ], '... in order';

  my $entries_before = [ @{ $conn->{_dbio_async_queue}{waiting} } ];

  my $over = $storage->_query_async_pinned($conn,
    'SELECT secret_column FROM secret_table', [ $SECRET_BIND ]);
  ok $over->is_failed, 'at the limit: the statement fails at once';
  like scalar $over->failure, qr/\Anot sent: 2 statements already wait on this connection \(max_pending_pinned\)/,
    '... naming the option and the number';
  unlike scalar $over->failure, qr/secret_column|secret_table|SELECT|\Q$SECRET_BIND\E/,
    '... and neither the SQL nor the bind values';

  is scalar @{ $conn->{_dbio_async_queue}{waiting} }, 2, 'the queue still holds two entries';
  is_deeply $conn->{_dbio_async_queue}{waiting}, $entries_before,
    '... the very same ones, in the same order';
  is_deeply waiting_sql($conn), [ 'SELECT 1', 'SELECT 2' ], '... with the same statements';
  is_deeply [ map { $_->[2] } @{ $conn->{_dbio_async_queue}{waiting} } ], [ ['one'], ['two'] ],
    '... and the same binds';
  is_deeply $storage->{wire}, [ 'SELECT 0' ], 'nothing but the first statement went on the wire';

  # The statements that got in still run, in order.
  answer_one($conn);
  settle($inflight);
  ok $inflight->is_done, 'the statement in flight completed';
  answer_one($conn);
  settle($w1);
  ok $w1->is_done, '... then the first waiting one';
  answer_one($conn);
  settle($w2);
  ok $w2->is_done, '... then the second';
  is_deeply $storage->{wire}, [ 'SELECT 0', 'SELECT 1', 'SELECT 2' ],
    'they went out in the order issued';
  ok !exists $conn->{_dbio_async_queue}, 'the connection fell idle, queue gone';

  # Room again: the limit counts the waiting ones, not the ones gone by.
  my $again = $storage->_query_async_pinned($conn, 'SELECT 3', []);
  $storage->_query_async_pinned($conn, 'SELECT 4', []);
  my $fifth = $storage->_query_async_pinned($conn, 'SELECT 5', []);
  ok !$fifth->is_failed, 'after the queue drained a statement queues again';
  $_->cancel for grep { !$_->is_ready } $again, $fifth;
  $pool->release($conn);
}

# ---------------------------------------------------------------------------
# 2. A cancelled waiting statement leaves room; the limit applies to the
#    pinned path only; no option, no limit.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage(max_pending_pinned => 1);
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  $storage->_query_async_pinned($conn, 'SELECT 0', []);
  my $w = $storage->_query_async_pinned($conn, 'SELECT 1', []);
  ok $storage->_query_async_pinned($conn, 'SELECT 2', [])->is_failed,
    'limit 1: one waiting, the next fails';
  $w->cancel;
  my $room = $storage->_query_async_pinned($conn, 'SELECT 3', []);
  ok !$room->is_failed, 'the waiting statement was cancelled: its place is free';
  $room->cancel;
}

{
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;
  $storage->_query_async_pinned($conn, 'SELECT 0', []);
  my @waiting = map { $storage->_query_async_pinned($conn, "SELECT $_", []) } 1 .. 50;
  is scalar(grep { $_->is_failed } @waiting), 0, 'no option: no limit, fifty statements wait';
  $_->cancel for @waiting;
}

done_testing;
