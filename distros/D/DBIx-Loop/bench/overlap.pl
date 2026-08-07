#!/usr/bin/env perl
use strict;
use warnings;

# The point of DBIx::Loop, measured: OVERLAP and LATENCY ISOLATION - not
# per-query speed. A slow query through plain DBI blocks everything behind it;
# through DBIx::Loop it runs on a pool worker while the loop keeps serving.
# (Per-query, DBD is already at libsqlite3 parity - a custom binding was
# benchmarked and rejected; see the plan. This is about not blocking.)
#
#   perl bench/overlap.pl [n_queries] [workers]

use Time::HiRes qw(time);
use File::Temp ();
use DBI;
use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $N       = shift || 8;
my $WORKERS = shift || 4;
my $dir     = File::Temp->newdir;
my $file    = "$dir/bench.db";

# a query that takes real CPU inside SQLite (~100ms here)
my $SLOW = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 2000000) SELECT COUNT(*) FROM c";

{ DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1 })
      ->do("CREATE TABLE t (id INTEGER PRIMARY KEY)"); }

# ---- serial plain DBI -------------------------------------------------------
my $t0 = time;
{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1 });
    for (1 .. $N) {
        my ($n) = $dbh->selectrow_array($SLOW);
    }
}
my $serial = time - $t0;
printf "serial DBI          : %d queries in %.2fs\n", $N, $serial;

# ---- concurrent via DBIx::Loop ---------------------------------------------
my $ad = DBIx::Loop::Loop::IOAsync->new;
my $db = DBIx::Loop->connect("dbi:SQLite:dbname=$file", '', '',
    { RaiseError => 1, PrintError => 0 }, loop => $ad, workers => $WORKERS);

$t0 = time;
my @f = map { $db->query($SLOW) } 1 .. $N;
$ad->await($_) for @f;
my $conc = time - $t0;
printf "DBIx::Loop pool (%d) : %d queries in %.2fs   (%.1fx overlap)\n",
    $WORKERS, $N, $conc, $serial / $conc;

# ---- latency isolation: the loop stays live under a slow query ---------------
my $ticks = 0;
$ad->timer($_ * 0.01, sub { $ticks++ }) for 1 .. 10;
my $slow = $db->query($SLOW);
$ad->await($slow);
printf "loop liveness       : %d/10 timers fired while a slow query ran\n", $ticks;

$db->disconnect;
