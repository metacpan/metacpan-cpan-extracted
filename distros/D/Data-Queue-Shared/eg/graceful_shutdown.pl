#!/usr/bin/env perl
# Graceful shutdown: eventfd signals workers to drain and exit
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $num_workers = 3;
my $q = Data::Queue::Shared::Str->new(undef, 4096);

# Enqueue work
$q->push("task_$_") for 1..30;

# Fork workers
my @pids;
for my $w (1..$num_workers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $done = 0;
        while (!$done) {
            my $task = $q->pop_wait(1);
            unless (defined $task) {
                # Timeout — check if queue is empty (shutdown condition)
                $done = 1 if $q->is_empty;
                next;
            }
            # Simulate work
            select(undef, undef, undef, 0.01);
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

# Wait for all workers to finish
for my $pid (@pids) {
    waitpid($pid, 0);
}

my $s = $q->stats;
print "shutdown complete: $s->{pop_ok} tasks processed by $num_workers workers\n";
