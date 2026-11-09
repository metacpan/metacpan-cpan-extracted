use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k83: a statement PostgreSQL cancelled fails its Future
# on the future_io transport, instead of resolving as a success with no rows.
#
# WHY: PostgreSQL fails a cancelled statement (statement_timeout,
# pg_cancel_backend, a cancel request) with SQLSTATE 57014, and DBD::Pg's
# pg_result does NOT die on that one: it returns 0E0 and leaves err and errstr
# undef; only $dbh->state says 57014 (pg_db_result in dbdimp.c; measured on
# PostgreSQL 18.6 / DBD::Pg 3.20.2). The sync path raises. Before k83 the
# collector read only whether pg_result died, so a statement that timed out
# came back as an empty success.
#
# What this file claims:
#   1. a statement whose pg_result answers the way DBD::Pg answers a
#      cancellation (no die, 0E0, state 57014) fails its Future, with an error
#      naming SQLSTATE 57014;
#   2. the cancellation does not retire the connection: it goes back to the
#      pool and the next statement on it resolves with its rows;
#   3. no misfire: the state is read AFTER pg_result, which sets it for the
#      statement it collects. A statement that follows a cancelled one, or a
#      failed one, resolves -- including a row-less one (0E0, like the
#      cancelled statement's own answer) -- and so does the very first
#      statement on a handle whose state still says 57014 before pg_result
#      runs.
#
# THE FAKE models DBD::Pg as measured: pg_result sets the state from the
# result it reads, every time -- '' on success, 22012 (and a die) for division
# by zero, 57014 without a die for a cancellation. WHAT RUNS FOR REAL: the
# pool, the base's _query_async / _query_async_pinned, and this dist's
# _submit_query / _collect_result / _conn_error_is_fatal. THE SUBSTITUTIONS:
# _await_readable resolves at once, as in t/61, t/64 and t/71, and the
# borrow-time check _idle_connection_alive answers its default (t/75).

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use Future;

# --- the fake DBD::Pg ------------------------------------------------------------

{
  package FakeCancel::DBH;

  sub new {
    return bless { Active => 1, pg_socket => 42, sqlstate => '' }, shift;
  }

  sub prepare {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql }, 'FakeCancel::STH';
  }

  sub pg_ready { 1 }

  # What DBD::Pg's pg_db_result does with the one result of the statement in
  # flight: set the SQLSTATE from it, then die on an error -- except 57014.
  sub pg_result {
    my ($self) = @_;
    my $sth = delete $self->{in_flight} or die "no async query is running\n";
    my $sql = $sth->{sql};

    if ($sql =~ /pg_sleep/) {            # cancelled by statement_timeout
      $self->{sqlstate} = '57014';
      $sth->{NUM_OF_FIELDS} = undef;
      return '0E0';
    }
    if ($sql =~ m{1/0}) {
      $self->{sqlstate} = '22012';
      die "DBD::Pg::db pg_result failed: ERROR:  division by zero\n";
    }
    $self->{sqlstate} = '';
    if ($sql =~ /^SET/) {
      $sth->{NUM_OF_FIELDS} = undef;
      return '0E0';
    }
    $sth->{NUM_OF_FIELDS} = 1;
    return 1;
  }

  sub state { $_[0]{sqlstate} }

  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  package FakeCancel::STH;

  sub execute {
    my ($self) = @_;
    $self->{dbh}{in_flight} = $self;
    return 1;
  }

  sub fetchall_arrayref { [ [ 1 ] ] }
}

{
  no warnings 'redefine';
  *DBI::connect = sub { FakeCancel::DBH->new };
}

{
  package FakeCancel::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  sub _await_readable { Future->done }

  # The borrow-time check (karr k90) is held at the seam's default: the fake's
  # pg_socket is no real fd to select on, and the check would retire the
  # connection claim 2 wants reused. t/75 pins the check itself.
  sub _idle_connection_alive { 1 }
}

# --- helpers ---------------------------------------------------------------------

sub fresh {
  my $s = FakeCancel::Transport->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=cancel_test', 'u', 'p', { pool_size => 1 } ]);
  return $s;
}

sub outcome {
  my ($f) = @_;
  die 'the fake transport is synchronous; the Future should be ready'
    unless $f->is_ready;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

my $CANCELLED = qr/cancelled the statement \(SQLSTATE 57014 query_canceled/;

# ---------------------------------------------------------------------------
# 0. The fake answers a cancellation the way DBD::Pg does: no die, 0E0.
#    So whatever fails in claim 1, pg_result did not.
# ---------------------------------------------------------------------------

{
  my $dbh = FakeCancel::DBH->new;
  $dbh->prepare('SELECT pg_sleep(1)')->execute;
  my $rv = eval { $dbh->pg_result };
  is $rv, '0E0', 'fake: pg_result of a cancelled statement returns 0E0, no die';
  is $dbh->state, '57014', 'fake: ... and the state says 57014';
}

# ---------------------------------------------------------------------------
# 1 + 2. A cancelled statement fails; the connection stays in service.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($ok, @r) = outcome($s->_query_async('SELECT pg_sleep(1)', []));
  ok !$ok, 'a cancelled statement fails its Future'
    or diag 'it resolved with: ' . join ', ', map { $_ // 'undef' } @r;
  like $ok ? '' : "$r[0]", $CANCELLED, '... with an error naming SQLSTATE 57014';

  is $s->pool->size, 1, '... the connection is not retired';
  is $s->pool->available, 1, '... it is back in the pool, idle';

  ($ok, @r) = outcome($s->_query_async('SELECT 1', []));
  ok $ok, 'the next statement on that connection resolves' or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 1 ] ], '... with its rows';
}

# ---------------------------------------------------------------------------
# 3. No misfire on a successful statement.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $conn = $s->pool->acquire->get;

  my ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SELECT pg_sleep(1)', []));
  ok !$ok, 'pinned: the cancelled statement fails';

  ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SET statement_timeout = 0', []));
  ok $ok, 'a row-less statement right after a cancelled one resolves'
    or diag "it failed: $r[0]";
  is $r[0], '0E0', '... with pg_result\'s 0E0, the same answer the cancellation got';

  ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SELECT 1/0', []));
  ok !$ok, 'a failed statement fails';
  like $ok ? '' : "$r[0]", qr/division by zero/, '... with its own error';
  unlike $ok ? '' : "$r[0]", $CANCELLED, '... not the cancellation one';

  ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SELECT 1', []));
  ok $ok, 'a statement right after a failed one resolves' or diag "it failed: $r[0]";

  # The handle still says 57014 when the next statement goes out; pg_result
  # replaces it. A collector reading the state before pg_result would fail
  # this statement.
  $conn->{dbh}{sqlstate} = '57014';
  ($ok, @r) = outcome($s->_query_async_pinned($conn, 'SELECT 1', []));
  ok $ok, 'the state is read after pg_result: a 57014 left from before does not '
    . 'fail the statement' or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 1 ] ], '... which resolves with its rows';

  $s->pool->release($conn);
}

done_testing;
