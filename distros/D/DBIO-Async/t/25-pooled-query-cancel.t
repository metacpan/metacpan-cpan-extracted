use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k29: a pooled query cancelled while its result is
# still on the wire must not hand that connection to the next borrower.
#
# WHY IT MATTERS. _query_async hands its connection back from an on_ready
# callback on the query Future, and on_ready fires on a cancel too. A cancel
# drops the Future::IO poll, but the statement is on the server and its result
# is on its way, unread: the connection is busy, not dead. Idled as it was, the
# next acquire got it and its query was refused -- DBD::Pg: "another command is
# already in progress" -- and so was the query of a caller already queued for
# the slot. The base can read that result only through the driver, and cannot
# cancel it on the server, so it retires the connection: reported dead to the
# pool (core PoolBase::_mark_connection_dead) BEFORE the hand-back, the order
# karr k26 established, so the release retires it and a queued caller gets a
# fresh one. The pinned path decided the same for a cancelled statement in
# karr k33 (t/24 section 5).
#
# The cancel a caller makes is on the Future it was given, which is rarely the
# query Future itself: core's CRUD runner chains a ->then onto it, and
# _query_async's own Future is the ->then of the pool's acquire. A Future's
# cancel propagates down such a chain to the Future running at the time --
# section 2 and 4 cancel the outermost one.
#
# WHAT IS REAL. The whole transport -- _query_async, _await_query_result, the
# Future::IO watcher seam on a real pipe, the release -- the real
# DBIO::Async::Pool with core's release, _mark_connection_dead and retirement,
# and core's update_async. Section 0 pins that the mock owns the DB-specific
# seams and nothing else, and the pool nothing but a recording release.
#
# THE MOCK SERVER keeps ONE statement slot per connection, as a DBD does, and
# refuses a second statement while the slot is taken, with DBD::Pg's words. The
# slot is freed only by reading the result (_collect_result), so a cancelled
# statement leaves it taken.

# --- RecPool25: the real pool, with every release recorded ------------------

{
  package RecPool25;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- Cancel25: the DB-specific seams over a pipe -----------------------------

{
  package Cancel25;
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
    return $self->{pool} ||= RecPool25->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = main::label($sql);
    push @{ $self->{wire} }, [ $label, $conn->{id} ];
    die "another command is already in progress ($conn->{in_flight})\n"
      if defined $conn->{in_flight};
    $conn->{in_flight} = $label;
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    return Future->done([ 'row-for', $label, $conn->{id} ]);
  }

  # A cancel is no failure, so this is never asked; recorded to show that.
  sub _conn_error_is_fatal {
    my ($self, $conn) = @_;
    push @{ $self->{asked} }, $conn->{id};
    return 0;
  }
}

sub new_storage {
  my $storage = Cancel25->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire shutdown asked pool_errors);
  # pool_size 1: what the next acquire gets tells a retired connection from
  # one put back.
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# The table a statement names, or the statement itself: what the wire log
# records.
sub label { my ($sql) = @_; return $sql =~ /\b(?:FROM|UPDATE) (\w+)/ ? $1 : $sql }

# Drive the Future::IO loop by hand until $f settles. A query that waited for
# the pool hangs off a pool waiter, a plain Future that cannot ->get while
# pending; 50 turns is far more than any settle here needs, and a Future still
# pending after them is the finding.
sub drive {
  my $f = shift;
  for (1 .. 50) { last if $f->is_ready; Future::IO->sleep(0)->get }
  return $f;
}

sub outcome {
  my $f = shift;
  return 'still pending' unless $f->is_ready;
  return 'cancelled'     if $f->is_cancelled;
  return 'failed: ' . $f->failure if $f->is_failed;
  return [ $f->get ];
}

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion its meaning: the mock
#    overrides none of the transport's query path, and the pool nothing but
#    the recording release.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _await_query_result _await_readable
                   _release_on_ready _mark_dead_on_fail _abandon_on_cancel)) {
  is refaddr(Cancel25->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
for my $method (qw(_mark_connection_dead _retire_in_use_connection acquire)) {
  is refaddr(RecPool25->can($method)), refaddr(DBIO::Storage::PoolBase->can($method)),
    "RecPool25 does NOT override $method -- core's pool decides";
}

# ---------------------------------------------------------------------------
# 1. The k29 case: a pooled query cancelled in flight. The connection is
#    handed back once, as ever, and that hand-back retires it; the next query
#    runs on a fresh connection instead of being refused on the busy one.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ],
    'in flight: the statement is on the wire -- the pool had a connection';
  ok !$fa->is_ready, 'in flight: ... and its result has not been read';

  $fa->cancel;
  ok $fa->is_cancelled, 'in flight: the query is cancelled';
  is_deeply $pool->{release_log}, [1],
    'in flight: the connection was handed back once';
  is_deeply $storage->{shutdown}, [1],
    'in flight: ... and that hand-back retired it: its result is still unread';
  is $pool->size, 0, 'in flight: ... and it no longer counts against the pool';

  my $fb = drive($storage->_query_async('SELECT * FROM b', []));
  is_deeply outcome($fb), [ [ 'row-for', 'b', 2 ] ],
    'in flight: the next query succeeds, on a freshly spawned connection';
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 2 ] ],
    'in flight: nothing but the cancelled statement ever ran on connection 1';
  is_deeply $storage->{asked}, [],
    'in flight: _conn_error_is_fatal was not asked -- a cancel is no failure';
  is_deeply $storage->{pool_errors}, [], 'in flight: no pool error';
}

# ---------------------------------------------------------------------------
# 2. The same through the public path: the caller cancels the Future core's
#    update_async gave it, a ->then on top of _query_async's own. The cancel
#    propagates down to the query in flight.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->update_async('artist', { name => 'x' }, { id => 1 });
  is_deeply $storage->{wire}, [ [ 'artist', 1 ] ],
    'public path: the UPDATE is on the wire';
  $f->cancel;

  is_deeply $storage->{shutdown}, [1],
    'public path: cancelling update_async\'s Future retired the connection';
  my $g = drive($storage->_query_async('SELECT * FROM b', []));
  is_deeply outcome($g), [ [ 'row-for', 'b', 2 ] ],
    'public path: ... and the next query runs on a fresh one';
}

# ---------------------------------------------------------------------------
# 3. The ordering: a caller is already QUEUED for the slot when the query in
#    flight is cancelled. Reported dead before the hand-back, the release
#    retires the connection and spawns a fresh one for the waiter. Handed back
#    first, the busy connection would go straight to the waiter, whose query
#    would be refused.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  ok !$fb->is_ready, 'queued: b waits -- the pool of one is checked out';

  $fa->cancel;
  drive($fb);

  is_deeply outcome($fb), [ [ 'row-for', 'b', 2 ] ],
    'queued: b succeeds, on a connection spawned for its slot -- it was not '
    . 'handed the one with a\'s result still on it';
  is_deeply $storage->{shutdown}, [1], 'queued: connection 1 was retired, once';
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 2 ] ],
    'queued: nothing but the cancelled statement ever ran on connection 1';
}

# ---------------------------------------------------------------------------
# 4. A query that waited for the pool, was dispatched once it got a
#    connection, and is then cancelled -- through the Future the caller got
#    while it was still waiting. That Future is the ->then of the acquire; its
#    cancel must reach the query it went on to run.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  drive($fa);
  is_deeply outcome($fa), [ [ 'row-for', 'a', 1 ] ], 'waited: a completes';
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    'waited: b got connection 1 from a\'s release and is on the wire';

  $fb->cancel;
  is_deeply $storage->{shutdown}, [1],
    'waited: cancelling b retired connection 1 under it';
  my $fc = drive($storage->_query_async('SELECT * FROM c', []));
  is_deeply outcome($fc), [ [ 'row-for', 'c', 2 ] ],
    'waited: the next query runs on a fresh connection';
}

# ---------------------------------------------------------------------------
# 5. A cancel after the query settled changes nothing: the connection was
#    idled clean and stays in use.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = drive($storage->_query_async('SELECT * FROM a', []));
  $fa->cancel;
  is_deeply $storage->{shutdown}, [],
    'settled: a late cancel retires nothing';
  my $fb = drive($storage->_query_async('SELECT * FROM b', []));
  is_deeply outcome($fb), [ [ 'row-for', 'b', 1 ] ],
    'settled: the next query reuses connection 1';
}

# ---------------------------------------------------------------------------
# 6. A caller cancelled while it still WAITS for the pool never dispatched
#    anything, so no connection is retired for it. Its slot must not be lost
#    either. That half is core's: handed to the first waiter as it stood, the
#    connection went to a cancelled Future, which ignores ->done, and ended up
#    neither idle nor held. PoolBase::release skips a waiter that was given up
#    on (core k255).
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  $fb->cancel;
  drive($fa);

  is_deeply outcome($fa), [ [ 'row-for', 'a', 1 ] ], 'waiting: a completes';
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ],
    'waiting: the cancelled b never reached the wire';
  is_deeply $storage->{shutdown}, [],
    'waiting: nothing is retired -- b dispatched nothing';

  my $fc = drive($storage->_query_async('SELECT * FROM c', []));
  is_deeply outcome($fc), [ [ 'row-for', 'c', 1 ] ],
    'waiting: the next query gets connection 1';
}

done_testing;
