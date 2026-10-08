#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::SS;

# Shared work queue: producers `put` items keyed by job id; workers
# atomically claim with `cas_take`, so each job goes to exactly one worker.

my $queue = Data::HashMap::Shared::SS->new("/tmp/dhms_queue_$$.shm", 100_000);

sub enqueue {
    my ($id, $payload) = @_;
    shm_ss_put $queue, $id, $payload;
}

# Returns the payload if this worker won the race, undef if another took it.
sub claim {
    my ($id, $expected_payload) = @_;
    return shm_ss_cas_take $queue, $id, $expected_payload;
}

{
    my $njobs = 20;
    enqueue("job-$_", "payload-$_") for 1..$njobs;

    pipe(my $start_r, my $start_w) or die "pipe: $!";
    my @pids;
    for my $w (1..4) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $start_w;
            <$start_r>;   # start together, or worker 1 finishes before 2 forks
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
    close $start_r;
    close $start_w;
    waitpid($_, 0) for @pids;
    # which worker wins is scheduler-dependent; the totals show exclusivity
    print "claimed: ", $njobs - $queue->size, "/$njobs, remaining unclaimed: ",
          $queue->size, "\n";
    $queue->unlink;
}
