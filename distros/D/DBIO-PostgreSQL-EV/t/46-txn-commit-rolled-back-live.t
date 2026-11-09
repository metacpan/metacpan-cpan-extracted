use strict;
use warnings;
use Test::More;

# LIVE regression for karr k53: a transaction whose COMMIT PostgreSQL answers
# with ROLLBACK fails, instead of resolving as if it had committed.
#
# WHY: a statement that fails inside a transaction aborts it on the server, and
# PostgreSQL answers a later COMMIT there not with an error but with the command
# tag ROLLBACK. Core k236 makes txn_do_async wait for every statement its
# context handed out and roll back when one failed -- but a statement the
# context never saw is out of its reach: one inside a pipeline batch whose
# coderef swallows the error (the pipeline's own Future resolves), or one sent
# on the pinned connection past the context. For those, core asks the
# transport after COMMIT (DBIO::Storage::Async::_txn_commit_rolled_back), and
# this transport answers from EV::Pg's result_meta->{cmd_status}. Without that
# answer txn_do_async resolved with the coderef's value while nothing was
# committed -- the caller was told the rows were written.
#
# What this file claims:
#   1. a pipeline on the transaction whose batch swallows a statement error:
#      txn_do_async fails with core's "COMMIT was answered with ROLLBACK", and
#      the row the batch inserted before the failing statement is not there;
#   2. the same for a statement sent on the pinned connection past the context,
#      whose failure the coderef swallows;
#   3. control: the same shapes without a failing statement commit, and the
#      transaction resolves -- a COMMIT answered with COMMIT is taken at its
#      word;
#   4. a statement of the context that fails without being awaited, while the
#      coderef returns something else (core k236): the transaction fails with
#      that statement's own error -- core catches it before COMMIT, so the
#      COMMIT-answered error does not appear -- and nothing is committed;
#   5. after each, the connection is back in the pool of one, IDLE, on the same
#      backend -- the server ended the transaction, nothing was retired;
#   6. no callback of this transport dies out of EV::Pg.
#
# Before the fix 1 and 2 fail: txn_do_async resolves. 3 and 4 pass before and
# after (4 is core's). Every wait on the EV loop is bounded by a watchdog, and
# alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TABLE = 'dbio_karr53_commit_rb';
my $TAKEN = 'k53-taken';   # committed up front; inserting it again fails
my $ROLLED_BACK = qr/COMMIT was answered with ROLLBACK/;

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

# Wait for $f: (1, @result) once it is done, (0, $error) once it failed. A
# Future still pending after 10 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the loop a little, so anything that would fire late has fired before the
# pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Another session: the sync storage's own DBI connection, never the pool's.
sub other_session {
  my ($h) = @_;
  my $dbh = $h->sync_storage->dbh;
  $dbh->do(q{SET lock_timeout = '3s'});
  $dbh->do(q{SET statement_timeout = '10s'});
  return $dbh;
}

# A pool of one with its connection up, over a fresh table holding $TAKEN.
sub fresh {
  my $h   = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
  my $dbh = other_session($h);
  $dbh->do("DROP TABLE IF EXISTS $TABLE");
  $dbh->do("CREATE TABLE $TABLE (id serial PRIMARY KEY, name text NOT NULL UNIQUE)");
  $dbh->do("INSERT INTO $TABLE (name) VALUES (?)", undef, $TAKEN);
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  return ($h, $r[0][0]);
}

sub done_with {
  my ($h) = @_;
  $h->disconnect;
  other_session($h)->do("DROP TABLE IF EXISTS $TABLE");
  return;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# The names in the table besides $TAKEN, as another session sees them.
sub names {
  my ($h) = @_;
  return other_session($h)->selectcol_arrayref(
    "SELECT name FROM $TABLE WHERE name <> ? ORDER BY id", undef, $TAKEN,
  );
}

# Claim 5, and 6.
sub back_idle {
  my ($label, $h, $pid) = @_;
  settle();
  is $h->pool->size, 1, "$label: the pool still has its one connection";
  is $h->pool->available, 1, "$label: back in the pool";
  my $conn = $h->pool->{_connections}[0];
  is $conn && $conn->transaction_status, EV::Pg::PQTRANS_IDLE(),
    "$label: IDLE -- the transaction ended, nothing in flight";
  my ($same, @r) = wait_for($h->async->select_async(@PID));
  is $same && $r[0][0], $pid, "$label: the next call runs on the same backend";
  no_callback_died($label);
}

# A pipeline on the transaction: insert $name, then -- when $fail -- $TAKEN,
# whose failure the batch swallows, so the pipeline's Future resolves.
sub pipeline_txn {
  my ($h, $name, $fail) = @_;
  return $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub {
      my ($batch) = @_;
      my @stmts = ($batch->insert_async($TABLE, { name => $name }));
      push @stmts, $batch->insert_async($TABLE, { name => $TAKEN })
        ->else(sub { $batch->future_class->done('swallowed') })
        if $fail;
      return $batch->future_class->needs_all(@stmts);
    })->then(sub { 'coderef result' });
  });
}

# The context inserts $name, then -- when $fail -- $TAKEN goes on the pinned
# connection past the context, and the coderef swallows its failure.
sub past_context_txn {
  my ($h, $name, $fail) = @_;
  my $async = $h->async;
  return $async->txn_do_async(sub {
    my ($ctx) = @_;
    my $conn = $ctx->txn_conn;
    return $ctx->insert_async($TABLE, { name => $name })->then(sub {
      return 'coderef result' unless $fail;
      return $async->_query_async_pinned(
        $conn, "INSERT INTO $TABLE (name) VALUES (?)", [ $TAKEN ],
      )->else(sub { $async->future_class->done })->then(sub { 'coderef result' });
    });
  });
}

# --- 1. a pipeline batch swallows a statement error -----------------------------

{
  my $label = 'pipeline swallows an error';
  my ($h, $pid) = fresh();
  my ($ok, $err) = wait_for(pipeline_txn($h, 'k53-pipe', 1));
  ok !$ok, "$label: the transaction fails" or diag "it resolved with: $err";
  like $ok ? '' : "$err", $ROLLED_BACK, "$label: with core's COMMIT-answered error";
  is_deeply names($h), [], "$label: the row the batch inserted is not there";
  back_idle($label, $h, $pid);
  done_with($h);
}

# --- 2. a statement past the context, its failure swallowed ----------------------

{
  my $label = 'past the context';
  my ($h, $pid) = fresh();
  my ($ok, $err) = wait_for(past_context_txn($h, 'k53-past', 1));
  ok !$ok, "$label: the transaction fails" or diag "it resolved with: $err";
  like $ok ? '' : "$err", $ROLLED_BACK, "$label: with core's COMMIT-answered error";
  is_deeply names($h), [], "$label: the row the context inserted is not there";
  back_idle($label, $h, $pid);
  done_with($h);
}

# --- 3. control: the same shapes, nothing fails ----------------------------------

{
  my $label = 'control';
  my ($h, $pid) = fresh();
  my ($ok, @r) = wait_for(pipeline_txn($h, 'k53-pipe-ok', 0));
  ok $ok, "$label: a clean pipeline transaction commits" or diag "it failed: $r[0]";
  is $r[0], 'coderef result', "$label: and resolves with the coderef's result";
  ($ok, @r) = wait_for(past_context_txn($h, 'k53-past-ok', 0));
  ok $ok, "$label: a clean transaction of the second shape commits" or diag "it failed: $r[0]";
  is_deeply names($h), [qw( k53-pipe-ok k53-past-ok )], "$label: both rows are there";
  back_idle($label, $h, $pid);
  done_with($h);
}

# --- 4. an unawaited failed statement of the context (core k236) -------------------

{
  my $label = 'unawaited failure';
  my ($h, $pid) = fresh();
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->insert_async($TABLE, { name => 'k53-unawaited' });
    $ctx->insert_async($TABLE, { name => $TAKEN });   # fails; nothing awaits it
    return 'coderef result';
  }));
  ok !$ok, "$label: the transaction fails" or diag "it resolved with: $err";
  like $ok ? '' : "$err", qr/duplicate key value/, "$label: with the failed statement's own error";
  unlike $ok ? '' : "$err", $ROLLED_BACK, "$label: caught before COMMIT, not by its answer";
  is_deeply names($h), [], "$label: nothing is committed";
  back_idle($label, $h, $pid);
  done_with($h);
}

done_testing;
