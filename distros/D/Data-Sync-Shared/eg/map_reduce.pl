#!/usr/bin/env perl
# MapReduce with barrier synchronization
#
# Phase 1: workers "map" (compute partial sums)
# Barrier: all wait until map is complete
# Phase 2: leader "reduces" (sums the partials)
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 4;
my $chunk    = 250_000;

# Shared file for partial results
use File::Temp qw(tmpnam);
my $results_file = tmpnam();
open my $fh, '>', $results_file or die;
close $fh;

my $bar = Data::Sync::Shared::Barrier->new(undef, $nworkers);
# RWLock protects writes to the results file
my $rw = Data::Sync::Shared::RWLock->new(undef);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # Map phase: compute partial sum
        my $start = ($w - 1) * $chunk + 1;
        my $end   = $w * $chunk;
        my $partial = 0;
        $partial += $_ for $start..$end;

        # Write partial result
        $rw->wrlock;
        open my $fh, '>>', $results_file or die;
        print $fh "$partial\n";
        close $fh;
        $rw->wrunlock;

        printf "  worker %d: mapped %d..%d = %d\n", $w, $start, $end, $partial;

        # Wait for all workers to finish map
        my $leader = $bar->wait(10);

        if ($leader) {
            # Reduce phase: sum all partials
            open my $in, '<', $results_file or die;
            my $total = 0;
            while (<$in>) { chomp; $total += $_ }
            close $in;

            my $n = $nworkers * $chunk;
            my $expected = $n * ($n + 1) / 2;
            printf "  leader reduced: total=%d, expected=%d, %s\n",
                $total, $expected, $total == $expected ? "OK" : "MISMATCH";
        }

        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
unlink $results_file;

printf "map-reduce: %d workers x %d items in %.3fs\n",
    $nworkers, $chunk, time - $t0;
