#!/usr/bin/env perl
# Once throughput benchmark
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
    printf "  %-40s %8.0f/s  (%.3fs)\n", $label, $count / $elapsed, $elapsed;
}

print "Once benchmark, $n ops:\n\n";

# is_done check (fast path — just an atomic load)
{
    my $once = Data::Sync::Shared::Once->new(undef);
    $once->enter;
    $once->done;

    bench "is_done (already done)" => $n, sub {
        $once->is_done for 1..$n;
    };
}

# enter when already done (CAS fails on first check)
{
    my $once = Data::Sync::Shared::Once->new(undef);
    $once->enter;
    $once->done;

    bench "enter (already done)" => $n, sub {
        $once->enter for 1..$n;
    };
}

# enter + done + reset cycle
{
    my $once = Data::Sync::Shared::Once->new(undef);

    bench "enter + done + reset cycle" => $n, sub {
        for (1..$n) {
            $once->enter;
            $once->done;
            $once->reset;
        }
    };
}

print "\n";

# Cross-process: many processes checking is_done
{
    print "Cross-process is_done (already done):\n";

    for my $nprocs (2, 4, 8) {
        my $once = Data::Sync::Shared::Once->new(undef);
        $once->enter;
        $once->done;

        my $per = int($n / $nprocs);
        my $total = $per * $nprocs;

        my $t0 = time;
        my @pids;
        for (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                $once->is_done for 1..$per;
                _exit(0);
            }
            push @pids, $pid;
        }
        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f/s  (%.3fs)\n",
            "$nprocs procs is_done", $total / $elapsed, $elapsed;
    }
}

print "\n";

# Cross-process: race to enter
{
    print "Cross-process enter race (N procs, 1 wins):\n";

    for my $nprocs (2, 4, 8) {
        my $rounds = int($n / 100);  # fewer rounds, each is a full race
        my $t0 = time;

        for (1..$rounds) {
            my $once = Data::Sync::Shared::Once->new(undef);
            my @pids;
            for (1..$nprocs) {
                my $pid = fork // die "fork: $!";
                if ($pid == 0) {
                    if ($once->enter(2)) { $once->done }
                    _exit(0);
                }
                push @pids, $pid;
            }
            waitpid($_, 0) for @pids;
        }

        my $elapsed = time - $t0;
        printf "  %-40s %8.0f races/s  (%.3fs)\n",
            "$nprocs procs enter race", $rounds / $elapsed, $elapsed;
    }
}
