use strict;
use warnings;
use Test::More;

# Loaded before anything polls: Future::IO takes the implementation that is
# loaded first, and this one applies itself as it loads. Only a recommendation
# of this dist, so the file skips without it.
BEGIN {
  eval { require IO::Async::Loop; require Future::IO::Impl::IOAsync; 1 }
    or plan skip_all => 'Future::IO::Impl::IOAsync (and IO::Async) not installed';
}

use Future;
use Future::IO;
use Scalar::Util qw( refaddr weaken );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test for karr k38, and for a second behaviour of the same
# implementation found beside it: what Future::IO::Impl::IOAsync does with
# this transport's polls, held as it stands. Its counterpart for Future::IO's
# built-in implementation is t/33 (karr k37) -- one process loads one
# implementation, hence two files.
#
# THE TWO UPSTREAM BEHAVIOURS (Future::IO::Impl::IOAsync 0.805, the newest
# release; sub poll).
#
#   A. A CANCELLED POLL KEEPS ITS WATCH (karr k38). poll registers no
#      on_cancel. The loop goes on watching the handle of a cancelled poll,
#      and holding it, until that handle next turns readable; only then is
#      the poll taken off its list and the handle unwatched. For this
#      transport that handle is the dup of a connection's socket, and every
#      statement let go of in flight leaves one behind: a statement the caller
#      cancelled (section 1), one whose connection was closed under it
#      (section 2) -- and so does a listen watch that is stopped (the end of
#      section 6). The socket turns readable at the latest when the server
#      closes its end.
#
#   B. THE READ HANDLER IS NOT REENTRANT. It resolves the first poll waiting
#      on a handle and takes it off the list AFTERWARDS. A callback that runs
#      inside that resolve and turns the loop itself -- a ->get -- while the
#      handle turns readable again has that event delivered to the poll that
#      is already done, and the death comes out of its ->get:
#
#        IO::Async::Future=HASH(...) is already done and cannot be ->done
#        at Future/IO/Impl/IOAsync.pm line 88.
#
#      For this transport that is a SYNCHRONOUS statement issued from the
#      callback of a statement on the same connection, whose own answer is
#      what turns the handle readable (section 3) -- and so every synchronous
#      statement of a txn_do block, which core runs from the callback of
#      BEGIN's Future (section 4, the karr k34 case; t/26 runs it on the
#      built-in implementation, where it works). Confirmed live on
#      PostgreSQL: the block dies, the transaction is rolled back. Chained
#      instead of blocking, the same block commits (section 5). And it is a
#      channel callback that blocks on anything while the next notification
#      arrives on the listen socket (section 6).
#
# WHY TODO, AND WHY ON THE TARGET. What is asserted under TODO is what a
# caller is owed -- the watch gone with the cancel, the synchronous statement
# returning its rows, the transaction committed -- and today each of those is
# red. Nothing here asserts an upstream behaviour as a passing test: this file
# is run by everybody who installs the dist with IO::Async present, and an
# assertion that the watch is still there, or that the block still dies,
# would fail every such install on the day upstream changes it. A TODO turns
# up as "TODO passed" in the harness summary instead -- visible to whoever
# runs the suite, fatal to nobody -- and then the TODO blocks come off. What
# the transport owes whatever the implementation does is asserted hard,
# beside them.
#
# DECIDED 2026-10-27: both reported upstream, no workaround here. They are
# defects of Future::IO::Impl::IOAsync and reach everyone who uses it that
# way; neither is a fault of this transport. The report, a patch and new tests
# for IO-Async (the dist that ships Future::IO::Impl::IOAsync) lie in
# maint/upstream/ (IO-Async-0.805-future-io-poll.patch), handed to the author
# (Paul Evans, PEVANS) on that day. With the patch applied every TODO in this
# file passes. When an IO-Async release makes them pass: remove the TODO
# blocks and raise IO::Async in cpanfile to that release. Nothing in lib/
# works around either.
#
# WHAT IS REAL. The whole transport -- _query_async, _query_async_pinned and
# its queue, the flight register, _await_query_result, the Future::IO poll on
# the dup(2) of a real fd, _let_go, the listen watch loop -- its pool(), the
# real DBIO::Async::Pool, core's acquire, release, shutdown, disconnect,
# txn_do and txn_do_async, the context's synchronous wrappers, core's listen
# machinery, Future.pm, IO::Async. Section 0 pins that.
#
# THE MOCK SERVER. A connection is the read end of a pipe, and keeps one
# statement slot, freed only by reading the result (t/31). For A the server
# answers when the test says so. For B it answers by itself, a moment after
# the statement arrived, from a timer of the loop -- the socket of a quiet
# connection turns readable while the loop runs, because of that statement
# and nothing else, as it does with a server at the other end. Sections 3
# and 4 pin that the socket IS quiet when the inner statement goes out: the
# outer answer has been read, so what the handler trips over is the inner
# statement's own answer, not a byte the mock left lying.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };
$SIG{PIPE} = 'IGNORE';

# --- LoopSpy34: which handles the loop watches for reading ------------------
#
# IO::Async::Loop->new is the one loop of the process, the one
# Future::IO::Impl::IOAsync takes too. It is reblessed into a subclass of its
# own class that records watch_io / unwatch_io -- the loop's public calls, the
# two the implementation makes -- and passes them on, so the watching that
# happens is the real one.

{
  package LoopSpy34;
  our %READ;      # fileno => 1 for every handle watched for reading

  sub watch_io {
    my ($self, %params) = @_;
    $READ{ $params{handle}->fileno } = 1 if $params{on_read_ready};
    return $self->SUPER::watch_io(%params);
  }

  sub unwatch_io {
    my ($self, %params) = @_;
    delete $READ{ $params{handle}->fileno } if $params{on_read_ready};
    return $self->SUPER::unwatch_io(%params);
  }
}

my $loop = IO::Async::Loop->new;
@LoopSpy34::ISA = (ref $loop);
bless $loop, 'LoopSpy34';

sub watched { return scalar keys %LoopSpy34::READ }

# --- Limit34: the DB-specific seams over a pipe ------------------------------

{
  package Limit34;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Future::IO;
  use Scalar::Util ();

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # What a transaction context's CRUD needs from its owning storage (as in
  # t/26): this mock is its own owner, and proves ownership as core does.
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context does not belong to this storage generation\n"
      unless Scalar::Util::refaddr($self->_context_owner_token)
          == Scalar::Util::refaddr($ctx->_context_owner_token);
    return $ctx;
  }
  sub _select_args { my ($self, @args) = @_; return ('select', @args) }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    my $id = ++$self->{_next_id};
    $self->{server}{$id} = $w;
    my $conn = { id => $id, r => $r };
    # Held weakly: the test reaches a connection's poll handle without being
    # what keeps the connection alive.
    Scalar::Util::weaken($self->{conns}{$id} = $conn);
    return $conn;
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
    push @{ $self->{wire} }, $label;
    die "another command is already in progress ($conn->{in_flight})\n"
      if defined $conn->{in_flight};
    $conn->{in_flight} = $label;

    # The server that answers by itself: a moment later, from the loop.
    if (defined(my $after = $self->{answers_after})) {
      my $server = $self->{server}{ $conn->{id} };
      push @{ $self->{answering} },
        Future::IO->sleep($after)->on_done(sub { syswrite $server, 'R' });
    }
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    push @{ $self->{collected} }, $conn->{in_flight};
    die "Limit34: connection $conn->{id} is closed\n" if $conn->{closed};
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    return Future->done([ 'row-for', $label ]);
  }
}

# --- Listen34: the same driver, offering LISTEN --------------------------------
#
# The DB-specific listen seams over a second pipe; a notification on the wire
# is one line, its payload. The watch loop that polls that pipe is the
# transport's.

{
  package Listen34;
  our @ISA = ('Limit34');

  sub transport_capabilities { qw(listen notify) }

  sub _listen_open {
    my ($self) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    $r->blocking(0);
    $self->{notifier} = $w;
    return { r => $r };
  }

  sub _listen_close       { $_[1]{closed} = 1; return }
  sub _listen_subscribe   { 1 }
  sub _listen_unsubscribe { 1 }
  sub _listen_probe       { !$_[1]{closed} }

  # Never blocks: reads only what is there. End of file dies, as the seam's
  # POD requires of a socket driver.
  sub _listen_drain {
    my ($self, $conn) = @_;
    return [] unless main::readable($conn->{r});
    my $n = sysread $conn->{r}, my $buf, 65536;
    die "Listen34: the server closed the listen connection\n" unless $n;
    return [ map { [ 'jobs', $_, 1 ] } split /\n/, $buf ];
  }
}

sub new_storage {
  my (%args) = @_;
  my $storage = ($args{class} // 'Limit34')->new(undef);
  $storage->{_next_id} = 0;
  $storage->{server}   = {};
  $storage->{conns}    = {};
  $storage->{$_} = [] for qw(closed wire collected answering);
  $storage->{answers_after} = $args{answers_after};
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# The table a statement names, or the statement itself (BEGIN, COMMIT).
sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# The server answers the statement in flight on a connection.
sub answer { my ($server) = @_; syswrite $server, 'R' if $server; return }

# Run $code with a deadline: what goes wrong on an event loop hangs rather
# than dies, and a hanging test proves nothing. Nests -- a callback bounds its
# own blocking call inside a bounded ->get -- so the deadline it found running
# is put back when it is done.
sub bounded {
  my ($code) = @_;
  my (@result, $outer);
  my $ok = eval {
    local $SIG{ALRM} = sub { die "timed out\n" };
    $outer = alarm 10;
    @result = $code->();
    1;
  };
  my $error = $@;
  alarm($outer // 0);
  return $ok ? (1, @result) : (0, $error);
}

# Turn the IO::Async loop: ->get on a timer of its own runs it, and whatever
# socket is readable meanwhile is served.
sub turn { return bounded(sub { Future::IO->sleep(0.01)->get for 1 .. 3; 1 }) }

# Turn it until $cond holds, within the deadline -- for what several events
# of the loop have to bring about.
sub drive {
  my ($cond) = @_;
  return bounded(sub { Future::IO->sleep(0.01)->get until $cond->(); 1 });
}

# Is there something to read on $fh right now?
sub readable {
  my ($fh) = @_;
  vec(my $rin = '', fileno($fh), 1) = 1;
  return select($rin, undef, undef, 0) ? 1 : 0;
}

sub outcome {
  my $f = shift;
  return 'still pending' unless $f->is_ready;
  return 'cancelled'     if $f->is_cancelled;
  return 'failed: ' . $f->failure if $f->is_failed;
  return [ $f->get ];
}

sub quiet {
  my ($l) = @_;
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
  return;
}

my $todo_upstream = 'Reported with patch and tests 2026-10-27, see '
                  . 'maint/upstream/. Passing on a new IO-Async: drop this '
                  . 'TODO, raise IO::Async in cpanfile to that release';
my $todo_watch = 'UPSTREAM defect of Future::IO::Impl::IOAsync 0.805, not of '
               . 'DBIO: a cancelled poll keeps its watch and its handle until '
               . "the socket next turns readable. $todo_upstream";
my $todo_reentry = 'UPSTREAM defect of Future::IO::Impl::IOAsync 0.805, not '
                 . 'of DBIO: the read handler is not reentrant -- a ->get in a '
                 . 'poll callback dies when the handle turns readable again. '
                 . $todo_upstream;

# ---------------------------------------------------------------------------
# 0. The guards: it is IO::Async that polls, and the transport that runs.
# ---------------------------------------------------------------------------

is $Future::IO::IMPL, 'Future::IO::Impl::IOAsync',
  'Future::IO runs on its IO::Async implementation';
for my $method (qw( _query_async _query_async_pinned _await_query_result
                    _await_readable _conn_poll_fh _let_go _abandon_flights_on
                    pool txn_do txn_do_async
                    _listen_watch _listen_unwatch _listen_delay listen )) {
  is refaddr(Listen34->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mocks do NOT override $method -- the transport itself runs";
}
is refaddr(DBIO::Async::TransactionContext->can('select')),
  refaddr(DBIO::Storage::Async::TransactionContext->can('select')),
  "the context's synchronous select is core's select_async->get";
is watched(), 0, 'the loop watches nothing to begin with';

# ---------------------------------------------------------------------------
# 1. A (karr k38): a pooled query cancelled in flight. The transport's part
#    is done at the cancel -- the caller's Future cancelled, the connection
#    retired (karr k29). The watch on the dup of its socket stays until the
#    statement's answer, which nobody reads any more, makes the socket stir.
# ---------------------------------------------------------------------------

{
  my $l       = 'cancelled in flight';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT * FROM a', []);
  is watched(), 1, "$l: with the statement in flight the loop watches its socket";
  weaken(my $dup = $storage->{conns}{1}{_dbio_async_poll_fh});
  ok $dup, "$l: ... on the connection's poll handle";

  $f->cancel;
  is outcome($f), 'cancelled', "$l: the caller's Future is cancelled";
  is_deeply $storage->{closed}, [1], "$l: its connection is retired, at the cancel";
  is_deeply [ $pool->size, $pool->available ], [ 0, 0 ],
    "$l: ... and off the pool's books";

  TODO: {
    local $TODO = $todo_watch;
    is watched(), 0, "$l: the loop watches the socket no longer";
    ok !$dup, "$l: ... and holds its handle no longer";
    turn();
    is watched(), 0, "$l: nor once the loop has turned on the quiet socket";
  }

  answer($storage->{server}{1});
  my ($turned, $why) = turn();
  ok $turned, "$l: the answer arrives late and the loop turns: nothing dies"
    or diag $why;
  is watched(), 0, "$l: that was the event the watch waited for -- it is gone";
  ok !$dup, "$l: ... and so is the poll handle";
  is_deeply $storage->{collected}, [], "$l: the late answer is not read";
  is outcome($f), 'cancelled', "$l: ... and changes nothing for the caller";

  my $next = $storage->_query_async('SELECT * FROM b', []);
  answer($storage->{server}{2});
  my ($got, @rows) = bounded(sub { $next->get });
  ok $got, "$l: the next query is answered, on a fresh connection" or diag $rows[0];
  is_deeply \@rows, [ [ 'row-for', 'b' ] ], "$l: ... with its own rows";
  is watched(), 0, "$l: and nothing is watched once it has settled";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 2. A (karr k38): torn down with a statement in flight, by disconnect and by
#    the pool's own shutdown. The caller hears at the teardown (ADR 0007,
#    t/32). The watch stays until the socket stirs -- here as it does with a
#    real server: the other end closes.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  my $l       = "torn down, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT * FROM a', []);
  is watched(), 1, "$l: with the statement in flight the loop watches its socket";
  weaken(my $dup = $storage->{conns}{1}{_dbio_async_poll_fh});

  ok eval { $via eq 'disconnect' ? $storage->disconnect : $pool->shutdown; 1 },
    "$l: the teardown does not die" or diag $@;
  like outcome($f), qr/^failed: Statement abandoned in flight: /,
    "$l: the statement in flight fails at the teardown, saying what happened";
  my $failed_with = outcome($f);
  is_deeply $storage->{closed}, [1], "$l: its connection is closed, once";

  TODO: {
    local $TODO = $todo_watch;
    is watched(), 0, "$l: the loop watches the socket no longer";
    ok !$dup, "$l: ... and holds its handle no longer";
    turn();
    is watched(), 0, "$l: nor once the loop has turned on the quiet socket";
  }

  close delete $storage->{server}{1};           # the server closes its end
  my ($turned, $why) = turn();
  ok $turned, "$l: the server closes its end and the loop turns: nothing dies"
    or diag $why;
  is watched(), 0, "$l: that was the event the watch waited for -- it is gone";
  ok !$dup, "$l: ... and so is the poll handle";
  is_deeply $storage->{collected}, [],
    "$l: nothing was read off the closed connection";
  is outcome($f), $failed_with, "$l: ... and nothing changed for the caller";
  is_deeply $storage->{closed}, [1], "$l: the connection was not closed again";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 3. B: a synchronous statement from the callback of a statement on the same
#    connection, nothing else waiting. Pinned, that is the connection the
#    caller holds, idle as soon as its statement has settled (karr k34).
#    Pooled, it is the connection the pool hands out again: it went back
#    before the callback ran (ADR 0007), so in a pool with one idle connection
#    the callback's query gets the very one. Either way the statement goes
#    out, and its ->get turns the loop from inside the read handler.
# ---------------------------------------------------------------------------

for my $how (qw( pooled pinned )) {
  my $l       = "synchronous in a callback, $how";
  my $storage = new_storage(answers_after => 0.02);
  my $pool    = $storage->pool;
  my $pinned  = $how eq 'pinned' ? $pool->acquire->get : undef;
  my $issue   = sub {
    my ($sql) = @_;
    return $pinned ? $storage->_query_async_pinned($pinned, $sql, [])
                   : $storage->_query_async($sql, []);
  };

  my ($socket_quiet, $ok, @r);
  my $outer = $issue->('SELECT * FROM outer_t');
  $outer->on_done(sub {
    $socket_quiet = !readable($storage->{conns}{1}{r});
    ($ok, @r) = bounded(sub { $issue->('SELECT * FROM inner_t')->get });
  });

  my ($outer_ok, @outer_rows) = bounded(sub { $outer->get });
  ok $outer_ok, "$l: the outer statement is answered" or diag $outer_rows[0];
  is_deeply \@outer_rows, [ [ 'row-for', 'outer_t' ] ], "$l: ... with its rows";
  ok $socket_quiet,
    "$l: the socket was quiet when the inner statement went out -- the outer "
    . 'answer had been read';
  is_deeply $storage->{wire}, [ 'outer_t', 'inner_t' ],
    "$l: the inner statement went out, one at a time";
  is $storage->{_next_id}, 1, "$l: ... on the connection the outer one ran on";

  TODO: {
    local $TODO = $todo_reentry;
    ok $ok, "$l: the inner statement's ->get returns" or diag $r[0];
    is_deeply \@r, [ [ 'row-for', 'inner_t' ] ], "$l: ... with its rows";
  }

  # Whatever became of that ->get, the statement is the transport's until it
  # settles: collected, and the connection good for the next one.
  my ($turned, $why) = turn();
  ok $turned, "$l: the loop turns on: nothing dies" or diag $why;
  is_deeply $storage->{collected}, [ 'outer_t', 'inner_t' ],
    "$l: the inner statement's answer is read, once";

  my ($got, @rows) = bounded(sub { $issue->('SELECT * FROM third')->get });
  ok $got, "$l: the connection takes the next statement" or diag $rows[0];
  is_deeply \@rows, [ [ 'row-for', 'third' ] ], "$l: ... which returns its own rows";

  $pool->release($pinned) if $pinned;
  is_deeply [ $pool->size, $pool->available, $storage->{_next_id} ], [ 1, 1, 1 ],
    "$l: the one connection is in the pool, and no other was ever opened";
  is watched(), 0, "$l: nothing is watched once all of it has settled";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 4. B, the everyday case: txn_do with a synchronous statement on its context.
#    Core runs the block from the callback of BEGIN's Future, so the block's
#    statement is section 3's inner one.
# ---------------------------------------------------------------------------

{
  my $l       = 'synchronous in txn_do';
  my $storage = new_storage(answers_after => 0.02);
  my $pool    = $storage->pool;

  my ($socket_quiet, $rows);
  my ($ok, @r) = bounded(sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      $socket_quiet = !readable($ctx->txn_conn->{r});
      $rows = $ctx->select('first', ['*'], {});
      return 'block-value';
    });
  });

  ok $socket_quiet,
    "$l: the socket was quiet when the block's statement went out -- BEGIN's "
    . 'answer had been read';
  is_deeply [ @{ $storage->{wire} }[ 0, 1 ] ], [ 'BEGIN', 'first' ],
    "$l: BEGIN, then the block's statement";

  TODO: {
    local $TODO = $todo_reentry;
    ok $ok, "$l: the block's statement returns and txn_do with it" or diag $r[0];
    is $r[0], 'block-value', "$l: ... with the block's value";
    is_deeply $rows, [ 'row-for', 'first' ], "$l: the statement returned its rows";
    is_deeply $storage->{wire}, [ 'BEGIN', 'first', 'COMMIT' ],
      "$l: and the transaction is committed";
  }

  my ($turned, $why) = turn();
  ok $turned, "$l: the loop turns on: nothing dies" or diag $why;
  is scalar @{ $storage->{wire} }, 3,
    "$l: the transaction was ended, by one statement";
  is_deeply $storage->{collected}, $storage->{wire},
    "$l: every answer was read -- the block's statement's too";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: its connection is back in the pool";

  my ($got, @next) = bounded(sub { $storage->_query_async('SELECT * FROM b', [])->get });
  ok $got, "$l: the pool serves the next query" or diag $next[0];
  is_deeply \@next, [ [ 'row-for', 'b' ] ], "$l: ... which returns its own rows";
  is watched(), 0, "$l: nothing is watched once all of it has settled";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 5. The way round B: the same block with its statement chained instead of
#    awaited. No loop is turned inside the read handler, and the transaction
#    commits. This is the control as well -- the claims of section 4 are
#    attainable on this mock and this loop.
# ---------------------------------------------------------------------------

{
  my $l       = 'chained in txn_do_async';
  my $storage = new_storage(answers_after => 0.02);
  my $pool    = $storage->pool;

  my $rows;
  my ($ok, @r) = bounded(sub {
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->select_async('first', ['*'], {})->then(sub {
        $rows = shift;
        return Future->done('block-value');
      });
    })->get;
  });

  ok $ok, "$l: the transaction resolves" or diag $r[0];
  is $r[0], 'block-value', "$l: ... with the block's value";
  is_deeply $rows, [ 'row-for', 'first' ], "$l: the statement returned its rows";
  is_deeply $storage->{wire}, [ 'BEGIN', 'first', 'COMMIT' ],
    "$l: and the transaction is committed";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: its connection is back in the pool";
  is watched(), 0, "$l: nothing is watched once all of it has settled";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 6. B needs no second poll on the handle, only a callback that turns the
#    loop while the handle turns readable again. The listen watch loop runs a
#    channel callback from the poll on the listen socket: one that blocks --
#    here on a synchronous query, on a pooled connection -- while the next
#    notification arrives has its blocking call killed the same way. The
#    callback dies with it; core reports that through on_listen_error, and
#    delivery goes on.
# ---------------------------------------------------------------------------

{
  my $l       = 'blocking in a channel callback';
  my $storage = new_storage(class => 'Listen34', answers_after => 0.02);
  my $pool    = $storage->pool;
  my @reported;
  $storage->on_listen_error(sub { push @reported, $_[1] });

  my (@delivered, $arriving, $rows);
  $storage->listen(jobs => sub {
    my ($channel, $payload) = @_;
    push @delivered, $payload;
    return unless $payload eq 'one';
    $arriving = Future::IO->sleep(0.005)          # the next one arrives ...
      ->on_done(sub { syswrite $storage->{notifier}, "two\n" });
    ($rows) = $storage->_query_async('SELECT * FROM job', [])->get;
  });                                             # ... while this one blocks

  turn();                                         # the watch's first drain
  is watched(), 1, "$l: the loop watches the listen socket";
  syswrite $storage->{notifier}, "one\n";
  my ($turned, $why) = drive(sub { @delivered == 2 && @{ $storage->{collected} } });
  ok $turned, "$l: the loop turns through all of it: nothing dies" or diag $why;

  TODO: {
    local $TODO = $todo_reentry;
    is_deeply $rows, [ 'row-for', 'job' ],
      "$l: the callback's synchronous query returns its rows";
    is_deeply \@reported, [], "$l: ... and the callback does not die"
      or diag $reported[0];
  }

  is_deeply \@delivered, [ 'one', 'two' ],
    "$l: both notifications are delivered, in order";
  is_deeply $storage->{collected}, ['job'],
    "$l: the callback's query is collected by the transport all the same";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and its connection is back in the pool";
  ok $storage->listen_alive, "$l: the listen connection is still up";

  # A on the way out: the stopped watch's poll is a cancelled one.
  $storage->unlisten('jobs');
  TODO: {
    local $TODO = $todo_watch;
    is watched(), 0, "$l: unlistened, the loop watches the listen socket no longer";
  }
  close delete $storage->{notifier};              # the server closes its end
  turn();
  is watched(), 0, "$l: nothing is watched once all of it has settled";
  quiet($l);
}

is_deeply \@warnings, [], 'nothing warned on the way out of a section';

done_testing;
