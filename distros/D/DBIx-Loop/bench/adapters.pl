#!/usr/bin/env perl
use strict;
use warnings;

# Compare loop adapters on two axes:
#   throughput - small fast queries/sec through the pool (dispatch overhead:
#                framing + Storable + loop wakeup + future settle per query)
#   overlap    - N CPU-heavy queries, wall-clock vs serial plain DBI
#
# Adapters run one at a time in a FORKED child so each gets a clean loop
# (Mojo/AnyEvent singletons do not mix in one process).
#
#   perl bench/adapters.pl [n_fast] [n_slow] [workers]

use Time::HiRes qw(time);
use File::Temp ();
use DBI;
use Storable qw(freeze thaw);

my $NFAST   = shift || 2000;
my $NSLOW   = shift || 8;
my $WORKERS = shift || 4;

my $SLOW = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 2000000) SELECT COUNT(*) FROM c";

my @ADAPTERS = (
    [ 'IOAsync',  'IO::Async::Loop', 'DBIx::Loop::Loop::IOAsync'  ],
    [ 'Mojo',     'Mojo::IOLoop',    'DBIx::Loop::Loop::Mojo'     ],
    [ 'AnyEvent', 'AnyEvent',        'DBIx::Loop::Loop::AnyEvent' ],
    [ 'Hyperman', 'Hyperman',        'DBIx::Loop::Loop::Hyperman' ],
);

# ---- serial DBI baselines -----------------------------------------------------
my ($serial_fast, $serial_slow);
{
    my $dir = File::Temp->newdir;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/base.db", '', '', { RaiseError => 1 });
    my $t0 = time;
    for (1 .. $NFAST) { my ($v) = $dbh->selectrow_array("SELECT 1") }
    $serial_fast = time - $t0;
    $t0 = time;
    for (1 .. $NSLOW) { my ($v) = $dbh->selectrow_array($SLOW) }
    $serial_slow = time - $t0;
}
printf "plain DBI (serial)  : fast %6.0f q/s   slow %d in %.2fs\n\n",
    $NFAST / $serial_fast, $NSLOW, $serial_slow;

printf "%-9s %14s %18s %10s\n", 'adapter', 'fast q/s', 'slow wall-clock', 'overlap';
for my $a (@ADAPTERS) {
    my ($name, $probe, $class) = @$a;
    my $pid = open(my $rd, '-|');
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # child: one adapter, clean loop
        my $out = eval {
            eval "require $probe; 1"  or die "SKIP ($probe not installed)\n";
            eval "require $class; 1"  or die "SKIP ($class failed: $@)\n";
            require DBIx::Loop;
            my $dir = File::Temp->newdir;
            my $ad  = $class->new;
            my $db  = DBIx::Loop->connect("dbi:SQLite:dbname=$dir/a.db", '', '',
                { RaiseError => 1, PrintError => 0 },
                loop => $ad, workers => $WORKERS);

            # warm the pool
            my $wm = $db->query("SELECT 1"); $ad->await($wm);

            # fast-query throughput (sequential round trips: pure dispatch cost)
            my $t0 = time;
            for (1 .. $NFAST) {
                my $f = $db->query("SELECT 1");
                $ad->await($f);
            }
            my $fast = $NFAST / (time - $t0);

            # overlap on CPU-heavy queries
            $t0 = time;
            my @f = map { $db->query($SLOW) } 1 .. $NSLOW;
            $ad->await($_) for @f;
            my $slow = time - $t0;

            $db->disconnect;
            sprintf "OK %.0f %.2f", $fast, $slow;
        } || "SKIP ($@)";
        chomp $out;
        print "$out\n";
        exit 0;
    }
    my $line = <$rd> || ''; close $rd;
    chomp $line;
    if ($line =~ /^OK (\S+) (\S+)/) {
        my ($fast, $slow) = ($1, $2);
        printf "%-9s %10.0f q/s %15.2fs %9.1fx\n",
            $name, $fast, $slow, $serial_slow / $slow;
    } else {
        $line =~ s/^SKIP\s*//;
        printf "%-9s %14s   %s\n", $name, '-', ($line || 'skipped');
    }
}
