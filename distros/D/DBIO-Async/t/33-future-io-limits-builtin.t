use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util qw( refaddr );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k37: what Future::IO's BUILT-IN implementation does
# when a poll is cancelled from inside the callback of another poll, as far as
# this transport reaches it. Its counterpart for the IO::Async implementation
# is t/34 -- one process loads one implementation, hence two files.
#
# THE UPSTREAM BEHAVIOUR (Future::IO 0.23, the newest release; _DefaultImpl,
# _await_once). One round of the built-in loop walks its list of pollers with
# the list's length taken up front, and resolves each ready one from inside
# the walk. A poll cancelled by a callback that runs there is spliced out of
# the list by its on_cancel. When that poll sat BEHIND the one being resolved,
# the walk goes on to an index that no longer exists, and the round dies:
#
#   Can't call method "fh" on an undefined value at Future/IO.pm line 890.
#
# The death comes out of whatever drove the loop -- the ->get of a Future that
# is by then already done.
#
# HOW A CALLER OF THIS TRANSPORT GETS THERE. Every statement in flight is a
# poll on its connection, and letting go of one (_let_go) is a cancel of that
# poll. So: Future->wait_any over two pooled queries, where the one issued
# first wins and the loser is cancelled from the winner's callback (section
# 1); a disconnect, or a pool shutdown, from a query's callback while another
# statement is in flight (section 3) -- any cancel made there. Confirmed live
# on PostgreSQL for the first.
#
# WHY TODO, AND WHY ON THE TARGET. What is asserted under TODO is what a caller
# is owed -- the round survives, ->get returns the winner's rows -- and today
# that is red. Nothing here asserts the death itself as a passing test: this
# file is run by everybody who installs the dist, and an assertion that
# upstream's bug is still there would fail every install on the day upstream
# fixes it. A TODO turns up as "TODO passed" in the harness summary instead --
# visible to whoever runs the suite, fatal to nobody -- and then the TODO
# blocks come off. What the transport owes whatever the loop does is asserted
# hard, beside them: the winner's statement collected and its connection
# handed back, the loser's connection retired and its late answer unread, the
# pool serving the next query.
#
# DECIDED 2026-10-27: reported upstream, no workaround here. The defect is
# Future::IO's and reaches everyone who cancels a poll from a poll callback; it
# is not a fault of this transport. The report, a patch and new tests for
# Future-IO lie in maint/upstream/ (Future-IO-0.23-poll-round.patch), handed to
# the author (Paul Evans, PEVANS) on that day. With the patch applied every
# TODO in this file passes. When a Future::IO release makes them pass: remove
# the TODO blocks and require that release in cpanfile. Nothing in lib/ works
# around it.
#
# WHAT IS REAL. The whole transport -- _query_async, the flight register,
# _await_query_result, the Future::IO poll on the dup(2) of a real fd, _let_go,
# the release and the dead-connection report -- its pool(), the real
# DBIO::Async::Pool, core's acquire, release, shutdown and disconnect,
# Future.pm and Future::IO's built-in implementation. Section 0 pins that.
#
# THE MOCK SERVER is t/31's: a connection is the read end of a pipe, a
# statement is in flight until the test has the server answer, and a
# connection keeps one statement slot, freed only by reading the result.
#
# THE LOOP'S LIST IS GLOBAL. The built-in implementation keeps one list of
# pollers for the process, so a section that left something on it would hand
# its damage to the next. Every section has a storage of its own and ends by
# asking the loop whether it watches nothing (loop_is_idle); the death itself
# leaves the list empty -- both polls are off it before the walk trips.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };
$SIG{PIPE} = 'IGNORE';

{
  package Race33;
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
    return { id => $id, r => $r };
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
    push @{ $self->{collected} }, [ $conn->{in_flight}, $conn->{id} ];
    die "Race33: connection $conn->{id} is closed\n" if $conn->{closed};
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    return Future->done([ 'row-for', $label, $conn->{id} ]);
  }
}

sub new_storage {
  my $storage = Race33->new(undef);
  $storage->{_next_id} = 0;
  $storage->{server}   = {};
  $storage->{$_} = [] for qw(closed wire collected);
  $storage->connect_info([{ host => 'localhost', pool_size => 2 }]);
  return $storage;
}

sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# The server answers the statement in flight on a connection.
sub answer { my ($server) = @_; syswrite $server, 'R' if $server; return }

# Run $code with a deadline. The built-in loop reads blocking where it
# presumes a poll ready, so a mistake here hangs rather than fails.
sub bounded {
  my ($code) = @_;
  my @result;
  my $ok = eval {
    local $SIG{ALRM} = sub { die "timed out\n" };
    alarm 10;
    @result = $code->();
    alarm 0;
    1;
  };
  my $error = $@;
  alarm 0;
  return $ok ? (1, @result) : (0, $error);
}

# Turn the built-in loop. The zero timer makes it select() for real instead of
# presuming a lone read poll ready (Future::IO 0.23, _await_once), so a poll
# resolves here only when its socket really is readable.
sub turn { return bounded(sub { Future::IO->sleep(0)->get for 1 .. 3; 1 }) }

# Is the built-in loop watching nothing -- no poll and no timer? One round of
# it refuses to run when it has nothing to wait for, and that refusal is the
# answer (t/27, t/31).
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

sub quiet {
  my ($l) = @_;
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
  return;
}

# What the transport owes after a race between two pooled queries, whatever
# became of the loop's round: asserted hard in sections 1 and 2 alike.
sub transport_kept_its_part {
  my ($l, $storage, %is) = @_;
  my $pool = $storage->pool;
  my ($won, $lost) = @is{qw( winner loser )};

  is_deeply outcome($is{winner_future}), [ [ 'row-for', $won->[0], $won->[1] ] ],
    "$l: the winner's own Future is done, with its rows";
  is outcome($is{loser_future}), 'cancelled', "$l: the loser is cancelled";
  is_deeply $storage->{collected}, [$won],
    "$l: the winner's answer was read, and nothing else";
  is_deeply $storage->{closed}, [ $lost->[1] ],
    "$l: the loser's connection is retired -- its statement is still on the server";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the winner's is back in the pool";

  answer($storage->{server}{ $lost->[1] });     # the loser's answer, late
  my ($turned, $why) = turn();
  ok $turned, "$l: the loser's answer arrives late and the loop turns: nothing dies"
    or diag $why;
  is_deeply $storage->{collected}, [$won], "$l: ... and it is not read";

  my $next = $storage->_query_async('SELECT * FROM next', []);
  is_deeply $storage->{wire}[-1], [ 'next', $won->[1] ],
    "$l: the next query gets the winner's connection";
  answer($storage->{server}{ $won->[1] });
  my ($got, @rows) = bounded(sub { $next->get });
  ok $got, "$l: ... and is answered" or diag $rows[0];
  is_deeply \@rows, [ [ 'row-for', 'next', $won->[1] ] ], "$l: ... with its own rows";

  ok loop_is_idle(), "$l: the loop is left watching nothing";
  quiet($l);
  return;
}

# ---------------------------------------------------------------------------
# 0. The guards: the built-in implementation polls, the transport itself runs.
# ---------------------------------------------------------------------------

ok !$INC{'Future/IO/Impl/IOAsync.pm'},
  'no other Future::IO implementation is loaded in this process';
for my $method (qw( _query_async _await_query_result _await_readable
                    _conn_poll_fh _let_go _abandon_on_cancel _release_on_ready
                    _abandon_flights_on pool )) {
  is refaddr(Race33->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}

# ---------------------------------------------------------------------------
# 1. karr k37: Future->wait_any over two pooled queries, the one issued first
#    wins. Its poll is in front of the loser's in the loop's list, and the
#    loser's is cancelled from inside the winner's callback.
# ---------------------------------------------------------------------------

{
  my $l       = 'wait_any, the loser behind the winner';
  my $storage = new_storage();

  my $first  = $storage->_query_async('SELECT * FROM first', []);
  my $second = $storage->_query_async('SELECT * FROM second', []);
  is_deeply $storage->{wire}, [ [ 'first', 1 ], [ 'second', 2 ] ],
    "$l: both are in flight, each on a connection of its own";
  is $Future::IO::IMPL, 'Future::IO::_DefaultImpl',
    "$l: it is the built-in implementation that polls";

  answer($storage->{server}{1});
  my $any = Future->wait_any($first, $second);
  my ($ok, @r) = bounded(sub { $any->get });

  TODO: {
    local $TODO = 'UPSTREAM defect of Future::IO 0.23 (built-in '
                . 'implementation), not of DBIO: a poll cancelled from a poll '
                . 'callback, behind the resolving one, kills the round. '
                . 'Reported with patch and tests 2026-10-27, see '
                . 'maint/upstream/. Passing on a new Future::IO: drop this '
                . 'TODO, require that release in cpanfile';
    ok $ok, "$l: the round survives -- ->get on the race returns" or diag $r[0];
    is_deeply \@r, [ [ 'row-for', 'first', 1 ] ],
      "$l: ... with the winner's rows";
  }

  is_deeply outcome($any), [ [ 'row-for', 'first', 1 ] ],
    "$l: the race itself is decided, whatever ->get did -- asked again, it "
    . "hands out the winner's rows";
  transport_kept_its_part($l, $storage,
    winner => [ 'first', 1 ],  winner_future => $first,
    loser  => [ 'second', 2 ], loser_future  => $second,
  );
}

# ---------------------------------------------------------------------------
# 2. The same race with the loser IN FRONT: no death. This is the control --
#    the claims of section 1 are attainable on this mock, so its TODO is about
#    the order in the loop's list and nothing else. The second query can only
#    win while the loop really selects, which the built-in one does once it
#    has a timer; left to presume, it would take the first poll for ready and
#    read its quiet socket blocking.
# ---------------------------------------------------------------------------

{
  my $l       = 'wait_any, the loser in front';
  my $storage = new_storage();
  my $timer   = Future::IO->sleep(60);      # makes every round select()

  my $first  = $storage->_query_async('SELECT * FROM first', []);
  my $second = $storage->_query_async('SELECT * FROM second', []);

  answer($storage->{server}{2});
  my $any = Future->wait_any($first, $second);
  my ($ok, @r) = bounded(sub { $any->get });
  $timer->cancel;

  ok $ok, "$l: the round survives -- ->get on the race returns" or diag $r[0];
  is_deeply \@r, [ [ 'row-for', 'second', 2 ] ], "$l: ... with the winner's rows";
  transport_kept_its_part($l, $storage,
    winner => [ 'second', 2 ], winner_future => $second,
    loser  => [ 'first', 1 ],  loser_future  => $first,
  );
}

# ---------------------------------------------------------------------------
# 3. karr k37, the other way in: the storage is disconnected from a query's
#    callback while a statement issued after it is in flight. The teardown
#    lets go of that statement's poll (ADR 0007) -- a cancel from inside a
#    poll callback, behind the resolving one.
# ---------------------------------------------------------------------------

{
  my $l       = 'disconnect in a callback';
  my $storage = new_storage();

  my $first  = $storage->_query_async('SELECT * FROM first', []);
  my $second = $storage->_query_async('SELECT * FROM second', []);
  my $torn_down;
  $first->on_done(sub { $torn_down = eval { $storage->disconnect; 1 } ? 'done' : $@ });

  answer($storage->{server}{1});
  my ($ok, @r) = bounded(sub { $first->get });

  TODO: {
    local $TODO = 'UPSTREAM defect of Future::IO 0.23 (built-in '
                . 'implementation), not of DBIO: a poll cancelled from a poll '
                . 'callback, behind the resolving one, kills the round. '
                . 'Reported with patch and tests 2026-10-27, see '
                . 'maint/upstream/. Passing on a new Future::IO: drop this '
                . 'TODO, require that release in cpanfile';
    ok $ok, "$l: the round survives -- ->get on the first query returns"
      or diag $r[0];
    is_deeply \@r, [ [ 'row-for', 'first', 1 ] ], "$l: ... with its rows";
  }

  is $torn_down, 'done', "$l: the disconnect itself does not die";
  is_deeply outcome($first), [ [ 'row-for', 'first', 1 ] ],
    "$l: the first query's own Future is done, with its rows";
  like outcome($second), qr/^failed: Statement abandoned in flight: /,
    "$l: the statement in flight failed at the teardown, saying what happened";
  is_deeply [ sort @{ $storage->{closed} } ], [ 1, 2 ],
    "$l: both connections are closed, once each";

  answer($storage->{server}{2});                # the abandoned one's answer
  my ($turned, $why) = turn();
  ok $turned, "$l: its answer arrives late and the loop turns: nothing dies"
    or diag $why;
  is_deeply $storage->{collected}, [ [ 'first', 1 ] ],
    "$l: ... and nothing is read off the closed connection";
  ok loop_is_idle(), "$l: the loop is left watching nothing";
  quiet($l);
}

is_deeply \@warnings, [], 'nothing warned on the way out of a section';

done_testing;
