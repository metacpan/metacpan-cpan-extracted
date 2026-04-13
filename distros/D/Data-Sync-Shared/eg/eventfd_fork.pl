#!/usr/bin/env perl
# Cross-process eventfd: parent and children share notifications
#
# Parent creates eventfd before fork. All children inherit the fd.
# Each child does work and notifies; parent collects all notifications.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 5;

# Create semaphore and eventfd before forking
my $sem = Data::Sync::Shared::Semaphore->new(undef, $nworkers);
my $fd = $sem->eventfd;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # Acquire a permit (simulate using a resource)
        $sem->acquire;
        usleep(50_000 * $w);  # hold for varying time
        $sem->release;

        # Notify parent that this worker is done
        $sem->notify;
        printf "  worker %d: done, notified\n", $w;
        _exit(0);
    }
    push @pids, $pid;
}

# Parent: collect notifications
my $collected = 0;
while ($collected < $nworkers) {
    my $n = $sem->eventfd_consume;
    if (defined $n && $n > 0) {
        $collected += $n;
        printf "  parent: got %d notification(s), total=%d/%d\n",
            $n, $collected, $nworkers;
    } else {
        select(undef, undef, undef, 0.01);  # brief sleep, no busy-spin
    }
}

waitpid($_, 0) for @pids;
printf "\nall %d workers finished, sem value=%d\n", $nworkers, $sem->value;
