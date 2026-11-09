use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k86: a future_io transaction whose COMMIT PostgreSQL
# answers with ROLLBACK fails, instead of resolving as if it had committed.
#
# WHY: a statement that fails inside a transaction aborts it on the server,
# and PostgreSQL answers a later COMMIT there not with an error but with the
# command tag ROLLBACK. Core k236 makes txn_do_async wait for every statement
# its context handed out and roll back when one failed; a statement sent on
# the pinned connection PAST the context is out of its reach. For that one
# core asks the transport after COMMIT (DBIO::Storage::Async::
# _txn_commit_rolled_back). Its default answers "committed", so without this
# transport's answer the transaction resolved with the coderef's value while
# nothing was written.
#
# What this file claims:
#   1. the seam reads the COMMIT's command tag off the statement handle
#      _submit_query left on the connection: ROLLBACK -> true, COMMIT ->
#      false, no statement handle -> false (taken at its word);
#   2. through the real txn_do_async: a statement past the context fails and
#      the coderef swallows it -- the transaction fails with core's "COMMIT was
#      answered with ROLLBACK", COMMIT was the last thing sent (core sends no
#      ROLLBACK after it, the server ended the transaction), and the connection
#      is back in the pool, idle;
#   3. control: the same shape without the failing statement commits and
#      resolves with the coderef's value;
#   4. counter-check: with the seam answering core's default, the transaction
#      of claim 2 RESOLVES -- so claim 2 holds because of this transport's
#      answer, and the scenario really reaches COMMIT unseen by core.
#
# THE FAKE models what PostgreSQL does with a transaction (measured live on
# DBD::Pg 3.20.2, see the seam's POD): a failed statement inside BEGIN aborts
# it, a statement in an aborted transaction fails, and COMMIT there succeeds
# with pg_result 0E0 and the statement handle's pg_cmd_status 'ROLLBACK'.
# WHAT RUNS FOR REAL: the pool, core's txn_do_async and the transaction
# context, and this dist's _submit_query / _collect_result /
# _txn_commit_rolled_back. THE ONE SUBSTITUTION: _await_readable resolves at
# once, as in t/61 and t/64.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates _txn_commit_rolled_back (core k236)'
    unless DBIO::Storage::Async->can('_txn_commit_rolled_back');
}

use Future;

# --- the fake DBD::Pg ------------------------------------------------------------

our @WIRE;   # every statement sent, in order

{
  package FakeTxn::DBH;

  sub new {
    return bless { Active => 1, pg_socket => 42, txn => 'idle' }, shift;
  }

  sub prepare {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql }, 'FakeTxn::STH';
  }

  sub pg_ready { 1 }

  # What the server answers for the statement in flight; dies like DBD::Pg
  # (RaiseError) on an error. The command tag goes onto the statement handle.
  sub pg_result {
    my ($self) = @_;
    my $sth = delete $self->{in_flight} or die "no async query is running\n";
    my $sql = $sth->{sql};
    my $txn = $self->{txn};

    if ($sql eq 'BEGIN') {
      $self->{txn} = 'open';
      return $self->answer($sth, 'BEGIN', 0);
    }
    if ($sql eq 'COMMIT' || $sql eq 'ROLLBACK') {
      $self->{txn} = 'idle';
      return $self->answer($sth, $txn eq 'aborted' ? 'ROLLBACK' : $sql, 0);
    }
    if ($txn eq 'aborted') {
      $sth->{pg_cmd_status} = '';
      die "DBD::Pg::db pg_result failed: ERROR:  current transaction is aborted, "
        . "commands ignored until end of transaction block\n";
    }
    if ($sql =~ /FAIL/) {
      $self->{txn} = 'aborted' if $txn eq 'open';
      $sth->{pg_cmd_status} = '';
      die "DBD::Pg::db pg_result failed: ERROR:  division by zero\n";
    }
    return $self->answer($sth, 'SELECT 1', 1);
  }

  sub answer {
    my ($self, $sth, $tag, $fields) = @_;
    $sth->{pg_cmd_status} = $tag;
    $sth->{NUM_OF_FIELDS} = $fields;
    return $fields ? 1 : '0E0';
  }

  # SQLSTATE, read after pg_result (karr k83): none -- every failure above dies.
  sub state { q{} }

  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  package FakeTxn::STH;

  sub execute {
    my ($self) = @_;
    push @main::WIRE, $self->{sql};
    $self->{dbh}{in_flight} = $self;
    return 1;
  }

  sub fetchall_arrayref { [ [ 1 ] ] }
}

{
  no warnings 'redefine';
  *DBI::connect = sub { FakeTxn::DBH->new };
}

{
  package FakeTxn::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  sub _await_readable { Future->done }

  # The fake counts what goes on the wire; the reset between borrows
  # (DISCARD ALL, k154) is not what this file is about (t/195, t/196).
  sub _reset_pool_connection { Future->done }
}

{
  # Core's default answer, for the counter-check (claim 4).
  package FakeTxn::TakenAtItsWord;
  use base 'FakeTxn::Transport';

  sub _txn_commit_rolled_back { 0 }
}

# --- helpers ---------------------------------------------------------------------

sub fresh {
  my ($class) = @_;
  my $s = ($class // 'FakeTxn::Transport')->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=txn_test', 'u', 'p', { pool_size => 1 } ]);
  @WIRE = ();
  return $s;
}

# The context runs a statement; then -- when $fail -- a statement fails on the
# pinned connection past the context, and the coderef swallows its failure.
sub past_context_txn {
  my ($s, $fail) = @_;
  return $s->txn_do_async(sub {
    my ($ctx) = @_;
    my $conn = $ctx->txn_conn;
    return $ctx->select_async('t', ['x'], {})->then(sub {
      return 'coderef result' unless $fail;
      return $s->_query_async_pinned($conn, 'SELECT 1/0 -- FAIL', [])
        ->else(sub { Future->done })
        ->then(sub { 'coderef result' });
    });
  });
}

sub outcome {
  my ($f) = @_;
  die 'the fake transport is synchronous; the transaction should be ready'
    unless $f->is_ready;
  return $f->is_done ? (1, $f->get) : (0, scalar $f->failure);
}

my $ROLLED_BACK = qr/COMMIT was answered with ROLLBACK/;

# ---------------------------------------------------------------------------
# 1. The seam itself.
# ---------------------------------------------------------------------------

{
  my $s = 'DBIO::PostgreSQL::Storage::Async';
  ok $s->_txn_commit_rolled_back({ sth => { pg_cmd_status => 'ROLLBACK' } }, '0E0'),
    'a COMMIT answered with the tag ROLLBACK: rolled back';
  ok !$s->_txn_commit_rolled_back({ sth => { pg_cmd_status => 'COMMIT' } }, '0E0'),
    'a COMMIT answered with the tag COMMIT: committed';
  ok !$s->_txn_commit_rolled_back({ sth => undef }, '0E0'),
    'no statement handle on the connection: taken at its word';
  ok !$s->_txn_commit_rolled_back({ sth => { pg_cmd_status => undef } }),
    'no command tag on the handle: taken at its word';
}

# ---------------------------------------------------------------------------
# 2. A statement past the context fails, the coderef swallows it.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($ok, $err) = outcome(past_context_txn($s, 1));
  ok !$ok, 'past the context: the transaction fails' or diag "it resolved with: $err";
  like $ok ? '' : "$err", $ROLLED_BACK, '... with core\'s COMMIT-answered error';
  is_deeply \@WIRE, [ 'BEGIN', 'SELECT "x" FROM "t"', 'SELECT 1/0 -- FAIL', 'COMMIT' ],
    '... COMMIT went out and was the last statement: no ROLLBACK after it';
  is $s->pool->size, 1, '... the pool still has its one connection';
  is $s->pool->available, 1, '... back in the pool, idle';
}

# ---------------------------------------------------------------------------
# 3. Control: nothing fails.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($ok, @r) = outcome(past_context_txn($s, 0));
  ok $ok, 'control: a clean transaction commits' or diag "it failed: $r[0]";
  is $r[0], 'coderef result', '... and resolves with the coderef\'s value';
  is $WIRE[-1], 'COMMIT', '... after its COMMIT';
}

# ---------------------------------------------------------------------------
# 4. Counter-check: core's default answer lets claim 2's transaction resolve.
# ---------------------------------------------------------------------------

{
  my $s = fresh('FakeTxn::TakenAtItsWord');
  my ($ok, @r) = outcome(past_context_txn($s, 1));
  ok $ok, 'with core\'s default seam the same transaction resolves -- the '
    . 'failure is one core never saw, only the COMMIT\'s tag tells'
    or diag "it failed: $r[0]";
  is $WIRE[-1], 'COMMIT', '... after a COMMIT the server answered with ROLLBACK';
}

done_testing;
