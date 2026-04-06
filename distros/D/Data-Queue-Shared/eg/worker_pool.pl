#!/usr/bin/env perl
# Pre-fork worker pool with job queue and result queue
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $num_workers = 4;
my $num_jobs = 50;

my $jobs = Data::Queue::Shared::Int->new(undef, 4096);     # anonymous
my $results = Data::Queue::Shared::Int->new(undef, 4096);

# Fork workers
my @pids;
for my $w (1..$num_workers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (1) {
            my $job = $jobs->pop_wait(2);
            last unless defined $job;
            last if $job == -1;  # poison pill
            # "process" the job: square it
            $results->push($job * $job);
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

# Enqueue jobs
$jobs->push($_) for 1..$num_jobs;
$jobs->push(-1) for 1..$num_workers;  # poison pills

# Collect results
my @got;
for (1..$num_jobs) {
    my $r = $results->pop_wait(5);
    last unless defined $r;
    push @got, $r;
}
waitpid($_, 0) for @pids;

@got = sort { $a <=> $b } @got;
print "results: ", scalar @got, " items\n";
print "first 10: @got[0..9]\n";  # 1 4 9 16 25 36 49 64 81 100
