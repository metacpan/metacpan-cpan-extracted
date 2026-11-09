use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';

# OFFLINE regression test for karr k68 (ADR 0044, follow-on to dbio-async k11:
# the async bind lifetime ends at dispatch).
#
# THE PROPERTY: _collect_result on this transport takes the CONNECTION and
# nothing else, on the first call and on every re-poll of a result that spans
# several reads. Everything the collector needs is on $conn -- the dbh and the
# in-flight statement handle _submit_query stashed there. The SQL and the bind
# arrayref were consumed by the dispatch; a re-poll callback carrying them
# would pin the caller's binds alive for as long as the result keeps arriving,
# which is exactly the lifetime ADR 0044 ends.
#
# WHAT RUNS FOR REAL: _query_async_pinned, _await_query_result and
# _collect_on_readable from DBIO::Async::Storage, plus this dist's own
# _submit_query and _collect_result -- including the re-poll recursion, which
# is the line k68 changed.
#
# THE ONE SUBSTITUTION is _await_readable: instead of Future::IO->poll on a
# real socket fd it hands back a Future this test completes by hand. Faithful
# to what the production seam contributes to the reference graph (a PENDING
# Future holding the ->then callback while the socket is watched), and
# deterministic: Future::IO auto-routes to whichever Impl happens to be
# installed, so a real fd would exercise a different implementation per box.
# The DBD::Pg primitives the transport actually touches -- prepare/execute,
# pg_ready, pg_result, NUM_OF_FIELDS, Active -- are faked in full, and pg_ready
# is what drives the multi-read re-poll this test is about.

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async,
# which is only a recommends -- a minimal install may not have it. Load the
# adapter (which pulls the base) defensively so this offline suite skips
# cleanly instead of dying at compile time when dbio-async is absent.
BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use Future;

# --- Fake DBD::Pg primitives ------------------------------------------------

{
  package CollectWire::STH;
  sub new { my ($class, %args) = @_; return bless { %args }, $class }
  sub execute {
    my $self = shift;
    # Serialize onto the wire exactly as a DBD does at dispatch, keeping no
    # reference to the caller's arrayref.
    push @{ $self->{dbh}{wire} }, {
      sql  => $self->{sql},
      bind => [ map { defined $_ ? "$_" : undef } @_ ],
    };
    return 1;
  }
  sub fetchall_arrayref { return [ [ 1 ] ] }
}
{
  package CollectWire::DBH;
  sub new {
    my ($class, %args) = @_;
    # Active / pg_socket are read as hash keys by _conn_ready / _conn_fileno.
    return bless {
      wire        => [],
      Active      => 1,
      pg_socket   => -1,
      not_yet     => $args{not_yet} || 0,   # pg_ready answers 0 this many times
      ready_calls => 0,
    }, $class;
  }
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    return CollectWire::STH->new(dbh => $self, sql => $sql, NUM_OF_FIELDS => 1);
  }
  # "The result has not fully arrived yet" for the first $not_yet probes. This
  # is what sends _collect_result down its re-poll branch.
  sub pg_ready {
    my $self = shift;
    return ++$self->{ready_calls} > $self->{not_yet} ? 1 : 0;
  }
  sub pg_result { 1 }
  sub state { q{} }   # SQLSTATE, read after pg_result: none (karr k83)
}

our $NOT_YET = 0;
{
  package CollectWire::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  sub _create_pool_connection {
    return { dbh => CollectWire::DBH->new(not_yet => $NOT_YET) };
  }

  # The single transport substitution (see header).
  sub _await_readable {
    my ($self, $conn) = @_;
    return $conn->{readable} = Future->new;
  }

  # Record how many arguments EVERY _collect_result call was handed -- the
  # outer one from _collect_on_readable and each re-poll recursion -- then run
  # the shipped collector unchanged.
  sub _collect_result {
    my $self = shift;
    push @{ $self->{collect_arity} }, scalar @_;
    return $self->SUPER::_collect_result(@_);
  }
}

sub new_storage {
  my $storage = CollectWire::Transport->new(undef);
  $storage->connect_info([ 'dbi:Pg:dbname=collect_test', 'u', 'p', {} ]);
  return $storage;
}

# "The socket became readable" -- resolve the pending _await_readable Future.
sub make_readable {
  my ($conn) = @_;
  my $f = delete $conn->{readable} or die 'nothing is waiting on the socket';
  $f->done;
}

# -----------------------------------------------------------------------
# 1. A result that needs several reads: the re-poll carries the connection
#    and nothing else, and the caller's binds are gone from the first
#    readable event onwards.
# -----------------------------------------------------------------------
{
  local $NOT_YET = 2;             # pg_ready says "not complete" twice
  my $storage = new_storage;
  my $conn = $storage->pool->acquire->get;

  my ($weak, $f);
  {
    my $bind = [ 'payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async_pinned($conn, 'SELECT ?', $bind);
  }
  # The issuing-scope strong lexical dies here.

  is $conn->{dbh}{wire}[0]{sql}, 'SELECT $1',
    'the query was dispatched, with the PG placeholder shaping applied';
  is $conn->{dbh}{wire}[0]{bind}[0], 'payload' x 64,
    'the bind values reached the wire (serialized at dispatch)';
  ok !defined $weak,
    'bind arrayref is freed at dispatch, while the query is still in flight';

  make_readable($conn);
  ok !defined $weak,
    'still freed after the first readable event -- pg_ready said "not yet", '
    . 'so a re-poll callback is now pending';
  ok !$f->is_ready, '... and the query future is indeed still pending';

  make_readable($conn);
  ok !defined $weak, 'still freed across the second re-poll';

  make_readable($conn);           # pg_ready now says the result is complete
  ok $f->is_ready, 'the third readable event completed the query';
  is_deeply [ $f->get ], [ [ 1 ] ], 'the collected row came back';
  ok !defined $weak, 'bind arrayref is still freed after the future completes';

  is_deeply $storage->{collect_arity}, [ 1, 1, 1 ],
    '_collect_result was handed the connection and NOTHING else -- on the '
    . 'first call AND on both re-poll recursions (ADR 0044 seam signature: '
    . '_collect_result($conn))';
}

# -----------------------------------------------------------------------
# 2. Counter-check on the seam's own shape.
#
#    Section 1 samples the seam as the base calls it, and since dbio-async
#    k11 the base passes only $conn -- so on its own it cannot tell a
#    collector that IGNORES the SQL/bind from one that would still capture
#    them if it got them. This block hands the collector the pre-k11
#    argument list directly. A signature that binds $sql/$bind and closes
#    over them in the re-poll callback pins the arrayref for the whole
#    flight; the shipped one takes ($self, $conn), so the extra arguments
#    die with @_ when the call returns.
# -----------------------------------------------------------------------
{
  local $NOT_YET = 1;
  my $storage = new_storage;
  my $conn = $storage->pool->acquire->get;

  # Put a statement handle on $conn the way _submit_query would.
  $storage->_submit_query($conn, 'SELECT $1', [ 'dispatched' ]);

  my ($weak, $f);
  {
    my $bind = [ 'legacy' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_collect_result($conn, 'SELECT $1', $bind);
  }

  ok !$f->is_ready,
    'pg_ready said "not yet", so the collector is waiting on a re-poll';
  ok !defined $weak,
    'the re-poll callback does not retain the bind arrayref it was handed '
    . '-- it closes over the connection only';

  make_readable($conn);
  ok $f->is_ready, 'the re-poll completed the collection';
  ok !defined $weak, '... and retained nothing afterwards either';
}

done_testing;
