use strict;
use warnings;
use Test::More;

# LIVE, karr k73 (e): a pipeline whose coderef dies with a statement of the
# batch in flight, on a pooled connection and on a transaction's, against a
# real PostgreSQL. The live half of t/58-pipeline-seams-mock.t, claims 3a and 5.
#
# WHY: core leaves pipeline mode through _pipeline_exit on every way out of the
# bracket, and what it does with the connection hangs on whether that seam
# dies: released when it returns, RETIRED when it dies -- a connection still in
# pipeline mode would break its next borrower, who could neither run a plain
# statement on it nor know why. t/58 claims that a coderef dying after
# $batch->insert_async takes the second way, and rests it on one thing read
# from libpq's documentation and never seen for this case: that EV::Pg refuses
# exit_pipeline while a result is still due. If a real libpq let that exit
# through, core would release the connection with the batch's statement still
# in flight on it, and the next caller would get that statement's result, or
# none. And what became of the statement -- and, in a transaction, of
# everything the transaction had written -- only a server says.
#
# What this file claims, with the server asked from a connection of its own:
#   1. the control: a batch that reaches its sync point leaves pipeline mode --
#      the exit is not refused -- and keeps its connection: the next call runs
#      on the same backend;
#   2. pooled (k73 e): the coderef dies after $batch->insert_async. The
#      statement is in flight, in pipeline mode, as it dies; EV::Pg REFUSES the
#      exit ("cannot exit pipeline mode while busy"); the pipeline fails with
#      the coderef's error, not with the exit's; the statement in flight fails
#      as its connection is closed; the connection is retired, not released --
#      closed, out of the pool, its backend GONE from the server; nothing of
#      the batch is committed; the next call completes on a fresh backend, a
#      plain statement, and the server has that one backend for the pool;
#   3. in a transaction, $ctx->pipeline (k73 e): the same, and the transaction
#      fails with the error that ended the batch; its connection is retired,
#      its backend gone; COMMIT never took effect -- neither the batch's row
#      nor the row the transaction wrote before the batch is there;
#   4. no callback of this transport dies out of EV::Pg, and nothing warns.
#
# The exit is watched, not replaced: _pipeline_exit is wrapped to note whether
# it returned or what it died with, and calls the real one.
#
# NOTED, not claimed: how many INSERTs the server ran before the connection
# closed, read from the table's sequence, which a rollback does not turn back.
# The batch has no sync point when its coderef dies; whether libpq had sent the
# statement by then is its own business.
#
# The text of the refusal is libpq's and takes its messages to be English.
# Every wait on the EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::EV::Storage;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TAG   = "dbio_k73_pipeline_$$";
my $TABLE = 'dbio_karr73_pipeline';

my $REFUSED = qr/cannot exit pipeline mode while busy/;

# The server's view, from a connection that belongs to no pool.
# A server that is not there fails the file here, with a plan (karr k77).
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
$ENV{PGAPPNAME} = $TAG;   # every connection a harness opens from here on

$observer->do('SET client_min_messages = warning');
$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->do("CREATE TABLE $TABLE (id serial PRIMARY KEY, name text NOT NULL)");
$observer->do("INSERT INTO $TABLE (name) VALUES ('kept')");

END {
  if ($observer) {
    local $@;
    eval { $observer->do("DROP TABLE IF EXISTS $TABLE") };
  }
}

# Every _pipeline_exit of this process: 'left' when it returned, else what it
# died with. The real seam runs, and its death goes on to core.
my @EXITS;
{
  my $real = DBIO::PostgreSQL::EV::Storage->can('_pipeline_exit');
  no warnings 'redefine';
  *DBIO::PostgreSQL::EV::Storage::_pipeline_exit = sub {
    my @args = @_;
    my $left = eval { $real->(@args); 1 };
    my $died = $@;
    push @EXITS, $left ? 'left' : "$died";
    die $died unless $left;
    return;
  };
}

# A SELECT of SQL expressions through the async API, as a consumer writes it:
# one row of pg_namespace, each expression as literal SQL.
sub exprs {
  my @sql = @_;
  return ('pg_namespace', [ map { \$_ } @sql ], { nspname => 'pg_catalog' });
}

my @PID = exprs('pg_backend_pid()');

sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the EV loop until $cond holds; false if it does not within 10 seconds.
sub wait_until {
  my ($cond) = @_;
  my $deadline = EV::time() + 10;
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    EV::now_update();
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# Run the loop for a while, so anything that would fire late has fired.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub the_conn { $_[0]->pool->{_connections}[0] }

# A pool of one with its connection up and idle: the harness, the backend of
# that connection, and the connection. Nothing has left a pipeline yet.
sub fresh {
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  die "warming the pool failed: $r[0]" unless $ok;
  settle();
  @EXITS    = ();
  @warnings = ();
  return ($h, $r[0][0], the_conn($h));
}

# What a Future settled with: [ done => @result ], [ failed => $error ], or
# [ 'pending' ] / [ 'cancelled' ].
sub outcome {
  my ($f) = @_;
  return ['never issued'] unless $f;
  return ['pending']      unless $f->is_ready;
  return ['cancelled']    if $f->is_cancelled;
  return [ failed => ($f->failure)[0] ] if $f->is_failed;
  return [ done => $f->get ];
}

sub backend_gone {
  my ($pid) = @_;
  my ($n) = $observer->selectrow_array('SELECT count(*) FROM pg_catalog.pg_stat_activity WHERE pid = ?', undef, $pid);
  return !$n;
}

# The backends the server has for the pool of $h: the owner's DBI connection,
# which carries the same application_name, left out.
sub pool_backends {
  my ($h) = @_;
  my $owner = $h->sync_storage->dbh->{pg_pid};
  return [ grep { $_ != $owner } @{ $observer->selectcol_arrayref(
    'SELECT pid FROM pg_catalog.pg_stat_activity WHERE application_name = ? ORDER BY pid', undef, $TAG,
  ) } ];
}

sub names_in_table { $observer->selectcol_arrayref("SELECT name FROM $TABLE ORDER BY id") }

# How many values the table's sequence has handed out: the INSERTs the server
# ran, committed or not.
sub inserts_run {
  my ($last, $called) = $observer->selectrow_array("SELECT last_value, is_called FROM ${TABLE}_id_seq");
  return $called ? $last : 0;
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::Pg, nothing warned";
  @warnings = ();
}

# 2 / 3. The exit was refused and the connection retired: closed, out of the
# pool, its backend gone from the server; the table is what it was; and the
# next pooled call runs on a fresh backend, as a plain statement.
sub retired_and_replaced {
  my ($label, $h, $pid, $conn, $names, $run) = @_;

  is scalar @EXITS, 1, "$label: pipeline mode was left through the exit seam once";
  like $EXITS[0] // '', $REFUSED, "$label: and EV::Pg refused it -- a result was still due";

  ok !$conn->is_connected, "$label: the connection is closed";
  ok !grep({ $_ == $conn } @{ $h->pool->{_connections} }), "$label: the pool no longer holds it -- retired, not released";
  is $h->pool->available, 0, "$label: nothing is idle";
  is $conn->pending_count, 0, "$label: no callback is left queued on it";
  ok wait_until(sub { backend_gone($pid) }), "$label: its backend is gone from the server";

  is_deeply names_in_table(), $names, "$label: the table is what it was -- nothing was committed";
  note "$label: the server ran " . (inserts_run() - $run) . ' INSERT(s) before the connection closed';

  my ($ok, @r) = wait_for($h->async->select_async(exprs('pg_backend_pid()', "'next'")));
  ok $ok, "$label: the next pooled call completes" or diag "it failed: $r[0]";
  my $fresh = $ok ? $r[0][0] : 0;
  ok $fresh && $fresh != $pid, "$label: on a fresh backend";
  is $ok ? $r[0][1] : undef, 'next', "$label: with its own row";
  settle();
  my $now = the_conn($h);
  is $now && $now->pipeline_status, EV::Pg::PQ_PIPELINE_OFF(), "$label: on an ordinary connection, out of pipeline mode";
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  is_deeply pool_backends($h), [ $fresh ? $fresh : () ], "$label: and the server has that one backend for the pool";
  nothing_warned($label);
}

# --- 1. the control: a batch that reaches its sync point ----------------------------

{
  my $label = 'batch reaches its sync point';
  my ($h, $pid, $conn) = fresh();

  my ($ok, @r) = wait_for($h->async->pipeline(sub {
    my ($batch) = @_;
    return $batch->select_async(exprs('pg_backend_pid()', "'a'"));
  }));
  ok $ok, "$label: the pipeline completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ $pid, 'a' ] ], "$label: with its statement's row";
  is_deeply \@EXITS, ['left'], "$label: pipeline mode is left through the exit seam, which is not refused";

  my ($again, @p) = wait_for($h->async->select_async(@PID));
  is $again ? $p[0][0] : undef, $pid, "$label: the connection is kept -- the next call runs on the same backend";
  settle();
  is $h->pool->available, 1, "$label: which is idle again";
  nothing_warned($label);
  $h->disconnect;
}

# --- 2. pooled: the coderef dies after $batch->insert_async (k73 e) -----------------

{
  my $label = 'pooled, coderef dies mid-batch';
  my ($h, $pid, $conn) = fresh();
  my ($names, $run) = (names_in_table(), inserts_run());

  my ($stmt, %seen);
  my $p = $h->async->pipeline(sub {
    my ($batch) = @_;
    $stmt = $batch->insert_async($TABLE, { name => 'a' });
    @seen{qw( pending pipeline )} = ($conn->pending_count, $conn->pipeline_status);
    die "boom\n";
  });

  is_deeply [ @seen{qw( pending pipeline )} ], [ 1, EV::Pg::PQ_PIPELINE_ON() ],
    "$label: the statement is in flight, in pipeline mode, as the coderef dies";
  is_deeply outcome($p), [ failed => "boom\n" ],
    "$label: the pipeline fails with the coderef's error, not with the exit's";
  is_deeply outcome($stmt), [ failed => 'connection finished' ],
    "$label: the statement in flight fails as its connection is closed";
  retired_and_replaced($label, $h, $pid, $conn, $names, $run);
  $h->disconnect;
}

# --- 3. in a transaction: the coderef of $ctx->pipeline dies (k73 e) ----------------

{
  my $label = 'in a transaction, coderef dies mid-batch';
  my ($h, $pid, $conn) = fresh();
  my ($names, $run) = (names_in_table(), inserts_run());

  my ($before, $stmt, %seen);
  my ($ok, $err) = wait_for($h->async->txn_do_async(sub {
    my ($ctx) = @_;
    $before = $ctx->insert_async($TABLE, { name => 'before the batch' });
    return $before->then(sub {
      return $ctx->pipeline(sub {
        my ($batch) = @_;
        $stmt = $batch->insert_async($TABLE, { name => 'b' });
        $seen{pipeline} = $conn->pipeline_status;
        die "boom\n";
      });
    });
  }));

  is outcome($before)->[0], 'done', "$label: (the transaction had written a row before the batch)";
  ok $seen{pipeline} && $seen{pipeline} == EV::Pg::PQ_PIPELINE_ON(),
    "$label: the batch's statement was issued in pipeline mode, on the transaction's connection";
  ok !$ok, "$label: the transaction fails";
  is $err, "boom\n", "$label: with the error that ended the batch";
  is outcome($stmt)->[0], 'failed', "$label: the statement in flight fails as its connection is closed";
  note "$label: it failed with: " . (outcome($stmt)->[1] // '');
  retired_and_replaced($label, $h, $pid, $conn, $names, $run);
  $h->disconnect;
}

$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->disconnect;
undef $observer;

done_testing;
