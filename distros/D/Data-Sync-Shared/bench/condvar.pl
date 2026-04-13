#!/usr/bin/env perl
# Condvar signal/wait throughput benchmark
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX qw(_exit);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $n = shift || 100_000;

sub bench {
    my ($label, $count, $code) = @_;
    my $t0 = time;
    $code->();
    my $elapsed = time - $t0;
    printf "  %-40s %8.0f/s  (%.3fs)\n", $label, $count / $elapsed, $elapsed;
}

print "Condvar benchmark, $n ops:\n\n";

# Single-process lock/unlock
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);

    print "Single-process (uncontended):\n";

    bench "lock + unlock" => $n, sub {
        for (1..$n) { $cv->lock; $cv->unlock }
    };

    bench "signal (no waiters)" => $n, sub {
        for (1..$n) { $cv->signal }
    };

    bench "broadcast (no waiters)" => $n, sub {
        for (1..$n) { $cv->broadcast }
    };
}

print "\n";

# Ping-pong: signal/wait between two processes
{
    print "Cross-process signal/wait ping-pong:\n";

    my $cv1 = Data::Sync::Shared::Condvar->new(undef);
    my $cv2 = Data::Sync::Shared::Condvar->new(undef);

    my $t0 = time;
    my $pid = fork // die "fork: $!";

    if ($pid == 0) {
        for (1..$n) {
            $cv1->lock;
            $cv1->wait(5);
            $cv1->unlock;

            $cv2->lock;
            $cv2->signal;
            $cv2->unlock;
        }
        _exit(0);
    }

    for (1..$n) {
        $cv1->lock;
        $cv1->signal;
        $cv1->unlock;

        $cv2->lock;
        $cv2->wait(5);
        $cv2->unlock;
    }

    waitpid($pid, 0);
    my $elapsed = time - $t0;
    printf "  %-40s %8.0f roundtrips/s  (%.3fs)\n",
        "2-process ping-pong", $n / $elapsed, $elapsed;
}

print "\n";

# Broadcast fan-out
{
    print "Broadcast fan-out (1 signaler, N waiters):\n";

    for my $nwaiters (2, 4, 8) {
        my $cv = Data::Sync::Shared::Condvar->new(undef);
        my $bar = Data::Sync::Shared::Barrier->new(undef, $nwaiters + 1);
        my $rounds = int($n / 10);

        my $t0 = time;
        my @pids;
        for (1..$nwaiters) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                for (1..$rounds) {
                    $bar->wait;  # sync start
                    $cv->lock;
                    $cv->wait(5);
                    $cv->unlock;
                }
                _exit(0);
            }
            push @pids, $pid;
        }

        for (1..$rounds) {
            $bar->wait;  # wait for all waiters to be ready
            $cv->lock;
            $cv->broadcast;
            $cv->unlock;
        }

        waitpid($_, 0) for @pids;
        my $elapsed = time - $t0;
        printf "  %-40s %8.0f broadcasts/s  (%.3fs)\n",
            "$nwaiters waiters", $rounds / $elapsed, $elapsed;
    }
}
