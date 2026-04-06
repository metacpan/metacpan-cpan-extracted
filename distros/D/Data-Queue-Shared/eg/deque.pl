#!/usr/bin/env perl
# Str queue as a double-ended queue (deque)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $q = Data::Queue::Shared::Str->new(undef, 64);

# Push to back and front
$q->push("B");
$q->push("C");
$q->push_front("A");

# Queue order: A, B, C
print "peek: ", $q->peek, "\n";       # A
print "pop: ", $q->pop, "\n";         # A (from front)
print "pop_back: ", $q->pop_back, "\n"; # C (from back)
print "pop: ", $q->pop, "\n";         # B (last remaining)

# Work-stealing pattern: main queue + requeue on failure
$q->push("job_1");
$q->push("job_2");
$q->push("job_3");

# Simulate failed job → requeue at front
my $job = $q->pop;
print "processing: $job (simulating failure)\n";
$q->push_front($job);  # requeue at head for immediate retry

print "next: ", $q->pop, "\n";  # job_1 again (retried first)

# Work stealing from back
print "stolen: ", $q->pop_back, "\n";  # job_3 (stolen by another worker)
print "remaining: ", $q->pop, "\n";    # job_2
