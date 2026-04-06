#!/usr/bin/env perl
# Job retry with push_front: failed jobs go back to the head
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $q = Data::Queue::Shared::Str->new(undef, 256);

# Enqueue some jobs
$q->push("job_$_") for 1..5;

# Process with simulated failures and retries
my %retries;
my $max_retries = 2;
my $processed = 0;

while (defined(my $job = $q->pop)) {
    $retries{$job} //= 0;

    # Simulate: job_2 and job_4 fail on first attempt
    my $fails = ($job =~ /_(2|4)$/ && $retries{$job} == 0);

    if ($fails) {
        $retries{$job}++;
        if ($retries{$job} <= $max_retries) {
            printf "FAIL  %-10s (retry %d, requeueing at front)\n", $job, $retries{$job};
            $q->push_front($job);  # immediate retry
            next;
        }
        printf "DROP  %-10s (exceeded max retries)\n", $job;
        next;
    }

    $processed++;
    printf "OK    %-10s (attempt %d)\n", $job, $retries{$job} + 1;
}

print "\nprocessed: $processed / 5 jobs\n";
