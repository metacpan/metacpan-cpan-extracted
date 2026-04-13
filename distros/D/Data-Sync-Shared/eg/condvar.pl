#!/usr/bin/env perl
# Condvar: producer/consumer with condition variable
#
# Producer signals consumers when work is available.
# Consumers wait on the condvar rather than polling.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $cv = Data::Sync::Shared::Condvar->new(undef);

# Use a shared semaphore as a simple counter for items
my $items = Data::Sync::Shared::Semaphore->new(undef, 1000);
# Drain all permits — start at 0 items
$items->try_acquire for 1..1000;

my $nconsumers = 3;
my $nitems     = 20;

my @pids;

# Consumers: wait for signal, then check for items
for my $c (1..$nconsumers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $consumed = 0;
        while ($consumed < int($nitems / $nconsumers)) {
            $cv->lock;
            while ($items->value == 0) {
                last unless $cv->wait(3.0);
            }
            $cv->unlock;
            if ($items->try_acquire) {
                $consumed++;
                printf "  consumer %d got item (total: %d)\n", $c, $consumed;
            }
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Give consumers time to start waiting
usleep(50_000);

# Producer: add items and signal
for my $i (1..$nitems) {
    $items->release;
    $cv->lock;
    $cv->signal;
    $cv->unlock;
    usleep(10_000);
}

# Final broadcast to release any still-waiting consumers
$cv->lock;
$cv->broadcast;
$cv->unlock;

waitpid($_, 0) for @pids;

printf "remaining items: %d\n", $items->value;
my $s = $cv->stats;
printf "signals: %d, waits: %d\n", $s->{signals}, $s->{waits};
