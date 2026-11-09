use strict;
use warnings;
use Test::More;

use Future;
use Future::IO qw( POLLIN );
use Scalar::Util qw( refaddr weaken );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k36: what becomes of this transport's readiness poll
# when the caller of an acquire gives up, or the pool is shut down, while the
# connection is still coming up (core k258).
#
# WHY IT MATTERS. DBIO::Async::Pool answers core's _connection_ready_future
# seam with a Future of its own: _await_conn_ready, a Future::IO poll on the
# connection's socket, repeated until the driver says the connection is ready.
# Core cannot see into it; all it does is chain onto it. Until core k258 it
# handed that chain to the caller, and a Future carries a cancel down a ->then
# chain -- so a caller that gave up stopped the poll. The connection, counted
# against the pool's size, then never became ready for anyone: in a pool of
# one, every later acquire waited for good. Since k258 the caller gets a Future
# of its own and the POOL holds the chain off the poll. Two things follow, and
# both are claims about this transport's seam, which no core test runs:
#
#   * a caller that gives up no longer stops the connect. The poll goes on,
#     and the connection that comes up goes to the next caller or to idle --
#     the pool of one stays usable. That only holds if the poll chain keeps
#     running with nobody but the pool holding it;
#   * the one thing that now ends a connect early is the pool's shutdown,
#     which cancels the chain it holds. That cancel has to arrive at the
#     Future::IO poll itself, through every round of _await_conn_ready's
#     recursion, or the loop keeps watching the dup of a socket whose
#     connection is closed, keeps the connection, its poll handle and the
#     storage alive through the callback it holds, and the next time that
#     socket stirs asks a closed connection whether it is ready -- or has
#     Future.pm warn that it "lost a sequence Future". And the caller still
#     waiting must hear about it: a failed Future, not a wait that never ends.
#
# WHAT IS REAL. The transport's whole readiness path -- _await_conn_ready,
# _await_readable, _conn_poll_fh on the dup(2) of a real fd -- the query path
# on top of it, the real DBIO::Async::Pool, and core's acquire, release and
# shutdown. Future::IO's built-in implementation does the polling. Section 0
# pins that the mock owns the DB-specific seams and nothing else.
#
# THE MOCK SERVER. A connection is a pipe, born CONNECTING: _conn_ready
# answers false until the test brings the connection up. A step of the connect
# puts a byte on the pipe -- that is what makes the socket readable -- and the
# next _conn_ready takes it off again, as a driver's connect poll reads the
# handshake. No DBD-based future_io driver has such a window today (their
# connect blocks, _conn_ready is true at once), so this path runs nowhere but
# here.
#
# NOT PINNED HERE, on purpose. What a cancelled poll leaves behind is the
# Future::IO implementation's: the built-in one drops the watch in the cancel,
# which is what section 3 observes; Future::IO::Impl::IOAsync 0.805 has no
# cancel handling and keeps its watch, and the dup with it, until the socket
# next turns readable -- held as it stands in t/34 (karr k38). And a shutdown
# called from INSIDE a poll's callback is not run here at all: cancelling a
# poll that sits behind the resolving one in the built-in loop's list makes
# that loop's round die (Future::IO 0.23, _await_once: Can't call method "fh"
# on an undefined value), for any cancel made there, not only this one --
# held as it stands in t/33, for a race of two queries and for a disconnect
# in a query's callback (karr k37).

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# --- LoopSpy27: every poll the transport makes, on the built-in loop --------
#
# $Future::IO::IMPL is the documented hook for supplying an implementation.
# The spy keeps each poll Future and delegates to the built-in implementation
# by localising the variable away for the call, as t/12's PollSpy does, so the
# poll that happens is the real one.

{
  package LoopSpy27;
  our @POLLS;

  sub poll {
    my ($class, $fh, $events) = @_;
    local $Future::IO::IMPL;     # -> the built-in impl for this one call
    my $f = Future::IO->poll($fh, $events);
    push @POLLS, $f;
    return $f;
  }

  sub sleep {
    my ($class, $seconds) = @_;
    local $Future::IO::IMPL;
    return Future::IO->sleep($seconds);
  }
}
$Future::IO::IMPL = 'LoopSpy27';

sub polls { return @LoopSpy27::POLLS }

# --- Connect27: the DB-specific seams over a pipe ----------------------------

{
  package Connect27;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    my $conn = { id => ++$self->{_next_id}, r => $r, w => $w, up => 0 };
    # Held weakly: the test reaches a connection no acquire has resolved with
    # yet, without being what keeps it alive.
    push @{ $self->{conns} }, $conn;
    Scalar::Util::weaken($self->{conns}[-1]);
    return $conn;
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  # Every ask is recorded: an ask after the connection was closed is the
  # finding. A refused connect is a die, the way a driver reports one.
  sub _conn_ready {
    my ($self, $conn) = @_;
    push @{ $self->{asked} }, $conn->{id};
    sysread $conn->{r}, my $handshake, delete $conn->{unread} if $conn->{unread};
    die $conn->{refused} if defined $conn->{refused};
    return $conn->{up} ? 1 : 0;
  }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= DBIO::Async::Pool->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, [ main::label($sql), $conn->{id} ];
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row-for', $self->{wire}[-1][0], $conn->{id} ]);
  }
}

sub new_storage {
  my %args = @_;
  my $storage = Connect27->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(conns closed asked wire pool_errors);
  # pool_size 1 unless a section says otherwise: whether the next acquire is
  # served at all is what tells a connection that came up from one that was
  # lost.
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %args }]);
  @LoopSpy27::POLLS = ();
  return $storage;
}

sub conn { my ($storage, $id) = @_; return $storage->{conns}[ $id - 1 ] }

# One step of the connect that does not finish it: the socket stirs. A
# connection that was never opened has no socket; the assertions that follow
# say so, rather than this helper dying.
sub stir {
  my $conn = shift or return;
  syswrite $conn->{w}, 'C';
  $conn->{unread}++;
  return;
}

# The last step: the connection is up.
sub come_up {
  my $conn = shift or return;
  $conn->{up} = 1;
  return stir($conn);
}

# The table a statement names: what the wire log records.
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# Turn the built-in loop. The zero timer makes it select() for real instead of
# presuming a lone read poll ready (Future::IO 0.23, _await_once), so a poll
# resolves here only when its socket really is readable.
sub turn { Future::IO->sleep(0)->get for 1 .. ($_[0] // 3); return }

# Turn the loop until $f settles. A caller queued for the pool hangs off a
# pool waiter, a plain Future that cannot ->get while pending; a Future still
# pending after 50 turns is the finding.
sub drive {
  my $f = shift;
  for (1 .. 50) { last if $f->is_ready; turn(1) }
  return $f;
}

# Is the built-in loop watching nothing -- no poll and no timer? One round of
# it refuses to run when it has nothing to wait for, and that refusal is the
# answer. Asked only where nothing should be watched: a round that does run
# resolves what it finds, and one that dies of what it finds had something to
# find.
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

# The id of the connection an acquire resolved with, or how it ended instead.
sub conn_id {
  my $f = shift;
  my $got = outcome($f);
  return ref $got ? $got->[0]{id} : $got;
}

# Closes a section: nothing was reported to the pool's on_error and nothing
# warned.
sub quiet {
  my ($l, $pool_errors) = @_;
  is_deeply $pool_errors, [], "$l: no pool error";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
  return;
}

my $SHUT_DOWN = qr/^failed: Connection pool has been shut down/;

# ---------------------------------------------------------------------------
# 0. The guards that give every other assertion its meaning: the mock
#    overrides none of the transport's readiness or query path, the pool is
#    core's but for the readiness seam, and loop_is_idle can tell a watched
#    loop from an idle one.
# ---------------------------------------------------------------------------

for my $method (qw(_await_conn_ready _await_readable _conn_poll_fh
                   _query_async _await_query_result _release_on_ready)) {
  is refaddr(Connect27->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
for my $method (qw(acquire release shutdown)) {
  is refaddr(DBIO::Async::Pool->can($method)),
     refaddr(DBIO::Storage::PoolBase->can($method)),
    "DBIO::Async::Pool does NOT override $method -- core's pool decides";
}
isnt refaddr(DBIO::Async::Pool->can('_connection_ready_future')),
     refaddr(DBIO::Storage::PoolBase->can('_connection_ready_future')),
  'the readiness seam IS the transport\'s own -- core sees only a Future';

{
  pipe(my $r, my $w) or die "pipe: $!";
  my $poll = Future::IO->poll($r, POLLIN);
  ok !loop_is_idle(), 'the probe: with one poll pending the loop is not idle';
  ok loop_is_idle(),  'the probe: ... and once that poll is gone, it is';
  is_deeply [ splice @warnings ], [], 'the probe: asking warns nothing';
}

# ---------------------------------------------------------------------------
# 1. A caller that does not give up is served as before: the hand-over must
#    not cost what worked.
# ---------------------------------------------------------------------------

{
  my $l       = 'waits';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  ok !$f->is_ready, "$l: the acquire is pending while its connection comes up";
  is scalar(polls()), 1, "$l: the transport polls the socket for it";

  turn();
  ok !$f->is_ready, "$l: a quiet socket resolves nothing";
  is_deeply $storage->{asked}, [1],
    "$l: ... and the connection is not asked again";

  come_up(conn($storage, 1));
  drive($f);
  is conn_id($f), 1, "$l: it resolves with the connection once that is up";
  is $pool->available, 0, "$l: borrowed by the caller, not idle";
  ok loop_is_idle(), "$l: nothing is watched once the connection is up";
  ok !exists conn($storage, 1)->{_dbio_async_ready},
    "$l: the connection carries no readiness bookkeeping once it is up (karr k49)";
  quiet($l, $storage->{pool_errors});
}

# The blocking form. The sync methods are ->get on the async ones (ADR 0001),
# so the Future a caller waits on for a cold connection has to run the loop in
# ->get. It is the caller's own Future now, no longer a ->then off the poll; a
# plain Future there croaks "is not yet complete and does not provide ->await".
{
  my $l       = 'blocks';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  come_up(conn($storage, 1));
  my $conn = eval { $f->get };
  is $@, '', "$l: ->get on an acquire still connecting runs the loop";
  is $conn && $conn->{id}, 1, "$l: ... and returns the connection";
  quiet($l, $storage->{pool_errors});
}

{
  my $l       = 'waits, refused';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  conn($storage, 1)->{refused} = "connection refused\n";
  stir(conn($storage, 1));
  drive($f);

  like conn_id($f), qr/^failed: connection refused/,
    "$l: the connect's own error reaches the caller";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  is $pool->size, 0, "$l: ... and keeps no slot";
  ok loop_is_idle(), "$l: nothing is watched after a refused connect";
  quiet($l, $storage->{pool_errors});
}

# ---------------------------------------------------------------------------
# 2. (a) The caller gives up while the connection comes up. The cancel stops
#    at the caller's Future: the poll goes on, and the connection that comes
#    up is the pool's to hand out. In a pool of one the next caller is served
#    by exactly that connection -- before core k258 it waited for good.
# ---------------------------------------------------------------------------

{
  my $l       = 'gives up';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  $f->cancel;
  my ($poll) = polls();

  ok $f->is_cancelled, "$l: the acquire is cancelled";
  ok !$poll->is_ready,
    "$l: the cancel did not reach the poll -- the connect is still watched";
  is_deeply $storage->{closed}, [], "$l: the connection is not closed";
  is $pool->size, 1, "$l: ... and still holds the pool's one slot";
  is $pool->available, 0, "$l: ... not idle: it is not up yet";

  turn();
  ok !$poll->is_ready, "$l: a quiet socket: still connecting";

  come_up(conn($storage, 1));
  turn();
  is_deeply $storage->{asked}, [ 1, 1 ],
    "$l: the socket stirred and the connection was asked again -- the chain "
    . 'runs with only the pool holding it';
  is $pool->available, 1, "$l: the connection came up and is idle";

  my $g = $pool->acquire;
  is conn_id($g), 1, "$l: the next acquire is served, by that connection";
  is $storage->{_next_id}, 1, "$l: ... no second one was opened for it";
  $pool->release($g->get) if $g->is_done;
  ok loop_is_idle(), "$l: nothing is watched once the connection is up";
  quiet($l, $storage->{pool_errors});
}

# A second caller already queued for the slot when the first gives up.
{
  my $l       = 'gives up, one queued';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  my $g = $pool->acquire;
  ok !$g->is_ready, "$l: the second caller waits -- the pool of one is taken";

  $f->cancel;
  come_up(conn($storage, 1));
  drive($g);

  is conn_id($g), 1,
    "$l: the connection the first caller gave up on goes to the second";
  is $pool->available, 0, "$l: ... borrowed, not idle as well";
  quiet($l, $storage->{pool_errors});
}

# The same through the query path: the Future a caller cancels is the ->then
# _query_async chains on the acquire, and the cancel travels down to it.
{
  my $l       = 'gives up, query';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $qa = $storage->_query_async('SELECT * FROM a', []);
  my $qb = $storage->_query_async('SELECT * FROM b', []);
  $qa->cancel;

  is_deeply $storage->{closed}, [],
    "$l: nothing is retired -- the cancelled query dispatched nothing";

  come_up(conn($storage, 1));
  drive($qb);
  is_deeply outcome($qb), [ [ 'row-for', 'b', 1 ] ],
    "$l: the query queued behind it runs, on the connection that came up";
  is_deeply $storage->{wire}, [ [ 'b', 1 ] ],
    "$l: the cancelled query never reached the wire";

  my $qc = drive($storage->_query_async('SELECT * FROM c', []));
  is_deeply outcome($qc), [ [ 'row-for', 'c', 1 ] ],
    "$l: and the pool of one goes on serving";
  quiet($l, $storage->{pool_errors});
}

# The connect is refused after the caller gave up: nobody waits for the
# error, and the connection must still leave the pool, or its slot is lost.
{
  my $l       = 'gives up, refused';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  $f->cancel;
  conn($storage, 1)->{refused} = "connection refused\n";
  stir(conn($storage, 1));
  turn();

  is_deeply $storage->{closed}, [1], "$l: the refused connection is closed";
  is $pool->size, 0, "$l: ... and keeps no slot";

  my $g = $pool->acquire;
  come_up(conn($storage, 2));
  drive($g);
  is conn_id($g), 2, "$l: the next acquire opens a connection of its own";
  ok loop_is_idle(), "$l: nothing is watched once that one is up";
  quiet($l, $storage->{pool_errors});
}

# ---------------------------------------------------------------------------
# 3. (b), (c) The pool is shut down while a connection comes up. The caller
#    still waiting fails; the chain the pool held is cancelled, and that
#    cancel arrives at the Future::IO poll. Afterwards the loop watches
#    nothing, nothing keeps the connection, its poll handle or the storage
#    alive, and a poll that resolves late changes nothing.
# ---------------------------------------------------------------------------

{
  my $l       = 'shutdown';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  my ($poll) = polls();
  weaken(my $weak_conn = conn($storage, 1));
  weaken(my $weak_fh   = $weak_conn->{_dbio_async_poll_fh});
  ok defined $weak_fh, "$l: the socket's dup is what the loop watches";

  $storage->disconnect;

  like outcome($f), $SHUT_DOWN,
    "$l: the caller still waiting for the connection fails, saying why";
  ok $poll->is_cancelled, "$l: the poll itself is cancelled";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";

  # What the cancelled connect still holds is sampled BEFORE the loop is asked
  # anything: a round of it would resolve a poll left behind, and with that
  # let go of everything the poll held.
  ok !defined $weak_conn, "$l: nothing holds the connection any more";
  ok !defined $weak_fh,   "$l: ... nor its poll handle: the dup is closed";

  my ($asked, $pool_errors) = @$storage{qw(asked pool_errors)};
  weaken(my $weak_storage = $storage);
  undef $pool;
  undef $storage;
  ok !defined $weak_storage,
    "$l: nothing of the cancelled connect holds the storage";

  # What an implementation that resolves the poll after all would do. A
  # cancelled Future takes neither; one still pending would run the chain.
  ok eval { $poll->done(POLLIN); $poll->fail("late\n"); 1 },
    "$l: a poll resolving late is ignored" or diag $@;
  is_deeply $asked, [1],
    "$l: ... it does not ask the closed connection whether it is ready";
  like outcome($f), $SHUT_DOWN, "$l: ... and leaves the caller as it was";

  ok loop_is_idle(), "$l: the loop watches nothing any more";
  quiet($l, $pool_errors);
}

# After a step of the connect that did not finish it, the poll being waited on
# is the second one: _await_conn_ready asked, heard "not yet" and polled
# again. The cancel has to reach that one.
{
  my $l       = 'shutdown, second poll';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  stir(conn($storage, 1));
  turn();
  my @polls = polls();
  is scalar(@polls), 2, "$l: the socket stirred, not ready: polled again";
  ok $polls[0]->is_done && !$polls[1]->is_ready,
    "$l: ... the first poll resolved, the second is pending";
  weaken(my $weak_conn = conn($storage, 1));

  $storage->disconnect;

  ok $polls[1]->is_cancelled, "$l: the pending poll is cancelled";
  like outcome($f), $SHUT_DOWN, "$l: the caller fails";
  ok !defined $weak_conn, "$l: nothing holds the connection any more";
  ok loop_is_idle(), "$l: the loop watches nothing any more";
  is_deeply $storage->{asked}, [ 1, 1 ],
    "$l: the connection was not asked again";
  quiet($l, $storage->{pool_errors});
}

# Through the query path: the query waiting for its connection fails.
{
  my $l       = 'shutdown, query';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $q = $storage->_query_async('SELECT * FROM a', []);
  $storage->disconnect;

  like outcome($q), $SHUT_DOWN, "$l: the query fails, saying why";
  is_deeply $storage->{wire}, [], "$l: it never reached the wire";
  ok loop_is_idle(), "$l: the loop watches nothing any more";
  quiet($l, $storage->{pool_errors});
}

# The caller had given up already. Its connect ran on (section 2), so the
# shutdown is what has to stop it.
{
  my $l       = 'shutdown, given up';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  $f->cancel;
  my ($poll) = polls();
  $storage->disconnect;

  ok $poll->is_cancelled, "$l: the poll nobody waited on is cancelled too";
  ok loop_is_idle(), "$l: the loop watches nothing any more";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";
  is outcome($f), 'cancelled', "$l: the caller's Future stays cancelled";
  quiet($l, $storage->{pool_errors});
}

# Two connections coming up at once: every chain the pool holds is cancelled.
{
  my $l       = 'shutdown, two connecting';
  my $storage = new_storage(pool_size => 2);
  my $pool    = $storage->pool;

  my @f = ($pool->acquire, $pool->acquire);
  my @polls = polls();
  is scalar(@polls), 2, "$l: two connections, two polls";

  $storage->disconnect;

  is scalar(grep { $_->is_cancelled } @polls), 2, "$l: both polls are cancelled";
  like outcome($_), $SHUT_DOWN, "$l: a caller fails" for @f;
  is_deeply [ sort @{ $storage->{closed} } ], [ 1, 2 ],
    "$l: both connections are closed, once each";
  ok loop_is_idle(), "$l: the loop watches nothing any more";
  quiet($l, $storage->{pool_errors});
}

# ---------------------------------------------------------------------------
# 4. A connection the pool RETIRES while it comes up (core k261, dbio
#    b96971e27): the acquire that waits for it fails, saying so, and the pool
#    parks its chain on the readiness Future instead of cancelling it. The
#    transport's part: the connection is closed once, and what the poll did
#    for it does not outlive that.
# ---------------------------------------------------------------------------

{
  my $l       = 'retired while coming up';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  my ($poll) = polls();
  my $conn = conn($storage, 1);
  weaken(my $weak_conn = $conn);
  weaken(my $weak_fh   = $conn->{_dbio_async_poll_fh});

  ok eval { $pool->_retire_connection($conn); 1 }, "$l: the retirement does not die"
    or diag $@;
  undef $conn;

  like outcome($f), qr/^failed: Connection was retired while it was coming up/,
    "$l: the caller waiting for it fails, saying why";
  is_deeply $storage->{closed}, [1], "$l: the connection is closed, once";

  # The pool does not cancel the readiness Future of a connection it retired,
  # it parks its chain on it (core k261); cancelling it from the transport
  # would leave that chain without the failure path that offers the slot to
  # the next waiter. So the transport FAILS the readiness Future where the
  # pool closes the connection (_abandon_flights_on, karr k49) and lets go of
  # the poll under it.
  ok $poll->is_cancelled, "$l: the poll is let go of";
  ok !defined $weak_conn, "$l: nothing holds the closed connection any more";
  ok !defined $weak_fh,   "$l: ... nor its poll handle: the dup is closed";
  ok loop_is_idle(), "$l: the loop watches nothing any more";

  # What an implementation that resolves the poll after all would do.
  ok eval { $poll->done(POLLIN); 1 }, "$l: a poll resolving late is ignored"
    or diag $@;
  is_deeply $storage->{asked}, [1],
    "$l: ... the closed connection is not asked whether it is ready";
  is_deeply $storage->{closed}, [1], "$l: ... and not closed a second time";
  like outcome($f), qr/^failed: Connection was retired/,
    "$l: ... and the caller is left as it was";
  quiet($l, $storage->{pool_errors});
}

# The poll being waited on is the second one.
{
  my $l       = 'retired, second poll';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  stir(conn($storage, 1));
  turn();
  my @polls = polls();
  is scalar(@polls), 2, "$l: the socket stirred, not ready: polled again";
  my $conn = conn($storage, 1);
  weaken(my $weak_conn = $conn);

  $pool->_retire_connection($conn);
  undef $conn;

  ok $polls[1]->is_cancelled, "$l: the pending poll is let go of";
  like outcome($f), qr/^failed: Connection was retired while it was coming up/,
    "$l: the caller fails, saying why";
  ok !defined $weak_conn, "$l: nothing holds the connection any more";
  ok loop_is_idle(), "$l: the loop watches nothing any more";
  is_deeply $storage->{asked}, [ 1, 1 ], "$l: the connection was not asked again";
  is_deeply $storage->{closed}, [1], "$l: closed once";
  quiet($l, $storage->{pool_errors});
}

# A caller queued for the slot is offered it (core k260): the failed readiness
# Future is what tells the pool, so the transport must fail it, not drop it.
{
  my $l       = 'retired, one queued';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  my $g = $pool->acquire;
  $pool->_retire_connection(conn($storage, 1));

  like outcome($f), qr/^failed: Connection was retired/, "$l: the first fails";
  come_up(conn($storage, 2));
  drive($g);
  is conn_id($g), 2, "$l: the second is served by a connection of its own";
  is_deeply $storage->{closed}, [1], "$l: the retired one was closed once";
  quiet($l, $storage->{pool_errors});
}

# A connection that is up already: retiring it has no readiness poll to let go
# of, and nothing is closed twice.
{
  my $l       = 'retired, up already';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  come_up(conn($storage, 1));
  drive($f);
  my $conn = $f->get;
  ok !exists $conn->{_dbio_async_ready}, "$l: no readiness bookkeeping is left";
  $pool->release($conn);
  weaken(my $weak_conn = $conn);
  $pool->_retire_connection($conn);
  undef $conn;
  undef $f;

  is_deeply $storage->{closed}, [1], "$l: closed once";
  is_deeply $storage->{asked}, [ 1, 1 ], "$l: the closed connection is not asked";
  ok loop_is_idle(), "$l: the loop watches nothing";
  ok !defined $weak_conn, "$l: nothing holds the connection";
  quiet($l, $storage->{pool_errors});
}

{
  my $l       = 'retired, then shutdown';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $pool->acquire;
  $pool->_retire_connection(conn($storage, 1));
  $storage->disconnect;
  is_deeply $storage->{closed}, [1], "$l: closed once, not again by the shutdown";
  ok loop_is_idle(), "$l: the loop watches nothing";
  quiet($l, $storage->{pool_errors});
}

ok loop_is_idle(), 'at the end of the file the loop watches nothing';
is_deeply \@warnings, [], '... and nothing warned on the way out of a section';

done_testing;
