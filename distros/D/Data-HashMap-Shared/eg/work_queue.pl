#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SS;

# Shared work queue: producers `put` items keyed by job id; workers
# atomically claim with `cas_take`. Claim is exclusive — only one
# worker can take each job, even with N workers racing on the same id.

my $queue = Data::HashMap::Shared::SS->new('/tmp/demo_queue.shm', 100_000);

# Producer side
sub enqueue {
    my ($id, $payload) = @_;
    shm_ss_put $queue, $id, $payload;
}

# Worker side: claim-or-skip. Returns the payload if this worker won
# the race; undef if another worker already took it.
sub claim {
    my ($id, $expected_payload) = @_;
    return shm_ss_cas_take $queue, $id, $expected_payload;
}

# Demo: enqueue some jobs, spawn 4 workers, count wins.
# Pass `reset` as an argument to drop the backing file and exit.
if (@ARGV && $ARGV[0] eq 'reset') { $queue->unlink; exit }

{
    my $njobs = 20;
    enqueue("job-$_", "payload-$_") for 1..$njobs;

    my @pids;
    for my $w (1..4) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $wins = 0;
            for my $j (1..$njobs) {
                my $got = claim("job-$j", "payload-$j");
                $wins++ if defined $got;
            }
            print "worker $w claimed $wins jobs\n";
            exit;
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    print "remaining unclaimed: ", $queue->size, "\n";
}
