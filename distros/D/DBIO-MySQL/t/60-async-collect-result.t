use strict;
use warnings;

use Test::More;
use Scalar::Util 'weaken';

use DBIO::MySQL::Storage;

# OFFLINE regression test for karr k47 (ADR 0044, following dbio-async k11):
# the _collect_result seam of the future_io MySQL transport takes the
# CONNECTION AND NOTHING ELSE.
#
# WHAT THIS TEST PROVES, in one run of the real transport:
#
#   1. the re-poll path works with the post-k47 signature -- a result that is
#      not ready on the first readable event is re-collected by recursing as
#      _collect_result($conn), and the assembled result is unchanged;
#   2. every dispatch of the seam -- the first one from the base's
#      _collect_on_readable AND each re-poll recursion -- is handed exactly one
#      argument. Before k47 the recursion passed ($conn, $sql, $bind), which is
#      what this arity probe is here to keep from coming back;
#   3. the caller's bind arrayref is not retained past dispatch: not while the
#      query is in flight, not mid-re-poll, not after the future settles.
#
# WHAT RUNS FOR REAL: this dist's own _submit_query and _collect_result over
# DBIO::Async::Storage's _query_async / _query_async_pinned /
# _await_query_result / _collect_on_readable / _release_on_ready and a real
# DBIO::Async::Pool. No live MySQL -- the DBD handle is faked; everything
# asserted here is decided on this side of the wire.
#
# THE SUBSTITUTIONS, and why they are faithful:
#
#   * _await_readable -- a Future the TEST completes, instead of
#     Future::IO->poll on a real socket fd. It contributes to the reference
#     graph exactly what the production seam does (a PENDING Future holding the
#     ->then callback until the socket is readable) and it makes the re-poll
#     step-drivable; a real fd would be readable at once and there would be no
#     in-flight state to probe. Ported from dbio-async t/04-bind-release.t.
#     Nothing calls _conn_fileno / mysql_fd as a result.
#   * _create_pool_connection -- hands out the fake DBD handle instead of
#     DBI->connect. The pool, the readiness check and the release path stay real.
#
# _collect_result itself is NOT substituted: the probe records the arity of
# each dispatch and then runs the real one via SUPER.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    require Future;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- fake DBD primitives -----------------------------------------------------

{
  package MyTest::MySQL::CollectSth;
  sub new {
    my ($class, %args) = @_;
    return bless {
      NUM_OF_FIELDS  => 0,
      mysql_insertid => 0,
      rows           => [],
      result         => 0,
      not_ready      => 0,   # how many "still arriving" answers before ready
      ready_calls    => 0,
      %args,
    }, $class;
  }
  # An async execute() returns at once; the bind values are serialized onto the
  # wire there and then (the DBD query_params contract), so the fake keeps
  # copies of the VALUES and no reference to the caller's arrayref.
  sub execute {
    my $self = shift;
    push @{ $self->{wire} }, {
      sql  => $self->{sql},
      bind => [ map { defined $_ ? "$_" : undef } @_ ],
    };
    return 1;
  }
  sub mysql_async_ready {
    my ($self) = @_;
    return $self->{ready_calls}++ >= $self->{not_ready} ? 1 : 0;
  }
  sub more_results { 0 }   # one result set (karr k73)
  sub mysql_async_result { $_[0]->{result} }
  sub fetchall_arrayref  { [ map { [ @$_ ] } @{ $_[0]->{rows} } ] }
}

{
  package MyTest::MySQL::CollectDbh;
  sub new {
    my ($class, %args) = @_;
    # A DBD::mysql handle, and it says so the way a DBI handle does: the
    # transport picks the async binding by the connection's DBD (karr k60).
    return bless {
      Driver => { Name => 'mysql' },
      Active => 1, wire => [], prepare_attrs => [], sth_args => { %args },
    }, $class;
  }
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    push @{ $self->{prepare_attrs} }, $attrs;
    return MyTest::MySQL::CollectSth->new(
      %{ $self->{sth_args} }, sql => $sql, wire => $self->{wire},
    );
  }
  sub disconnect { $_[0]->{Active} = 0 }
  sub do { 1 }   # the session statement of every connection (karr k121)
}

# --- the probe transport -----------------------------------------------------

{
  package MyTest::MySQL::CollectProbe;
  use base 'DBIO::MySQL::Storage::Async';

  sub _await_readable {
    my ($self, $conn) = @_;
    $self->{polls}++;
    return $conn->{readable} = Future->new;
  }

  sub _create_pool_connection {
    my ($self) = @_;
    return { dbh => MyTest::MySQL::CollectDbh->new(%{ $self->{_sth_args} || {} }) };
  }
  sub _shutdown_pool_connection { }

  # Not a substitution: record how many arguments the seam is dispatched with,
  # then run the REAL DBIO::MySQL::Storage::Async::_collect_result.
  sub _collect_result {
    my $self = shift;
    push @{ $self->{collect_arity} }, scalar @_;
    return $self->SUPER::_collect_result(@_);
  }
}

sub new_storage {
  my (%sth_args) = @_;
  my $storage = MyTest::MySQL::CollectProbe->new(undef);
  $storage->{_sth_args}     = { %sth_args };
  $storage->{collect_arity} = [];
  $storage->{polls}         = 0;
  $storage->connect_info([{ host => 'localhost' }]);
  return $storage;
}

# "The socket became readable" -- resolve the pending _await_readable Future.
sub make_readable { $_[0]->{readable}->done }

# --- 1. the re-poll path, post-k47 signature ---------------------------------
#
# not_ready => 2: the result is still arriving on the first two readable
# events, so the real _collect_result re-polls twice before it finalises.

{
  my $storage = new_storage(
    NUM_OF_FIELDS => 2,
    rows          => [ [ 1, 'Miles' ], [ 2, 'Bill' ] ],
    not_ready     => 2,
  );

  my $f = $storage->_query_async(
    'SELECT `artistid`, `name` FROM `artist` WHERE `name` = ?', ['Miles'],
  );
  my $conn = $storage->pool->{_connections}[0];

  ok !$f->is_ready, 'the query is in flight (the result has not arrived yet)';
  is_deeply $conn->{dbh}{wire}[0],
    { sql => 'SELECT `artistid`, `name` FROM `artist` WHERE `name` = ?',
      bind => ['Miles'] },
    'the statement reached the wire with its bind values (serialized at dispatch)';

  make_readable($conn);
  ok !$f->is_ready, 'first readable event: the result is not complete, so it re-polls';
  is_deeply $storage->{collect_arity}, [1],
    'the first collect dispatch is handed the connection and NOTHING else';

  make_readable($conn);
  ok !$f->is_ready, 'second readable event: still arriving, re-polls again';

  make_readable($conn);
  ok $f->is_ready && !$f->is_failed, 'third readable event: the result is complete'
    or diag explain $f->failure;

  my @rows = $f->get;
  is_deeply \@rows, [ [ 1, 'Miles' ], [ 2, 'Bill' ] ],
    'a result spanning several reads is assembled into the cursor ->all shape '
  . '(ADR 0031 section 3) -- the re-poll recursion loses nothing';

  is_deeply $storage->{collect_arity}, [ 1, 1, 1 ],
    'EVERY dispatch -- the first one and both re-poll recursions -- carries one '
  . 'argument: _collect_result($conn) (ADR 0044, karr k11/k47)';
  is $storage->{polls}, 3,
    'one initial socket wait plus one per re-poll -- the recursion really went '
  . 'back through _await_readable';
}

# --- 2. bind lifetime ends at dispatch ---------------------------------------
#
# While the query is in flight -- and again mid-re-poll, with the collect
# callback live -- no callback may point at the caller's arrayref. A callback
# that closed over the binds would pin that capture alive through CvOUTSIDE and
# turn this red.
#
# Honest about what catches what: with the current dbio-async base the pre-k47
# recursion here was already handed undef for $sql/$bind, so it is the ARITY
# probe in section 1 that goes red on it, not this one. This section pins the
# property itself -- that no capture on THIS side of the seam holds the binds
# past dispatch -- which is what any caller-side re-introduction would break.

{
  my $storage = new_storage(
    NUM_OF_FIELDS => 1,
    rows          => [ ['Miles'] ],
    not_ready     => 1,
  );

  my $weak;
  my $f;
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async('SELECT `name` FROM `artist` WHERE `name` = ?', $bind);
  }
  # The issuing-scope strong lexical dies here.

  my $conn = $storage->pool->{_connections}[0];

  is $conn->{dbh}{wire}[0]{bind}[0], 'payload' x 64,
    'the bind values reached the wire';
  ok !defined $weak,
    'bind arrayref is freed WHILE THE QUERY IS IN FLIGHT (neither the dispatch '
  . 'closure nor the collect callback retains it)';

  make_readable($conn);
  ok !$f->is_ready, 'the result is still arriving -- a re-poll callback is live';
  ok !defined $weak,
    'bind arrayref is still freed MID-RE-POLL (the recursion closes over the '
  . 'connection only -- this is what carrying $sql/$bind would break)';

  make_readable($conn);
  $f->get;
  ok !defined $weak, 'bind arrayref is still freed after the future completes';
}

# --- 3. the pinned (transaction) path has the same contract ------------------
#
# _query_async_pinned goes straight to _await_query_result: no pool acquire,
# no _release_on_ready anywhere, so this isolates the collect half.

{
  my $storage = new_storage(not_ready => 1, result => 1);
  my $conn = $storage->pool->acquire->get;

  my $weak;
  my $f;
  {
    my $bind = [ 'txn-payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async_pinned(
      $conn, 'UPDATE `artist` SET `name` = ? WHERE `artistid` = 1', $bind,
    );
  }

  is $conn->{dbh}{wire}[0]{bind}[0], 'txn-payload' x 64,
    'pinned (txn) query: the bind values reached the wire';
  ok !defined $weak,
    'pinned (txn) query: bind arrayref is freed while the query is in flight';

  make_readable($conn);
  make_readable($conn);

  is $f->get, 1,
    'pinned (txn) query: a statement with no result set resolves to the '
  . 'affected-row count, through the re-poll';
  is_deeply $storage->{collect_arity}, [ 1, 1 ],
    'pinned (txn) query: both dispatches carry the connection alone';
  ok !defined $weak, 'pinned (txn) query: bind arrayref is freed after completion too';
}

# --- 4. the INSERT branch survives the re-poll too ---------------------------
#
# MySQL has no RETURNING, so _collect_result is where the auto-increment id is
# captured for _insert_returned_columns. It is read off the sth in the dispatch
# that finalises -- i.e. the last recursion, not the first.

{
  my $storage = new_storage(mysql_insertid => 7, result => 1, not_ready => 1);

  my $f = $storage->_query_async(
    'INSERT INTO `artist` (`name`) VALUES (?)', ['Miles'],
  );
  my $conn = $storage->pool->{_connections}[0];

  make_readable($conn);
  is $storage->last_insert_id, undef,
    'nothing is captured while the result is still arriving';

  make_readable($conn);
  is $f->get, 1, 'the INSERT resolves to its affected-row count';
  is $storage->last_insert_id, 7,
    'the auto-increment id is captured by the finalising re-poll dispatch';
  is_deeply $conn->{dbh}{prepare_attrs}[0], { async => 1 },
    '... over the DBD::mysql async binding this adapter carries';
}

# --- 5. the MariaDB convention subclass inherits the fixed seam --------------
#
# It overrides only the five DBD primitives (karr k28, this dist's ADR 0001). A second
# _collect_result there would be a place for the signature to drift back.

is( DBIO::MySQL::Storage::MariaDB::Async->can('_collect_result'),
    DBIO::MySQL::Storage::Async->can('_collect_result'),
  'the MariaDB adapter resolves to the very same _collect_result -- inherited, '
. 'not repeated' );
{
  no strict 'refs';
  ok !defined *{'DBIO::MySQL::Storage::MariaDB::Async::_collect_result'}{CODE},
    '... with nothing of its own in the subclass (nowhere to drift)';
}

done_testing;
