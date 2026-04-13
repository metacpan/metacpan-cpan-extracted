#!/usr/bin/env perl
# Semaphore throughput benchmark
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $n = shift || 1_000_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time;
    $code->();
    my $elapsed = time - $t0;
    my $rate = $n / $elapsed;
    printf "  %-40s %8.0f/s  (%.3fs)\n", $label, $rate, $elapsed;
}

print "Semaphore benchmark, $n ops:\n\n";

# Single-process acquire/release
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 1000);

    print "Single-process (uncontended):\n";

    bench "try_acquire + release" => sub {
        for (1..$n) {
            $sem->try_acquire;
            $sem->release;
        }
    };

    bench "acquire + release" => sub {
        for (1..$n) {
            $sem->acquire;
            $sem->release;
        }
    };

    bench "try_acquire (always fail)" => sub {
        my $s = Data::Sync::Shared::Semaphore->new(undef, 1);
        $s->try_acquire;  # drain
        $s->try_acquire for 1..$n;
        $s->release;
    };
}

print "\n";

# Cross-process contended
{
    print "Cross-process (contended, sem=1):\n";

    for my $nprocs (2, 4, 8) {
        my $sem = Data::Sync::Shared::Semaphore->new(undef, 1);
        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for my $p (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for (1..$per) {
                    $sem->acquire;
                    $sem->release;
                }
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "$nprocs procs acquire+release", $total / $elapsed, $elapsed;
    }
}

print "\n";

# Cross-process with wider semaphore
{
    print "Cross-process (wider semaphore):\n";

    for my $max (1, 4, 16, 64) {
        my $nprocs = 8;
        my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for my $p (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for (1..$per) {
                    $sem->acquire;
                    $sem->release;
                }
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "8 procs, max=$max", $total / $elapsed, $elapsed;
    }
}
