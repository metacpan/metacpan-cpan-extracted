use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

BEGIN {
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
}

use DBIO::MySQL::EV::Storage;

# OFFLINE unit test for karr #27 / karr #28 (ADR 0044: async bind lifetime
# ends at dispatch).
#
# Contract under test: the caller's bind arrayref is NOT retained by the
# async path — neither by the Storage acquire-chain closure nor by the
# QueryExecutor — while a query is in flight, and nothing is retained after
# the future settles. The transport serializes bind values into its own wire
# buffer at dispatch (the EV::MariaDB contract); the Perl arrayref's life
# ends there.
#
# We drive the REAL Storage->_query_async against a fake pool whose acquire
# resolves to a fake EV::MariaDB-shaped connection whose execute DEFERS its
# callback, so a query genuinely stays in flight while we inspect weak refs —
# no real database needed. The weak-ref check is the load-bearing assertion:
# if any callback the transport holds was created inside the acquire-chain
# closure (or the executor's bind-clearing on_ready), it pins the caller's
# arrayref alive for the whole flight and the test goes red.

# A connection that records each in-flight query's deferred callback so the
# test can decide exactly when (and whether) it completes. Mirrors the
# EV::MariaDB prepare+execute shape: prepare returns a fake statement
# synchronously (the real EV::MariaDB does this in the next EV::run tick —
# we compress it because the QueryExecutor chains execute inside the
# prepare callback, so the deferral point IS the execute callback, not
# prepare's). execute SERIALIZES the bind values into its wire buffer and
# does NOT retain the caller's arrayref — the EV::MariaDB contract.
{
  package DeferConn;
  sub new { bless { inflight => [] }, $_[0] }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{inflight} }, { sql => $sql, cb => $cb };
  }
  sub prepare {
    my ($self, $sql, $cb) = @_;
    $cb->(bless { sql => $sql, conn => $self }, 'DeferStmt') if $cb;
  }
  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    my @wire = map { defined $_ ? "$_" : undef } @$bind;
    push @{ $self->{inflight} }, { sql => $stmt->{sql}, wire => \@wire, cb => $cb };
  }
  # The executor closes the statement after execute and settles the Future
  # from this callback (karr k45). Answered at once: the in-flight window
  # these tests sample is the execute's.
  sub close_stmt { my ($self, $stmt, $cb) = @_; $cb->(1) if $cb }
  # Settle the oldest in-flight query as a successful SELECT.
  sub complete_oldest {
    my $self = shift;
    my $q = shift @{ $self->{inflight} } or return;
    $q->{cb}->([[ 1 ]], undef);
    EV::run(EV::RUN_NOWAIT());   # the Future settles from the loop's idle watcher (karr k51)
  }
  # Settle the oldest in-flight query as an error.
  sub fail_oldest {
    my ($self, $err) = @_;
    my $q = shift @{ $self->{inflight} } or return;
    $q->{cb}->(undef, $err // 'boom');
    EV::run(EV::RUN_NOWAIT());   # the Future settles from the loop's idle watcher (karr k51)
  }
}

# Fake pool: acquire resolves to the given connection; release records.
{
  package FakePool;
  sub new { bless { conn => $_[1], released => 0 }, $_[0] }
  # With a conn_factory every acquire hands out a connection of its own, as the
  # real pool does for concurrent callers: statements with bind values on one
  # connection wait for each other (karr k81).
  sub acquire {
    my $self = shift;
    return Future->done($self->{conn}) unless $self->{conn_factory};
    my $conn = $self->{conn_factory}->();
    push @{ $self->{made} }, $conn;
    return Future->done($conn);
  }
  sub release { my $self = shift; $self->{released}++ }
  sub _lease  { 1 }   # the lease of a borrow (core k275, karr k91)
  sub shutdown { }   # Storage DESTROY calls ->pool->shutdown
  # The transport reports the connection of a failed statement here when it is
  # gone (karr k55). This double keeps no idle list to keep one off.
  sub _mysql_report_if_gone { }
}

# Build a real Storage whose pool is the fake. _query_async only needs
# ->pool->acquire, ->_executor (lazily built from {pool}), and _transform_sql.
sub make_storage {
  my ($conn) = @_;
  my $pool = FakePool->new($conn);
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->{pool} = $pool;
  return ($storage, $pool);
}

# --- single query: nothing held in flight, nothing after completion --------

{
  my $conn = DeferConn->new;
  my ($storage, $pool) = make_storage($conn);

  my @weak;
  my $f;
  {
    my $bind = ['alpha', 'beta', 'gamma'];
    push @weak, $bind;
    weaken($weak[-1]);
    $f = $storage->_query_async('SELECT * FROM t WHERE a = ? AND b = ? AND c = ?', $bind);
  }
  # $bind is out of scope; the only thing that can keep the arrayref alive is
  # retention by the async path.

  ok !$f->is_ready, 'future is pending while the query is in flight';
  ok !defined $weak[0], 'bind arrayref NOT retained while the query is in flight';

  # The transport still got the values: they were serialized at dispatch.
  is_deeply $conn->{inflight}[0]{wire}, ['alpha', 'beta', 'gamma'],
    'bind values serialized into the wire buffer at dispatch';

  $conn->complete_oldest;
  $f->get;

  ok !defined $weak[0], 'bind arrayref NOT retained after the future settles';
  is $pool->{released}, 1, 'pool connection released once the future settles';
}

# --- failure path also releases the binds ---------------------------------

{
  my $conn = DeferConn->new;
  my ($storage, $pool) = make_storage($conn);

  my @weak;
  my $f;
  {
    my $bind = ['x', 'y'];
    push @weak, $bind;
    weaken($weak[-1]);
    $f = $storage->_query_async('SELECT ? , ?', $bind);
  }

  ok !defined $weak[0], 'bind arrayref NOT retained while the query is in flight (failure path)';

  $conn->fail_oldest('explode');

  ok $f->is_failed, 'future fails when the connection reports an error';
  ok !defined $weak[0], 'bind arrayref NOT retained after the future fails';
  is $pool->{released}, 1, 'pool connection released even on the failure path';
}

# --- under load: N concurrent in-flight queries, no retention -------------
# Each query carries a distinct large bind payload. While all N are pending,
# NONE of the caller's arrayrefs may be retained; after all settle, still
# none.

{
  my $conn = DeferConn->new;
  my ($storage, $pool) = make_storage($conn);
  my $N = 32;

  my @weak;           # weak refs to the live bind arrayrefs, in issue order
  my @futures;
  for my $i (0 .. $N - 1) {
    my $bind = [ map { "q${i}_v${_}" . ('p' x 64) } 0 .. 9 ];
    push @weak, $bind;
    weaken($weak[-1]);
    push @futures, $storage->_query_async("SELECT * FROM t WHERE id = ? -- $i", $bind);
  }

  is scalar(@{ $conn->{inflight} }), $N, "all $N queries are in flight";
  ok !(grep { $_->is_ready } @futures), 'no future settled while all are in flight';

  my $held = grep { defined $_ } @weak;
  is $held, 0, 'no bind arrayref retained while all queries are in flight';

  # Drain in FIFO order.
  for my $i (0 .. $N - 1) {
    $conn->complete_oldest;
    ok $futures[$i]->is_ready, "future $i settled after its result arrived";
  }

  my $held_after = grep { defined $_ } @weak;
  is $held_after, 0, 'no bind arrayref retained after all futures settle';
  is $pool->{released}, $N, "pool released once per query ($N releases)";
}

# --- insert_async: row-data hashref not retained (karr #28) -----------------
# insert_async runs the INSERT + SELECT LAST_INSERT_ID() pair pinned on one
# connection (_run_crud_pinned). The row data is the %vals hashref (second
# argument), not a bind arrayref; ADR 0044 applies to it the same way. The
# pool-release on_ready is built in the named _release_on_ready (not inline
# in the acquire then-closure), and _run_crud_pinned takes a shallow copy of
# the row data at dispatch, so the caller's hashref lives only until dispatch.

# --- single insert: nothing held in flight, nothing after completion --------

{
  my $conn = DeferConn->new;
  my ($storage, $pool) = make_storage($conn);

  my @weak;
  my $f;
  {
    my $vals = { name => 'Tom' };
    push @weak, $vals;
    weaken($weak[-1]);
    $f = $storage->insert_async('artist', $vals);
  }
  # $vals is out of scope; the only thing that can keep the hashref alive is
  # retention by the async path.

  ok !$f->is_ready, 'insert future is pending while the INSERT is in flight';
  is scalar(@{ $conn->{inflight} }), 1, 'INSERT query is in flight';
  ok !defined $weak[0], 'row-data hashref NOT retained while the INSERT is in flight';

  # The transport still got the values: serialized into the wire buffer at dispatch.
  is_deeply $conn->{inflight}[0]{wire}, ['Tom'],
    'row values serialized into the wire buffer at dispatch';

  $conn->complete_oldest;   # INSERT completes -> SELECT LAST_INSERT_ID() issued
  is scalar(@{ $conn->{inflight} }), 1, 'SELECT LAST_INSERT_ID() is in flight';
  ok !defined $weak[0], 'row-data hashref NOT retained while the SELECT is in flight';

  $conn->complete_oldest;   # SELECT completes
  $f->get;

  ok !defined $weak[0], 'row-data hashref NOT retained after the insert settles';
  is $pool->{released}, 1, 'pool connection released once the insert settles';
}

# --- failure path also releases the row data --------------------------------

{
  my $conn = DeferConn->new;
  my ($storage, $pool) = make_storage($conn);

  my @weak;
  my $f;
  {
    my $vals = { name => 'X' };
    push @weak, $vals;
    weaken($weak[-1]);
    $f = $storage->insert_async('artist', $vals);
  }

  ok !defined $weak[0], 'row-data hashref NOT retained while the INSERT is in flight (failure path)';

  $conn->fail_oldest('explode');

  ok $f->is_failed, 'insert future fails when the INSERT reports an error';
  ok !defined $weak[0], 'row-data hashref NOT retained after the insert fails';
  is $pool->{released}, 1, 'pool connection released even on the failure path';
}

# --- under load: N concurrent inserts, no retention -------------------------
# Each insert issues INSERT + SELECT LAST_INSERT_ID() on the pinned
# connection. While all N INSERTs are pending, NONE of the caller's
# row-data hashrefs may be retained; while the SELECTs are in flight, still
# none; after all settle, still none.

{
  my ($storage, $pool) = make_storage(undef);
  $pool->{conn_factory} = sub { DeferConn->new };
  my $N = 16;
  my $in_flight = sub { my $n = 0; $n += @{ $_->{inflight} } for @{ $pool->{made} || [] }; $n };

  my @weak;           # weak refs to the live row-data hashrefs, in issue order
  my @futures;
  for my $i (0 .. $N - 1) {
    my $vals = { name => "artist_$i", active => $i };
    push @weak, $vals;
    weaken($weak[-1]);
    push @futures, $storage->insert_async('artist', $vals);
  }

  is $in_flight->(), $N, "all $N INSERTs are in flight";
  ok !(grep { $_->is_ready } @futures), 'no insert future settled while all are in flight';

  my $held = grep { defined $_ } @weak;
  is $held, 0, 'no row-data hashref retained while all INSERTs are in flight';

  # Drain: complete all INSERTs (each spawns its SELECT), then all SELECTs.
  $_->complete_oldest for @{ $pool->{made} };
  is $in_flight->(), $N, "all $N SELECT LAST_INSERT_ID() queries are in flight";

  my $held_mid = grep { defined $_ } @weak;
  is $held_mid, 0, 'no row-data hashref retained while the SELECTs are in flight';

  $_->complete_oldest for @{ $pool->{made} };
  $_->get for @futures;

  my $held_after = grep { defined $_ } @weak;
  is $held_after, 0, 'no row-data hashref retained after all inserts settle';
  is $pool->{released}, $N, "pool released once per insert ($N releases)";
}

done_testing;
