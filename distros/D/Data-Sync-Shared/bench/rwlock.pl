#!/usr/bin/env perl
# RWLock throughput benchmark
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $n = shift || 1_000_000;

sub bench {
    my ($label, $count, $code) = @_;
    my $t0 = time;
    $code->();
    my $elapsed = time - $t0;
    my $rate = $count / $elapsed;
    printf "  %-40s %8.0f/s  (%.3fs)\n", $label, $rate, $elapsed;
}

print "RWLock benchmark, $n ops:\n\n";

# Single-process
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    print "Single-process (uncontended):\n";

    bench "rdlock + rdunlock" => $n, sub {
        for (1..$n) { $rw->rdlock; $rw->rdunlock }
    };

    bench "wrlock + wrunlock" => $n, sub {
        for (1..$n) { $rw->wrlock; $rw->wrunlock }
    };

    bench "try_rdlock + rdunlock" => $n, sub {
        for (1..$n) { $rw->try_rdlock; $rw->rdunlock }
    };

    bench "try_wrlock + wrunlock" => $n, sub {
        for (1..$n) { $rw->try_wrlock; $rw->wrunlock }
    };
}

print "\n";

# Readers only (high concurrency)
{
    print "Cross-process readers only:\n";

    for my $nprocs (2, 4, 8) {
        my $rw = Data::Sync::Shared::RWLock->new(undef);
        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for (1..$per) { $rw->rdlock; $rw->rdunlock }
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "$nprocs readers", $total / $elapsed, $elapsed;
    }
}

print "\n";

# Writers only (exclusive contention)
{
    print "Cross-process writers only:\n";

    for my $nprocs (2, 4, 8) {
        my $rw = Data::Sync::Shared::RWLock->new(undef);
        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for (1..$per) { $rw->wrlock; $rw->wrunlock }
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "$nprocs writers", $total / $elapsed, $elapsed;
    }
}

print "\n";

# Mixed read/write (90% read, 10% write)
{
    print "Cross-process mixed (90%% read, 10%% write):\n";

    for my $nprocs (2, 4, 8) {
        my $rw = Data::Sync::Shared::RWLock->new(undef);
        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for my $i (1..$per) {
                    if ($i % 10 == 0) {
                        $rw->wrlock; $rw->wrunlock;
                    } else {
                        $rw->rdlock; $rw->rdunlock;
                    }
                }
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "$nprocs mixed 90r/10w", $total / $elapsed, $elapsed;
    }
}
