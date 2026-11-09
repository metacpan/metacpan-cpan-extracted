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
use Scalar::Util qw( refaddr );
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k46 and k39 on a real event loop: the statements this
# transport holds in flight (ADR 0007), driven by IO::Async through
# Future::IO::Impl::IOAsync instead of Future::IO's built-in implementation.
#
# WHY A SECOND IMPLEMENTATION. t/31 and t/30 pin both cards on the built-in
# one, whose poll Futures are its own class and whose cancel drops the watch
# at once. Here the poll Future is an IO::Async::Future made by the loop, and
# the implementation (0.805) does nothing when one is cancelled: the watch
# stays until the socket next turns readable. Both differences sit exactly
# where the two cards do -- the class of the Future a caller gets and ->get on
# it, and what a late answer finds after a teardown -- and k46 was confirmed
# live on this implementation as well as on the built-in one.
#
# What is NOT claimed here is that the loop stops watching at the teardown:
# on this implementation it does not, until the socket stirs (karr k38) --
# t/34 holds that as it stands, and what else this implementation does with
# the transport's polls. What is claimed is what the transport owes whatever
# the implementation does with a cancelled poll: the caller hears at the
# teardown, and the answer that comes late is not read, kills nothing and
# warns nothing.
#
# WHAT IS REAL. The whole transport, its pool(), the real DBIO::Async::Pool,
# core's acquire, release, shutdown and disconnect, Future.pm, IO::Async.
#
# THE MOCK SERVER is t/31's: a connection is the read end of a pipe, a
# statement is in flight until the test has the server answer, and a
# connection keeps one statement slot, freed only by reading the result.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };
$SIG{PIPE} = 'IGNORE';

{
  package Loop32;
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
    push @{ $self->{collected} },
      [ $conn->{in_flight}, $conn->{id}, $conn->{closed} ? 'closed' : 'open' ];
    die "Loop32: connection $conn->{id} is closed\n" if $conn->{closed};
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    return Future->done([ 'row-for', $label, $conn->{id} ]);
  }
}

sub new_storage {
  my $storage = Loop32->new(undef);
  $storage->{_next_id} = 0;
  $storage->{server}   = {};
  $storage->{$_} = [] for qw(closed wire collected);
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

sub label { my ($sql) = @_; return $sql =~ /\bFROM (\w+)/ ? $1 : $sql }

# The server answers the statement in flight on a connection. A connection
# that was never opened has no server; the assertions that follow say so.
sub answer { my ($server) = @_; syswrite $server, 'R' if $server; return }

# Turn the IO::Async loop: ->get on a timer of its own runs it, and whatever
# socket is readable meanwhile is served.
sub turn { Future::IO->sleep(0.01)->get for 1 .. 3; return }

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

# ---------------------------------------------------------------------------
# 0. The guards: it is IO::Async that polls, and the transport that runs.
# ---------------------------------------------------------------------------

is $Future::IO::IMPL, 'Future::IO::Impl::IOAsync',
  'Future::IO runs on its IO::Async implementation';
for my $method (qw( _query_async _await_query_result _await_readable
                    _conn_poll_fh _release_on_ready pool )) {
  is refaddr(Loop32->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}

# ---------------------------------------------------------------------------
# 1. A caller that keeps its Future: it is of the loop's own class, so ->get
#    on it runs the loop until the answer is in.
# ---------------------------------------------------------------------------

{
  my $l       = 'kept';
  my $storage = new_storage();

  my $f = $storage->_query_async('SELECT * FROM a', []);
  isa_ok $f, 'IO::Async::Future', "$l: the caller's Future";
  answer($storage->{server}{1});
  is_deeply [ $f->get ], [ [ 'row-for', 'a', 1 ] ],
    "$l: ->get on it drives IO::Async to the answer";
  is $storage->pool->available, 1, "$l: the connection is back in the pool";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 2. The k46 case: a pooled query in void context, pool of one.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped in flight';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  $storage->_query_async('SELECT * FROM a', []);       # void context
  is_deeply $storage->{wire}, [ [ 'a', 1 ] ], "$l: the statement is on the wire";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'a', 1, 'open' ] ],
    "$l: the answer is read, though nobody holds the Future";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the connection is handed back";

  my $next = $storage->_query_async('SELECT * FROM b', []);
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: the next query gets that connection at once";
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($next), [ [ 'row-for', 'b', 1 ] ], "$l: ... and resolves";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 3. Dropped while it still waits for the pool: dispatched when the slot
#    frees, collected, its connection handed back.
# ---------------------------------------------------------------------------

{
  my $l       = 'dropped while queued';
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $fa = $storage->_query_async('SELECT * FROM a', []);
  $storage->_query_async('SELECT * FROM b', []);       # dropped, queued
  answer($storage->{server}{1});
  turn();
  is_deeply outcome($fa), [ [ 'row-for', 'a', 1 ] ], "$l: a resolves";
  is_deeply $storage->{wire}, [ [ 'a', 1 ], [ 'b', 1 ] ],
    "$l: the dropped b is dispatched once the slot is free";

  answer($storage->{server}{1});
  turn();
  is_deeply $storage->{collected}, [ [ 'a', 1, 'open' ], [ 'b', 1, 'open' ] ],
    "$l: b's answer is read";
  is_deeply [ $pool->size, $pool->available ], [ 1, 1 ],
    "$l: ... and the connection handed back";
  quiet($l);
}

# ---------------------------------------------------------------------------
# 4. The k39 case: torn down with a statement in flight, by disconnect and by
#    the pool's own shutdown. The caller hears at the teardown. This
#    implementation keeps watching the socket; the answer that then comes is
#    not read off the closed connection, kills nothing and warns nothing.
# ---------------------------------------------------------------------------

for my $via (qw( disconnect shutdown )) {
  my $l       = "torn down, $via";
  my $storage = new_storage();
  my $pool    = $storage->pool;

  my $f = $storage->_query_async('SELECT * FROM a', []);
  is outcome($f), 'still pending', "$l: the statement is in flight";

  ok eval { $via eq 'disconnect' ? $storage->disconnect : $pool->shutdown; 1 },
    "$l: the teardown does not die" or diag $@;
  like outcome($f),
    qr/^failed: Statement abandoned in flight: .*connection was closed.*whether it took effect is unknown/s,
    "$l: the statement in flight fails at the teardown, saying what happened";
  my $failed_with = outcome($f);
  is_deeply $storage->{closed}, [1], "$l: its connection is closed, once";

  answer($storage->{server}{1});
  ok eval { turn(); 1 }, "$l: the answer arrives late and the loop turns: nothing dies"
    or diag $@;
  is outcome($f), $failed_with, "$l: the late answer changes nothing";
  is_deeply $storage->{collected}, [],
    "$l: nothing was read off the closed connection";
  my $now = $storage->{pool};
  ok !defined $now || refaddr($now) == refaddr($pool),
    "$l: the torn down storage got no new pool";
  is_deeply $storage->{closed}, [1], "$l: the connection was not closed again";
  quiet($l);
}

is_deeply \@warnings, [], 'nothing warned on the way out of a section';

done_testing;
