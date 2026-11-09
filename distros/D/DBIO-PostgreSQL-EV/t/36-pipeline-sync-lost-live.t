use strict;
use warnings;
use Test::More;

# LIVE regression for karr k47: a pipeline whose connection dies before the
# sync point fails with EV::Pg's error, and the pool serves on.
#
# The backend of the pipeline's own connection is terminated from a second
# session (pg_terminate_backend -- only this file's own sessions). EV::Pg then
# calls the pipeline_sync callback with (undef, $error) -- measured with EV::Pg
# 0.07 against PostgreSQL 18.6:
#   * killed while a statement of the batch runs: the statements fail first
#     ("FATAL:  terminating connection due to administrator command",
#     "pipeline aborted"), then the sync gets "connection lost";
#   * killed before a batch without statements: the server's FATAL lands on the
#     sync itself, and once the connection goes EV::Pg calls the same sync
#     callback a second time, with "connection lost".
#
# Before the fix _pipeline_sync ignored those arguments and was done. pipeline()
# failed all the same, but only because exit_pipeline croaked afterwards on the
# dead connection -- with "not connected" or
# "PQexitPipelineMode failed: cannot exit pipeline mode while busy", never the
# cause -- and in a transaction's pipeline the second call died out of EV::Pg:
# "exception in callback during cancel: ... is already done".
#
# What this file claims:
#   a. pipeline() fails with the sync's error -- also when the coderef returns a
#      plain value, so no statement Future can carry the failure;
#   b. nothing is left checked out, the next acquire on the pool of one
#      resolves, and the next call completes;
#   c. no callback of this transport dies out of EV::Pg -- in the transaction's
#      pipeline too, where the sync callback is called twice.
#
# Not claimed here: that a transaction whose connection died gives back a
# usable connection. It hands the dead one back to the pool, which since karr
# k49 retires it -- t/42-pool-retire-dead-live.t claims that. Every wait is
# bounded by a watchdog, and alarm is the backstop.

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

my @SELECT = ('pg_namespace', ['nspname'], { nspname => 'pg_catalog' });

my $LOST  = qr/^connection lost/;
my $FATAL = qr/^FATAL:  terminating connection due to administrator command/;

sub harness {
  return DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
}

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

# Run the loop a little, so a late second firing has fired before counting.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.3, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub terminate {
  my ($h, $pid) = @_;
  my ($ok) = $h->sync_storage->dbh->selectrow_array(
    'SELECT pg_terminate_backend(?, 5000)', undef, $pid,
  );
  return $ok;
}

# The backend pid of the pool's one connection, which is up.
sub pool_pid {
  my ($h) = @_;
  my ($up, @r) = wait_for($h->async->select_async(@SELECT));
  die "the connection did not come up: $r[0]" unless $up;
  my ($ok, $pg) = wait_for($h->pool->acquire);
  die "acquire failed: $pg" unless $ok;
  my $pid = $pg->backend_pid;
  $h->pool->release($pg);
  return $pid;
}

# Kill $pid now and give the server time to send its FATAL, without running
# the loop: EV::Pg has not noticed yet when the batch goes out.
sub terminate_unnoticed {
  my ($h, $pid) = @_;
  terminate($h, $pid) or die "pg_terminate_backend($pid) failed\n";
  select undef, undef, undef, 0.3;
  return;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# a. + b. + c. for $storage->pipeline.
sub pipeline_fails_and_pool_serves {
  my ($label, $h, $f, $error) = @_;
  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: pipeline() fails"
    or diag 'it resolved: ' . join ', ', map { $_ // 'undef' } @r;
  like $r[0], $error, "$label: with the sync's error";
  settle();
  my $pool = $h->pool;
  is $pool->available, $pool->size, "$label: nothing is left checked out";
  my ($acquired, $conn) = wait_for($pool->acquire);
  ok $acquired, "$label: the next acquire on the pool of one resolves"
    or diag "it failed: $conn";
  $pool->release($conn) if $acquired;
  my ($next, @rows) = wait_for($h->async->select_async(@SELECT));
  ok $next, "$label: the next call completes"
    or diag "it failed: $rows[0]";
  no_callback_died($label);
}

# --- killed while a statement of the batch runs --------------------------------

{
  my $h   = harness();
  my $pid = pool_pid($h);
  EV::now_update();
  my $killer = EV::timer(0.5, 0, sub { terminate($h, $pid) or die "pg_terminate_backend($pid) failed\n" });

  my $f = $h->async->pipeline(sub {
    my ($batch) = @_;
    $batch->_query_async('SELECT pg_sleep(3)', []);
    $batch->_query_async('SELECT 1', []);
    return 'plain-ok';
  });
  pipeline_fails_and_pool_serves('killed during the batch', $h, $f, $LOST);
  $h->disconnect;
}

# --- killed before a batch without statements -----------------------------------
#
# Killed from inside the coderef, with the connection checked out for the
# pipeline and nothing sent on it yet. Killed while it still sat idle, it would
# not be handed out at all -- the pool looks at an idle connection before it
# hands it out (karr k72, t/63-idle-liveness-live.t) -- and the pipeline would
# run, on a fresh connection.

{
  my $h   = harness();
  my $pid = pool_pid($h);

  my $f = $h->async->pipeline(sub { terminate_unnoticed($h, $pid); 'plain-ok' });
  pipeline_fails_and_pool_serves('killed before an empty batch', $h, $f, $FATAL);
  $h->disconnect;
}

# --- a transaction's pipeline, killed before a batch without statements --------

{
  my $h = harness();
  pool_pid($h);

  my $pipe;
  my $txn = $h->async->txn_do_async(sub {
    my ($ctx) = @_;
    terminate_unnoticed($h, $ctx->txn_conn->backend_pid);
    $pipe = $ctx->pipeline(sub { 'plain-ok' });
    return $pipe;
  });
  my ($txn_ok) = wait_for($txn);
  ok !$txn_ok, 'transaction pipeline: the transaction fails';
  settle();
  ok $pipe && $pipe->is_failed, 'transaction pipeline: $ctx->pipeline fails';
  like +($pipe && $pipe->is_failed ? ($pipe->failure)[0] : ''), $FATAL,
    "transaction pipeline: with the sync's error";
  no_callback_died('transaction pipeline');
  $h->disconnect;
}

done_testing;
