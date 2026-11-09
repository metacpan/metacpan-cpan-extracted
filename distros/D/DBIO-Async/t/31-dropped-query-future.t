use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util qw( refaddr weaken );
use DBIO::SQLMaker;          # the mocks' sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k46: a query whose Future the caller lets go of --
# not cancels: drops -- is carried through all the same.
#
# WHY IT MATTERS. Fire-and-forget is an ordinary way to call an async API:
# create_async in void context, a notify nobody waits for, a statement in a
# transaction block that is issued and not awaited. Future.pm holds a Future
# derived with ->then only weakly, so a chain lives exactly as long as
# somebody holds its end -- and the end of this transport's chain was the
# caller's: the Future::IO poll, the collect chained onto it, the release
# hung off that. Dropped, the chain was collected with the statement on the
# wire. The poll then resolved into nothing (Future.pm: "lost a sequence
# Future"), the result was never read, and the connection was never handed
# back: checked out for good, in a pool of one every later query waits for
# ever. A caller dropped while still QUEUED for the pool lost the connection
# the same way, one step earlier: the release handed it to a waiter whose
# chain was gone.
#
# Since k46 the transport holds what it started (ADR 0007): the statement's
# own Future -- the flight -- in a register on the storage until it settles,
# the wait for the pool until it is served, and the caller gets a Future of
# its own. What the caller does with that Future -- keep it, drop it -- no
# longer decides whether the statement is collected and the connection
# returned. Cancelling it still does what it did (t/25, t/24).
#
# WHAT IS REAL. The whole transport -- _query_async, _query_async_pinned and
# its queue, _await_query_result, the Future::IO poll on the dup(2) of a real
# fd, the release, the dead-connection report -- its pool(), the real
# DBIO::Async::Pool and core's acquire and release. Future.pm, and
# Future::IO's built-in implementation (t/32 runs the core of this file on
# IO::Async). Section 0 pins that the mocks own the DB-specific seams and
# nothing else.
#
# THE MOCK SERVER. A connection is the read end of a pipe; the write end is
# the server's. _submit_query records the statement and puts nothing on the
# pipe: the statement is in flight until the test has the server answer. A
# connection keeps ONE statement slot, as a DBD does, freed only by reading
# the result -- so a connection handed on with a result still unread refuses
# the next statement, loudly. A statement naming BAD fails with a statement
# error the session survives; one naming KILL takes the session with it.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# --- Drop31: the DB-specific seams over a pipe -------------------------------

{
  package Drop31;
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
    my $id = ++$self->{_next_id};
    $self->{server}{$id} = $w;
    return { id => $id, r => $r, socket => 7 };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->{id};
    close $conn->{r};
    $conn->{closed} = 1;
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = main::label($sql);
    push @{ $self->{wire} }, [ $label, $conn->{id} ];
    die "another command is already in progress ($conn->{in_flight})\n"
      if defined $conn->{in_flight};
    $conn->{in_flight} = $label;
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    push @{ $self->{collected} }, [ $label, $conn->{id} ];
    if ($label eq 'KILL') {
      $conn->{socket} = -1;
      return Future->fail("server closed the connection unexpectedly\n");
    }
    return Future->fail("syntax error at or near BAD\n") if $label eq 'BAD';
    return Future->done([ 'row-for', $label, $conn->{id} ]);
  }

  sub _conn_error_is_fatal {
    my ($self, $conn, $error) = @_;
    push @{ $self->{asked} }, [ $conn->{id}, $error ];
    return $conn->{socket} < 0 ? 1 : 0;
  }
}

# --- Obj31: the same driver with a connection that is no hashref -------------
#
# A blessed array. The transport keeps its per-connection state on a hashref
# connection (the poll handle, the pinned statement queue); a driver whose
# connection is none caches the poll handle itself, and gets no queue.

{
  package Obj31;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use constant { ID => 0, R => 1, IN_FLIGHT => 2, POLL_FH => 3 };

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1][R] }

  sub _conn_poll_fh {
    my ($self, $conn) = @_;
    return $conn->[POLL_FH] ||= do {
      open my $fh, '+<&', fileno $conn->[R] or die "dup: $!";
      $fh;
    };
  }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    my $id = ++$self->{_next_id};
    $self->{server}{$id} = $w;
    return bless [ $id, $r ], 'Conn31';
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->[ID];
    close $conn->[R];
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = main::label($sql);
    push @{ $self->{wire} }, [ $label, $conn->[ID] ];
    $conn->[IN_FLIGHT] = $label;
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->[R], my $byte, 1;
    my $label = $conn->[IN_FLIGHT];
    push @{ $self->{collected} }, [ $label, $conn->[ID] ];
    return Future->done([ 'row-for', $label, $conn->[ID] ]);
  }
}

sub new_storage {
  my ($class, %args) = @_;
  my $storage = ($class // 'Drop31')->new(undef);
  $storage->{_next_id} = 0;
  $storage->{server}   = {};
  $storage->{$_} = [] for qw(closed wire collected asked);
  # pool_size 1 unless a section says otherwise: whether the next query is
  # served at all is what tells a connection handed back from one that is lost.
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %args }]);
  return $storage;
}

# The table a statement names: what the wire log records.
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# The server answers the statement in flight on a connection: its socket
# turns readable. A connection that was never opened has no server; the
# assertions that follow say so, rather than this helper dying.
sub answer { my ($server) = @_; syswrite $server, 'R' if $server; return }

# Turn the built-in loop. The zero timer makes it select() for real instead of
# presuming a lone read poll ready (Future::IO 0.23, _await_once), so a poll
# resolves here only when its socket really is readable.
sub turn { Future::IO->sleep(0)->get for 1 .. 3; return }

# Is the built-in loop watching nothing -- no poll and no timer? One round of
# it refuses to run when it has nothing to wait for, and that refusal is the
# answer (t/27). Asked only where nothing should be watched.
sub loop_is_idle {
  return 0 if eval { Future::IO::_DefaultImpl::F::_await_once(); 1 };
  return 1 if $@ =~ /Cowardly refusing to sit idle/;
  diag "a round of the loop died: $@";
  return 0;
}

sub outcome {
  my $f = shift;
  return 'still pending' unless $f->is_ready;
  return 'cancelled'     if $f->is_cancelled;
  return 'failed: ' . $f->failure if $f->is_failed;
  return [ $f->get ];
}

# Closes a section: nothing warned -- above all not Future.pm, about a
# sequence Future it lost.
sub quiet {
  my ($l) = @_;
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
  return;
}

# ---------------------------------------------------------------------------
# 0. The guards that give every other assertion its meaning: the mocks
#    override none of the transport's query path nor its pool(), and the pool
#    hands out and takes back as core's does.
# ---------------------------------------------------------------------------

for my $class (qw( Drop31 Obj31 )) {
  for my $method (qw( _query_async _query_async_pinned _await_query_result
                      _collect_on_readable _release_on_ready _mark_dead_on_fail
                      _abandon_on_cancel _await_readable pool )) {
    is refaddr($class->can($method)), refaddr(DBIO::Async::Storage->can($method)),
      "$class does NOT override $method -- the transport itself runs";
  }
}
is refaddr(Drop31->can('_conn_poll_fh')), refaddr(DBIO::Async::Storage->can('_conn_poll_fh')),
  'Drop31 polls the dup the transport makes';
for my $method (qw( acquire release )) {
  is refaddr(DBIO::Async::Pool->can($method)),
     refaddr(DBIO::Storage::PoolBase->can($method)),
    "DBIO::Async::Pool does NOT override $method -- core's pool decides";
}

# ---------------------------------------------------------------------------
# 1. The k46 case: a pooled query in void context, pool of one. The statement
#    is collected and its connection handed back, with nobody holding the
#    Future; the next query is served.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped in flight';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT * FROM a', []);       # void context
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: the statement is on the wire";
  is_deeply [ $pool->size, $pool->available ], [ 1, 0 ],
    "$l: ... its connection checked out";

  turn();
  is_deeply $storage->{collected}, [],
    "$l: a quiet socket resolves nothing -- the statement is still in flight";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'a', 1 ] ],
    "$l: the answer is read off the connection, though nobody holds the Future";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the connection is handed back: the pool of one has it again";
  is_deeply $storage->{closed}, [], "$l: ... not retired -- nothing was wrong with it";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  my $next = $storage->_query_async('SELECT * FROM b', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: the next query gets that connection at once";
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($next), [ [ 'row-for', 'b', 1 ] ], "$l: ... and resolves";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 2. A second caller is already QUEUED for the slot when the dropped query's
#    answer comes in. It is served by that release -- it does not wait for a
#    connection nobody will ever hand back.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped, a caller queued';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT * FROM a', []);       # dropped
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  is outcome($fb), 'still pending', "$l: b waits -- the pool of one is checked out";
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: ... and is not on the wire";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: a's release hands connection 1 to b, which is dispatched on it";

  answer($storage->{server}{1});
  turn();
  is_deeply outcome($fb), [ [ 'row-for', 'b', 1 ] ], "$l: b resolves";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ], "$l: the pool has its connection";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 3. Dropped while it still WAITS for the pool. Fire-and-forget means the
#    statement runs: when the slot frees it is dispatched, collected and its
#    connection handed back. Before k46 the release handed the connection to a
#    waiter whose chain was gone -- neither run nor returned.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped while queued';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $weak_bind;
  my $fa = $storage->_query_async('SELECT * FROM a', []);
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak_bind = $bind);
    $storage->_query_async('SELECT * FROM b WHERE x = ?', $bind);   # dropped, queued
  }
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: b waits for the slot";
  ok defined $weak_bind,
    "$l: ... holding its bind values -- they are not sent yet";

  answer($storage->{server}{1});
  turn();
  is_deeply outcome($fa), [ [ 'row-for', 'a', 1 ] ], "$l: a resolves";
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: the dropped b is dispatched once the slot is free";
  ok !defined $weak_bind,
    "$l: ... and its bind values are freed while it is in flight (ADR 0044)";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'a', 1 ], [ 'b', 1 ] ], "$l: b's answer is read";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the connection handed back";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 4. A dropped query whose statement FAILS. Nobody is there to see the error,
#    and nothing is invented to announce it; what the failure means for the
#    connection is decided as for any failed query: the driver is asked
#    (_conn_error_is_fatal, karr k26), a connection it calls dead is retired
#    and its slot goes to the caller queued for it, on a fresh connection.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped, statement error';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT * FROM BAD', []);     # dropped
  answer($storage->{server}{1});
  turn();

  is_deeply $storage->{asked}, [ [ 1, "syntax error at or near BAD\n" ] ],
    "$l: the driver is asked about the connection, with the statement's error";
  is_deeply $storage->{closed}, [], "$l: the session survived: nothing is retired";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the connection is handed back";
  quiet($l);
}

{
  my $l       = 'dropped, connection killed';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT * FROM KILL', []);    # dropped
  my $fb = $storage->_query_async('SELECT * FROM b', []);
  answer($storage->{server}{1});
  turn();

  is_deeply $storage->{asked},
    [ [ 1, "server closed the connection unexpectedly\n" ] ],
    "$l: the driver is asked about the connection";
  is_deeply $storage->{closed}, [1],
    "$l: the connection it calls dead is retired, once";
  is_deeply $storage->{wire}, [ [ 'KILL', 1 ], [ 'b', 2 ] ],
    "$l: the caller queued for the slot runs on a fresh connection";

  answer($storage->{server}{2});
  turn();
  is_deeply outcome($fb), [ [ 'row-for', 'b', 2 ] ], "$l: ... and resolves";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ], "$l: the pool holds the fresh one";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 5. A dropped query does not keep what it does not need: the caller's bind
#    arrayref goes at dispatch (ADR 0044) although the transport now holds the
#    statement's Future for the flight, and once the statement has settled the
#    transport holds nothing of it -- a storage dropped along with the Future
#    is freed, its connection closed.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped, lifetimes';
  my $storage = new_storage();

  my $weak_bind;
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak_bind = $bind);
    $storage->_query_async('SELECT * FROM a WHERE x = ?', $bind);   # dropped
  }
  ok !defined $weak_bind,
    "$l: the bind arrayref is freed while the statement is in flight";

  my ($closed, $collected, $server) =
    ($storage->{closed}, $storage->{collected}, $storage->{server}{1});
  weaken(my $weak_storage = $storage);
  undef $storage;
  ok defined $weak_storage,
    "$l: the storage, dropped as well, lives on while its statement is in flight";

  answer($server);
  turn();
  is_deeply $collected, [ [ 'a', 1 ] ], "$l: the answer is read";
  ok !defined $weak_storage,
    "$l: ... and then the storage is gone: nothing of the flight is kept";
  is_deeply $closed, [1], "$l: its connection is closed, once";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 6. A dropped PINNED statement -- one issued on a transaction's connection
#    and not awaited. The pinned statement queue (karr k33) held the statement
#    in flight on the connection before k46 already; this pins that it stays
#    so: collected, the connection idle again, the next statement sent.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped, pinned';
  my $storage = new_storage();
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;

  $storage->_query_async_pinned($conn, 'SELECT * FROM a', []);     # dropped
  $storage->_query_async_pinned($conn, 'SELECT * FROM b', []);     # dropped, waiting
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: one statement at a time";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: the first is collected and the one waiting behind it sent";
  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'a', 1 ], [ 'b', 1 ] ], "$l: both are read";
  ok !exists $conn->{_dbio_async_queue},
    "$l: the idle connection carries no queue state";
  is_deeply [ $pool->size, $pool->available ], [ 1, 0 ],
    "$l: the connection is still its holder's -- a pinned statement releases nothing";

  $pool->release($conn);
  quiet($l);
}

# ---------------------------------------------------------------------------
# 7. A connection that is NOT a hashref. It gets no statement queue, so a
#    pinned statement on it was handed to the caller as it was -- and was lost
#    with the caller's Future like a pooled one. Pooled and pinned, kept and
#    dropped: it works as a hashref connection does.
# ---------------------------------------------------------------------------

{
  my $l       = 'no hashref, pooled';
  my $storage = new_storage('Obj31');
  my $pool    = $storage->pool;

  my $kept = $storage->_query_async('SELECT * FROM kept', []);
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($kept), [ [ 'row-for', 'kept', 1 ] ],
    "$l: a query resolves";

  $storage->_query_async('SELECT * FROM a', []);       # dropped
  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'kept', 1 ], [ 'a', 1 ] ],
    "$l: a dropped query is collected";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and its connection handed back";
  quiet($l);
}

{
  my $l       = 'no hashref, pinned';
  my $storage = new_storage('Obj31');
  my $pool    = $storage->pool;
  my $conn    = $pool->acquire->get;
  isa_ok $conn, 'Conn31', "$l: the connection";

  my $pinned = $storage->_query_async_pinned($conn, 'SELECT * FROM p', []);
  is_deeply $storage->{wire}, [ [ 'p', 1 ] ], "$l: a statement is sent at once";
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($pinned), [ [ 'row-for', 'p', 1 ] ], "$l: ... and resolves";

  $storage->_query_async_pinned($conn, 'SELECT * FROM q', []);     # dropped
  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'p', 1 ], [ 'q', 1 ] ],
    "$l: a dropped statement is collected";
  ok loop_is_idle(), "$l: the loop is left watching nothing";

  $pool->release($conn);
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ], "$l: the pool has its connection";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 8. What a caller that KEEPS its Future gets is what it got: the Future is
#    its own, of a class that drives the loop, so ->get on it waits for the
#    answer (ADR 0001); and the connection is back in the pool before the
#    caller's callbacks run, so a query issued from one is served at once.
# ---------------------------------------------------------------------------

{
  my $l       = 'kept';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT * FROM a', []);
  my ($available_in_callback, $from_callback);
  $f->on_done(sub {
    $available_in_callback = $pool->available;
    $from_callback = $storage->_query_async('SELECT * FROM b', []);
  });

  answer($storage->{server}{1});
  is_deeply [ $f->get ], [ [ 'row-for', 'a', 1 ] ],
    "$l: ->get on the caller's Future drives the loop to the answer";
  is $available_in_callback, 1,
    "$l: the connection is back in the pool when the caller's callbacks run";
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: ... so a query issued from one goes out at once";

  answer($storage->{server}{1});
  is_deeply [ $from_callback->get ], [ [ 'row-for', 'b', 1 ] ], "$l: ... and resolves";
  quiet($l);
}

ok loop_is_idle(), 'at the end of the file the loop watches nothing';
is_deeply \@warnings, [], '... and nothing warned on the way out of a section';

done_testing;
