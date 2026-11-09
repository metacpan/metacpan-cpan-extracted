use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Storage::Async;
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k35 (core karr k252): a driver's _await_query_result
# that returns NO FUTURE -- undef, a plain value -- without dying.
#
# WHY IT MATTERS. Both dispatch sites, _query_async (pooled) and
# _dispatch_pinned (pinned), guarded the seam with
#
#   eval { $self->_await_query_result(...) } // $self->future_class->fail($@)
#
# which covers a die (karr k25, t/21) and nothing else. A seam that returns
# undef leaves $@ empty, and Future.pm refuses a false exception: ->fail('')
# croaks. A seam that returns a plain value gets ->on_fail called on it. Either
# way the die comes from the transport's own line, AFTER the connection was
# taken and BEFORE anything hangs off a query Future:
#
#  * pooled: the release was never attached. The connection stays checked out,
#    and the caller is told about ->fail's argument, not about its driver;
#  * pinned: the die escapes _query_async_pinned into the caller -- or, for a
#    statement that was waiting, into whatever completed the statement before
#    it -- with the queue marked busy. Nothing behind it is ever sent.
#
# Core's _seam_future turns "no Future" into a failed Future naming the backend
# class and the seam, so it takes the path every other failure takes.
#
# WHAT IS REAL. The whole transport -- _query_async, _query_async_pinned and
# its queue, _release_on_ready, _mark_dead_on_fail, the Future::IO watcher seam
# on a real pipe -- the real DBIO::Async::Pool, and core's _seam_future. The
# mock owns the DB-specific seams and an _await_query_result that answers a
# statement naming NOTHING with undef and one naming PLAIN with 1; section 0
# pins that it owns nothing else.

# --- RecPool28: the real pool, with every release recorded ------------------

{
  package RecPool28;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- NoFuture28: the DB-specific seams over a pipe ---------------------------

{
  package NoFuture28;
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
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= RecPool28->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  # The seam under test: a driver's own dispatch that hands back no Future and
  # does not die either.
  sub _await_query_result {
    my ($self, $conn, $sql, $bind) = @_;
    return undef if $sql =~ /\bNOTHING\b/;
    return 1     if $sql =~ /\bPLAIN\b/;
    return $self->SUPER::_await_query_result($conn, $sql, $bind);
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = main::label($sql);
    push @{ $self->{wire} }, $label;
    $conn->{in_flight} = $label;
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row-for', delete $conn->{in_flight} ]);
  }
}

sub new_storage {
  my $storage = NoFuture28->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown pool_errors);
  # pool_size 1: a connection that did not come back turns the next acquire
  # into a waiter nothing will ever wake.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# The table a statement names: what the wire log records.
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# Drive the Future::IO loop by hand until $f settles. A statement stuck behind
# a wedged pool or queue hangs off a plain Future that cannot ->get while
# pending; 50 turns is far more than any settle here needs, and a Future still
# pending after them is the finding.
sub drive {
  my $f = shift;
  for (1 .. 50) { last if $f->is_ready; Future::IO->sleep(0)->get }
  return $f;
}

sub outcome {
  my $f = shift;
  return 'no Future -- the call died: ' . ($@ // '') unless ref $f;
  return 'still pending' unless $f->is_ready;
  return 'failed: ' . $f->failure if $f->is_failed;
  return [ $f->get ];
}

# What core's _seam_future says for the two answers: the backend class and the
# seam, so the driver author is pointed at the method that owes the Future.
my %NO_FUTURE = (
  NOTHING => qr/NoFuture28->_await_query_result returned undef/,
  PLAIN   => qr/NoFuture28->_await_query_result returned no Future/,
);

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the mock owns the
#    dispatch seam and nothing of the path around it, and the helper that
#    turns "no Future" into a failure is core's.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _query_async_pinned _dispatch_pinned
                   _release_on_ready _mark_dead_on_fail)) {
  is refaddr(NoFuture28->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
isnt refaddr(NoFuture28->can('_await_query_result')),
  refaddr(DBIO::Async::Storage->can('_await_query_result')),
  'the mock DOES override _await_query_result -- the premise';
is refaddr(NoFuture28->can('_seam_future')),
  refaddr(DBIO::Storage::Async->can('_seam_future')),
  '_seam_future is core\'s';

# ---------------------------------------------------------------------------
# 1. Pooled. The query fails naming the seam, its connection goes back exactly
#    once and is not retired, and the pool of one serves the next query.
# ---------------------------------------------------------------------------

for my $answer (sort keys %NO_FUTURE) {
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = eval { $storage->_query_async("SELECT * FROM $answer", []) };

  ok ref $f && $f->is_ready && $f->is_failed,
    "pooled $answer: the query Future is failed at once";
  like outcome($f), $NO_FUTURE{$answer},
    "pooled $answer: ... with an error naming the backend class and the seam";
  is_deeply $storage->{wire}, [],
    "pooled $answer: ... and nothing reached the wire";

  is_deeply $pool->{release_log} // [], [1],
    "pooled $answer: the connection went back to the pool exactly once";
  is $pool->available, 1,
    "pooled $answer: ... and sits on the idle list -- it was not retired";

  my $g = drive($storage->_query_async('SELECT * FROM b', []));
  is_deeply outcome($g), [ [ 'row-for', 'b' ] ],
    "pooled $answer: the next query runs -- the pool of one is not wedged";
  is $pool->size, 1,
    "pooled $answer: ... on the same connection, the only one ever spawned";
  is_deeply [ $storage->{shutdown}, $storage->{pool_errors} ], [ [], [] ],
    "pooled $answer: nothing was shut down and no pool error was raised";
}

# ---------------------------------------------------------------------------
# 2. Pinned, the statement goes out at once on an idle connection. It fails
#    naming the seam, and the connection is idle again: it carries no queue,
#    and the next statement on it goes out at once.
# ---------------------------------------------------------------------------

for my $answer (sort keys %NO_FUTURE) {
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  my $f = eval { $storage->_query_async_pinned($conn, "SELECT * FROM $answer", []) };

  ok ref $f && $f->is_ready && $f->is_failed,
    "pinned $answer: the statement's Future is failed at once -- the call "
    . 'did not die into the caller';
  like outcome($f), $NO_FUTURE{$answer},
    "pinned $answer: ... with an error naming the backend class and the seam";
  ok !exists $conn->{_dbio_async_queue},
    "pinned $answer: the connection is idle again -- it carries no queue";

  my $g = $storage->_query_async_pinned($conn, 'SELECT * FROM b', []);
  is_deeply $storage->{wire}, ['b'],
    "pinned $answer: the next statement goes out at once";
  is_deeply outcome(drive($g)), [ [ 'row-for', 'b' ] ],
    "pinned $answer: ... and resolves with what the connection answered";

  is_deeply $pool->{release_log} // [], [],
    "pinned $answer: the pinned connection was not released -- that is its holder's";
  $pool->release($conn);
  is $pool->available, 1,
    "pinned $answer: ... and its hand-back idles it -- it was not reported dead";
}

# ---------------------------------------------------------------------------
# 3. Pinned, the statement was WAITING: three issued without awaiting, the
#    middle one's dispatch returns no Future. It is dispatched from the
#    settling of the statement before it, so that is where a die would land.
#    Asserts that each caller gets its own outcome and that the queue runs on
#    to the statement behind.
# ---------------------------------------------------------------------------

for my $answer (sort keys %NO_FUTURE) {
  my $storage = new_storage();
  my $conn    = $storage->pool->acquire->get;

  my $fa = $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);
  my $fm = $storage->_query_async_pinned($conn, "SELECT * FROM $answer", []);
  my $fc = $storage->_query_async_pinned($conn, 'SELECT * FROM c', []);
  is_deeply $storage->{wire}, ['a'],
    "queued $answer: only the first statement is on the wire";

  my $died = eval { drive($fc); 1 } ? undef : $@;
  is $died, undef,
    "queued $answer: nothing died into the loop that settled the first statement";

  is_deeply outcome($fa), [ [ 'row-for', 'a' ] ],
    "queued $answer: the statement before it resolves with its own rows";
  like outcome($fm), $NO_FUTURE{$answer},
    "queued $answer: the statement itself fails, naming the backend class and the seam";
  is_deeply outcome($fc), [ [ 'row-for', 'c' ] ],
    "queued $answer: the statement behind it is dispatched and resolves";
  is_deeply $storage->{wire}, [ 'a', 'c' ],
    "queued $answer: ... in order, and the failed one never reached the wire";
  ok !exists $conn->{_dbio_async_queue},
    "queued $answer: the connection is idle at the end -- it carries no queue";
}

done_testing;
