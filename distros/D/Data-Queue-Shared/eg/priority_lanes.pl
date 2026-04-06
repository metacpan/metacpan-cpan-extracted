#!/usr/bin/env perl
# Two-lane priority queue: check high-priority first, fall back to low
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $hi = Data::Queue::Shared::Str->new(undef, 1024);
my $lo = Data::Queue::Shared::Str->new(undef, 1024);

# Producer: mixed priority jobs
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..20) {
        if ($i % 5 == 0) {
            $hi->push("URGENT_$i");
            $hi->notify;
        } else {
            $lo->push("normal_$i");
            $lo->notify;
        }
    }
    $hi->push("__STOP__");
    $hi->notify;
    POSIX::_exit(0);
}

# Consumer: always drain high-priority first
my $processed = 0;
while (1) {
    # Check high-priority lane first
    my $job = $hi->pop;
    unless (defined $job) {
        # Fall back to low-priority
        $job = $lo->pop;
        unless (defined $job) {
            # Both empty — brief sleep
            select(undef, undef, undef, 0.01);
            next;
        }
    }
    last if $job eq '__STOP__';
    $processed++;
    printf "%-3d %s\n", $processed, $job;
}

# Drain remaining low-priority
while (defined(my $job = $lo->pop)) {
    $processed++;
    printf "%-3d %s\n", $processed, $job;
}

waitpid($pid, 0);
print "processed $processed jobs\n";
