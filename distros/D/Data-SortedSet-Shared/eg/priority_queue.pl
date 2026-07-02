#!/usr/bin/env perl
# A min-priority queue / earliest-deadline scheduler: member = task id, score =
# due-time (or priority). pop_min always yields the most urgent task; ties on the
# score break by task id, so scheduling is deterministic.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SortedSet::Shared;

my $q = Data::SortedSet::Shared->new(undef, 10_000);

$q->add(101, 30);          # task 101 due at t=30
$q->add(102, 10);          # task 102 due at t=10
$q->add(103, 20);
$q->add(104, 10);          # tie on due-time with 102 -> 102 runs first (lower id)

$q->add(101, 5);           # reschedule 101 earlier (could also: $q->incr(101, -25))

printf "next up:            task %d (due %g)\n", $q->peek_min;
printf "due before t=15:    %d task(s)\n",       $q->count_in_score(0, 15);
printf "task 103 position:  %d of %d\n",         $q->rank(103), $q->count;

print "draining in due-time order:\n";
while (my ($task, $due) = $q->pop_min) {
    printf "  run task %d (due %g)\n", $task, $due;
}
