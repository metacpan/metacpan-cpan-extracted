use strict;
use warnings;
use Test::More;
use Scalar::Util 'refaddr';

use Future;
use Future::IO qw( POLLIN );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;

# OFFLINE test for the PRODUCTIVE Future::IO transport path (karr k15 point 1):
# _await_query_result -> _submit_query -> _await_readable -> Future::IO->poll ->
# _collect_result, plus the _await_conn_ready recursion and the _conn_poll_fh
# dup caching. No DB, no DBD, no event loop -- the "socket" is a real pipe(2)
# and the watcher is Future::IO's own built-in implementation.
#
# WHY THIS FILE EXISTS. Every other transport test in this dist substitutes the
# watcher seam: t/04 and t/08 override _await_readable, t/03 and t/11 override
# _await_conn_ready. Each does so for a good reason of its own, but the effect
# is that the seam where this transport touches Future::IO -- the one thing
# ADR 0004 says is deliberately concentrated here so it can be reworked
# punctually -- was pinned by nothing. This file is the one that runs it: the
# assertions in section 0 are what keep it that way, by refusing to let this
# file's own mock override any of the seams under test.
#
# WHAT IS REAL AND WHAT IS NOT. Real: _query_async, _query_async_pinned,
# _await_query_result, _collect_on_readable, _release_on_ready, _await_readable,
# _conn_poll_fh, _await_conn_ready, DBIO::Async::Pool, and the dup(2) of a real
# file descriptor. Not real: the database. The driver seams (_submit_query /
# _collect_result) write and read one byte on a pipe instead of talking to a
# server, which is all this layer ever asks of them -- "put the query on the
# wire" and "the fd is readable, take the result off it".
#
# NOT pinned here, on purpose: how long a poll stays pending. Future::IO's
# built-in implementation resolves a lone POLLIN poller without a select(2)
# round at all (Future::IO 0.23, _DefaultImpl::_await_once: "just presume it's
# ready"), so readiness *timing* is a property of whichever Future::IO::Impl::*
# the user installs, not of this transport. What this file pins is the wiring:
# that the seam really goes through Future::IO->poll, on the handle
# _conn_poll_fh cached, in the order the POD promises.
#
# THE SPY. $Future::IO::IMPL is the documented hook for supplying an
# implementation (Future::IO, "THE $IMPL VARIABLE"). PollSpy records every poll
# and then delegates to the built-in implementation by localising the variable
# away for the duration of the call, so the poll that happens is the real one.
# It is what lets the assertions below say WHICH filehandle the loop was handed
# -- the difference between "a dup is cached" (an implementation detail) and
# "every poll on this connection is made on the same, still-open fd" (the
# correctness claim in _conn_poll_fh's POD).

{
  package PollSpy;
  our @POLLS;
  sub poll {
    my ($class, $fh, $events) = @_;
    push @POLLS, { fileno => fileno($fh), refaddr => Scalar::Util::refaddr($fh) };
    local $Future::IO::IMPL;     # -> the built-in impl for this one call
    return Future::IO->poll($fh, $events);
  }
}
$Future::IO::IMPL = 'PollSpy';

sub polls_reset { @PollSpy::POLLS = () }
sub polls       { [ @PollSpy::POLLS ] }

# --- PipeMock: a concrete transport whose wire is a real pipe --------------
#
# The connection is a hashref holding a pipe pair. _conn_fileno hands back the
# RAW integer fd of the read end -- exactly the shape a driver supplies (e.g.
# DBD::Pg's pg_socket) and the shape _conn_poll_fh has to turn into a
# filehandle. _submit_query makes the fd readable (the server answered);
# _collect_result drains that byte again, so a connection is reusable.

{
  package PipeMock;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _normalize_conninfo       { $_[1] }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w}; }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { r => $r, w => $w, id => ++$self->{_next_id} };
  }

  sub _conn_fileno { fileno($_[1]{r}) }

  # Ready on the Nth ask: {cold} counts how many times this connection still
  # answers "not ready". Answering "not ready" also makes the fd readable --
  # that is what a still-connecting socket does, and it is what lets the
  # _await_conn_ready recursion make progress through a real poll.
  sub _conn_ready {
    my ($self, $conn) = @_;
    push @{ $self->{log} }, 'ready?';
    return 1 unless ($conn->{cold} || 0) > 0;
    $conn->{cold}--;
    syswrite $conn->{w}, 'C';
    return 0;
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{log} },  'submit';
    push @{ $self->{wire} }, { sql => $sql, bind => [@$bind], conn => $conn->{id} };
    syswrite $conn->{w}, 'R';      # the answer is on the wire -> fd readable
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    push @{ $self->{log} }, 'collect';
    sysread $conn->{r}, my $byte, 1;
    return Future->done([ 'row-for', $self->{wire}[-1]{sql} ]);
  }
}

sub new_storage {
  my %args = @_;
  my $storage = PipeMock->new(undef);
  $storage->{_next_id} = 0;
  $storage->{log}      = [];
  $storage->{wire}     = [];
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %args }]);
  polls_reset();
  return $storage;
}

# ---------------------------------------------------------------------------
# 0. The guard that gives every other assertion in this file its meaning: the
#    mock overrides the DB-specific seams and NOTHING of the transport. If a
#    later edit "simplifies" one of these by stubbing it out here, the file
#    would keep passing while testing a mock instead of the transport -- so
#    compare the resolved code refs, which is the only probe that can tell an
#    inherited method from an overridden one (core ADR 0032, addendum
#    2026-07-27; the same probe core itself uses in _async_storage).
# ---------------------------------------------------------------------------

for my $seam (qw(
  _query_async _query_async_pinned _await_query_result _collect_on_readable
  _release_on_ready _await_readable _conn_poll_fh _await_conn_ready
)) {
  is refaddr(PipeMock->can($seam)), refaddr(DBIO::Async::Storage->can($seam)),
    "this file's mock does NOT override $seam -- the transport itself runs";
}

# ---------------------------------------------------------------------------
# 1. One pooled query, end to end over the real seam.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  my $f = $storage->_query_async('SELECT ?', ['x']);
  ok !$f->is_ready,
    'the query Future is pending after dispatch -- the result is awaited on the '
    . 'fd, not produced inline';

  my $rows = $f->get;

  is_deeply $storage->{log}, [ 'ready?', 'submit', 'collect' ],
    'the productive order is: readiness gate, submit to the wire, then collect '
    . '-- the collect runs only after the poll resolved';
  is_deeply $rows, [ 'row-for', 'SELECT ?' ],
    'the query resolves with what _collect_result read off the connection';
  is $storage->{wire}[0]{bind}[0], 'x', 'the bind values reached the wire';

  is scalar @{ polls() }, 1,
    'exactly one Future::IO->poll for one query on a ready connection';

  my $conn = $storage->pool->{_connections}[0];
  isnt polls()->[0]{fileno}, $storage->_conn_fileno($conn),
    'the loop was handed the DUP, not the driver\'s own socket fd -- closing '
    . 'the poll handle can never touch the connection\'s fd';
  is polls()->[0]{refaddr}, refaddr($conn->{_dbio_async_poll_fh}),
    'and the dup it was handed is the one cached on the connection';

  is $storage->pool->available, 1,
    'the pooled query released its connection when the Future became ready';
}

# ---------------------------------------------------------------------------
# 2. The _conn_poll_fh caching promise, stated as the POD states it: not "a dup
#    is cached" but "every poll on a connection is made on the SAME, still-open
#    fd". Future::IO implementations mark the poll Future done BEFORE they
#    unwatch the handle, so a fresh-dup-per-poll handle that died with its poll
#    would be gone by the time the loop unwatches it by fileno -- and the freed
#    fd, reused by the next dup, collides with the stale watch. A size-1 pool
#    puts all three queries on one connection, which is where that would show.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();

  $storage->_query_async("SELECT $_")->get for 1 .. 3;

  my $conn = $storage->pool->{_connections}[0];
  is scalar @{ $storage->pool->{_connections} }, 1,
    'all three queries ran on the one connection a size-1 pool has';

  is scalar @{ polls() }, 3, 'three queries, three polls';

  my %filenos = map { $_->{fileno} => 1 } @{ polls() };
  is scalar keys %filenos, 1,
    'every poll on the connection was made on the same fd number';

  # The load-bearing one. An fd NUMBER can be stable by accident: a
  # fresh-dup-per-poll that dies with its poll frees the number and the next
  # dup gets it straight back, so the assertion above stays green through
  # exactly the bug this section is about. The handle IDENTITY cannot be
  # accidental -- it is only the same object if it was never re-made.
  my %handles = map { $_->{refaddr} => 1 } @{ polls() };
  is scalar keys %handles, 1,
    'and literally the same filehandle object each time -- the dup is cached '
    . 'for the connection\'s life, not made fresh per poll';

  is refaddr($storage->_conn_poll_fh($conn)), (keys %handles)[0],
    '_conn_poll_fh still answers with that same handle after the polls';
  ok defined fileno($storage->_conn_poll_fh($conn)),
    'and its fileno is still valid once every poll has resolved -- what keeps '
    . 'the loop\'s watch/unwatch cycle consistent';
}

# ---------------------------------------------------------------------------
# 3. The dup is independent of the driver's fd. This is the property that lets
#    the transport own a filehandle at all: it may be closed (with the
#    connection) without ever disturbing the socket the driver hands out.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $conn    = $storage->pool->acquire->get;

  my $poll_fh = $storage->_conn_poll_fh($conn);
  isnt fileno($poll_fh), $storage->_conn_fileno($conn),
    'the poll handle is a dup: a different fd from the driver\'s own';

  close $poll_fh;
  syswrite $conn->{w}, 'Z';
  is sysread($conn->{r}, my $byte, 1), 1,
    'closing the poll handle left the driver\'s own fd fully usable (dup(2), '
    . 'not a second reference to the same handle)';
  is $byte, 'Z', '... and reading it gives back what was written';
}

# ---------------------------------------------------------------------------
# 4. _await_conn_ready recursion, over the real poll. t/03 pins the pool's
#    readiness GATE by overriding this method, so the recursion itself -- ask
#    the driver, wait on the fd, ask again -- has never run in a test. A
#    connection that answers "not ready" twice must be polled twice and asked
#    three times, and must resolve to the connection.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $conn    = $storage->_create_pool_connection;
  $conn->{cold} = 2;

  my $f = $storage->_await_conn_ready($conn);
  is $f->get, $conn, 'a cold connection eventually resolves to itself';

  is scalar(grep { $_ eq 'ready?' } @{ $storage->{log} }), 3,
    'the driver was asked three times: twice "no", then "yes"';
  is scalar @{ polls() }, 2,
    'and each "no" was followed by a real Future::IO poll on the fd -- the '
    . 'recursion goes through the watcher seam, not a busy loop';

  is $storage->_await_conn_ready($conn)->get, $conn,
    'an already-ready connection resolves too';
  is scalar @{ polls() }, 2, '... without polling at all (immediate branch)';
}

# ---------------------------------------------------------------------------
# 5. The same recursion underneath the real pool gate. t/03 proves the gate
#    delegates; this proves the delegation lands somewhere that actually works:
#    a pool whose fresh connection is cold hands out a Future that resolves
#    only after the readiness recursion has polled its way to ready.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  $storage->{cold_new_conns} = 1;
  {
    no warnings 'redefine';
    my $orig = PipeMock->can('_create_pool_connection');
    local *PipeMock::_create_pool_connection = sub {
      my $conn = $orig->(@_);
      $conn->{cold} = 1;
      return $conn;
    };

    my $conn = $storage->pool->acquire->get;
    ok $conn, 'acquire resolves a cold connection through the readiness gate';
    is scalar @{ polls() }, 1,
      'the gate polled once -- DBIO::Async::Pool::_connection_ready_future '
      . 'really reaches the Future::IO seam';
    is scalar(grep { $_ eq 'ready?' } @{ $storage->{log} }), 2,
      'and asked the driver twice, exactly as the recursion prescribes';
  }
}

# ---------------------------------------------------------------------------
# 6. The pinned path over the same real seam: same submit/poll/collect, and no
#    release -- the connection stays checked out, which is the whole point of a
#    transaction pin.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $conn    = $storage->pool->acquire->get;
  is $storage->pool->available, 0, 'the pinned connection is checked out';

  polls_reset();
  my $rows = $storage->_query_async_pinned($conn, 'UPDATE t SET a = ?', [7])->get;

  is_deeply $rows, [ 'row-for', 'UPDATE t SET a = ?' ],
    'the pinned query resolves through the same submit -> poll -> collect path';
  is scalar @{ polls() }, 1, 'one poll for the pinned query';
  is polls()->[0]{refaddr}, refaddr($conn->{_dbio_async_poll_fh}),
    'on the pinned connection\'s own cached dup';
  is $storage->pool->available, 0,
    'and the connection is STILL checked out -- the pinned path never releases';
}

done_testing;
