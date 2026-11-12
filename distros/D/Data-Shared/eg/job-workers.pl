#!/usr/bin/env perl
# A job queue drained by forked workers. An anonymous root is shared with
# every process forked after its mounts, so no directory is needed.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_get shared_set shared_incr shared_call shared_push);

my ($workers, $jobs) = (4, 100);
my $root = Data::Shared->new;
$root->mount('jobs', 'queue:int', undef, 1024);
$root->mount('results', 'hashmap:ii', undef, 1024);
$root->mount('handled', 'hashmap:si', undef, 16);

my @pids;
for my $n (1 .. $workers) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        # 0 is the stop signal; the timeout ends a worker whose producer died.
        while (my $job = shared_call($root, '/jobs', 'pop_wait', 5)) {
            shared_set($root, "/results/$job", $job * $job);
            shared_incr($root, "/handled/worker$n");
        }
        exit 0;
    }
    push @pids, $pid;
}

shared_push($root, '/jobs', $_) for 1 .. $jobs;
shared_push($root, '/jobs', 0) for 1 .. $workers;
waitpid $_, 0 for @pids;

printf "worker%d handled %d\n", $_, shared_get($root, "/handled/worker$_") // 0
    for 1 .. $workers;
my $done = shared_call($root, '/results', 'size');
print "results: $done, 7 squared = ", shared_get($root, '/results/7'), "\n";
die "lost jobs\n" unless $done == $jobs;
