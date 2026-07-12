use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::EV::QueryExecutor;

# OFFLINE unit test for karr #11 (N1: async bind-value leak).
#
# Contract under test: the async path must reuse the sync storage's
# bind-clearing contract — bind values are released once the query future
# settles (completion handler), but NOT on the issuing side, because
# clearing on issue would corrupt the binds of a still-pending query and
# break in-flight inspection.
#
# We drive the REAL QueryExecutor against a fake EV::MariaDB-shaped
# connection whose ->query DEFERS its callback, so a query genuinely stays
# in flight while we inspect it — no real database needed.

# A connection that records each in-flight query's deferred callback so the
# test can decide exactly when (and whether) it completes. Mirrors the
# EV::MariaDB prepare+execute shape: prepare returns a fake statement
# synchronously (the real EV::MariaDB does this in the next EV::run tick —
# we compress it because the QueryExecutor chains execute inside the
# prepare callback, so the deferral point IS the execute callback, not
# prepare's).
{
  package DeferConn;
  sub new { bless { inflight => [] }, $_[0] }
  sub query {
    my ($self, $sql, $cb) = @_;
    push @{ $self->{inflight} }, { sql => $sql, bind => undef, cb => $cb };
  }
  sub prepare {
    my ($self, $sql, $cb) = @_;
    $cb->(bless { sql => $sql, conn => $self }, 'DeferStmt') if $cb;
  }
  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    push @{ $self->{inflight} }, { sql => $stmt->{sql}, bind => $bind, cb => $cb };
  }
  # Settle the oldest in-flight query as a successful SELECT.
  sub complete_oldest {
    my $self = shift;
    my $q = shift @{ $self->{inflight} } or return;
    $q->{cb}->([[ 1 ]], undef);
  }
  # Settle the oldest in-flight query as an error.
  sub fail_oldest {
    my ($self, $err) = @_;
    my $q = shift @{ $self->{inflight} } or return;
    $q->{cb}->(undef, $err // 'boom');
  }
}

# Minimal pool stub — execute() only needs the executor's {pool} slot to
# exist; it never touches it for a concrete-conn execute.
my $executor = DBIO::MySQL::EV::QueryExecutor->new(pool => bless({}, 'FakePool'));

# --- in-flight inspection: bind survives until the future settles ---------

{
  my $conn = DeferConn->new;
  my @bind = ('alpha', 'beta', 'gamma');
  my $f = $executor->execute($conn, 'SELECT * FROM t WHERE a = ? AND b = ? AND c = ?', \@bind);

  ok !$f->is_ready, 'future is pending while the query is in flight';
  is_deeply \@bind, ['alpha', 'beta', 'gamma'],
    'bind values preserved while the future is pending (in-flight inspection intact)';

  $conn->complete_oldest;

  ok $f->is_ready, 'future settles when the connection delivers the result';
  is_deeply \@bind, [],
    'bind values released once the future is done (sync clearing contract met)';
}

# --- failure path also releases the binds ---------------------------------

{
  my $conn = DeferConn->new;
  my @bind = ('x', 'y');
  my $f = $executor->execute($conn, 'SELECT ? , ?', \@bind);
  $conn->fail_oldest('explode');

  ok $f->is_failed, 'future fails when the connection reports an error';
  is_deeply \@bind, [], 'bind values released even on the failure path';
}

# --- under load: N concurrent in-flight queries, no cross-contamination ----
# Each query carries a distinct large bind payload. Completing them one at a
# time must release ONLY the completed query's binds; the others, still
# pending, must keep their own payloads intact (no stale/concatenated binds).

{
  my $conn = DeferConn->new;
  my $N = 32;

  my @binds;          # the live bind arrayrefs, in issue order
  my @futures;
  for my $i (0 .. $N - 1) {
    # large-ish per-query payload, unique to this query
    my $bind = [ map { "q${i}_v${_}" . ('p' x 64) } 0 .. 9 ];
    push @binds, $bind;
    push @futures, $executor->execute($conn, "SELECT * FROM t WHERE id = ? -- $i", $bind);
  }

  is scalar(@{ $conn->{inflight} }), $N, "all $N queries are in flight";
  ok !(grep { $_->is_ready } @futures), 'no future settled while all are in flight';

  # Every pending query keeps its OWN full payload — nothing cleared early,
  # nothing concatenated from a sibling.
  my $all_intact = 1;
  for my $i (0 .. $N - 1) {
    $all_intact = 0 unless @{ $binds[$i] } == 10
      && $binds[$i][0] eq "q${i}_v0" . ('p' x 64);
  }
  ok $all_intact, 'each in-flight query retains its own intact bind payload';

  # Drain in FIFO order. After each completion, that query's binds are empty
  # and every still-pending query is untouched.
  for my $i (0 .. $N - 1) {
    $conn->complete_oldest;
    ok $futures[$i]->is_ready, "future $i settled after its result arrived";
    is_deeply $binds[$i], [], "completed query $i released its binds";

    my $pending_intact = 1;
    for my $j ($i + 1 .. $N - 1) {
      $pending_intact = 0 unless @{ $binds[$j] } == 10;
    }
    ok $pending_intact, "still-pending queries keep their binds after query $i completes"
      if $i < $N - 1;
  }

  # Quiescent: every bind arrayref is empty — RSS-equivalent of "returns to
  # baseline" at the Perl-data level (no per-pool retention).
  my $leaked = grep { @$_ } @binds;
  is $leaked, 0, 'after all futures settle, no query retains any bind values';
}

done_testing;
