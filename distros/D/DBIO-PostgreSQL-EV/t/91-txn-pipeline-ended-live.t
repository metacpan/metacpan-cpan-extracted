use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (core k292): the live half of
# t/90-txn-pipeline-ended-mock.t. A transaction whose coderef runs
# $ctx->pipeline(...) and then dies, or returns a failed Future, before the
# pipeline's sync is answered.
#
# Measured before the fix (PostgreSQL 18.6, EV::Pg 0.07): the ROLLBACK went out
# in pipeline mode behind the sync point and was never answered -- the server
# holds the answer of a statement until the next sync -- so the transaction
# Future stayed pending, pipeline mode could not be left ("cannot exit
# pipeline mode while busy"), and the pool of one was gone for good: its
# connection in pipeline mode with the transaction open.
#
# Claimed: the transaction fails with the coderef's error, the batch's write
# is rolled back, the connection is idle again -- out of pipeline mode, no
# transaction open, 'idle' in pg_stat_activity --, and the next call runs on
# it.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::Pg;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
use PoolReset;
LiveServer->require_server;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $h     = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
my $async = $h->async;
my $obs   = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });

my $table = "dbio_k88_txn_pipeline_$$";
$obs->do("CREATE TABLE $table (name text)");

sub guarded { GuardedWait->until_ready($_[0], 6, $_[1]) }

for my $how (qw( dies fails )) {
  my $label = "the coderef $how after \$ctx->pipeline";
  my ($pg, $pipe);

  my $txn = $async->txn_do_async(sub {
    my ($ctx) = @_;
    $pg   = $ctx->txn_conn;
    $pipe = $ctx->pipeline(sub {
      my ($batch) = @_;
      $batch->_query_async("INSERT INTO $table (name) VALUES (?)", [$how]);
      return 1;
    });
    die "gave up\n" if $how eq 'dies';
    return $h->async->future_class->fail("gave up\n");
  });

  my $f = guarded($txn, "$label: the transaction is still pending after 6s");
  ok $f->is_failed, "$label: the transaction fails";
  is +($f->failure)[0], "gave up\n", "$label: with the coderef's error";

  guarded($h->async->select_async('pg_namespace', ['nspname'], { nspname => 'pg_catalog' }),
    "$label: the next call is still pending after 6s");
  PoolReset->until_reset($h->async);   # the next call's own reset is answered (karr k99)

  is $pg->pipeline_status, EV::Pg::PQ_PIPELINE_OFF(), "$label: libpq pipeline mode is off";
  is $pg->transaction_status, EV::Pg::PQTRANS_IDLE(), "$label: no transaction open";
  my ($state) = $obs->selectrow_array('SELECT state FROM pg_stat_activity WHERE pid = ?', undef, $pg->backend_pid);
  is $state, 'idle', "$label: the server reports the backend 'idle'";
  my ($rows) = $obs->selectrow_array("SELECT count(*) FROM $table");
  is $rows, 0, "$label: the batch's write is rolled back";
  is $h->pool->available, 1, "$label: the pool's one connection is back";
  is_deeply \@warnings, [], "$label: nothing warned";
  @warnings = ();
}

$obs->do("DROP TABLE $table");
$h->disconnect;
$obs->disconnect;
done_testing;
