use strict;
use warnings;
use Test::More;

# try_X vs X_wait(0) identity: both should produce identical return
# values and stat deltas on the same input.

use Data::Queue::Shared::Int;

my $q1 = Data::Queue::Shared::Int->new_memfd("t1", 8);
my $q2 = Data::Queue::Shared::Int->new_memfd("t2", 8);

# On empty queue
is $q1->pop_wait(0), undef, "pop_wait(0) on empty: undef";
is $q2->pop,         undef, "pop on empty: undef";

# Push and observe
$q1->push($_) for 1..3;
$q2->push($_) for 1..3;

is $q1->pop_wait(0), 1, "pop_wait(0) returns first item";
is $q2->pop,         1, "pop returns first item";

# Stat deltas should match
my $s1 = $q1->stats;
my $s2 = $q2->stats;
is $s1->{pushes}, $s2->{pushes}, "pushes counters equal";
is $s1->{pops},   $s2->{pops},   "pops counters equal";
is $s1->{size},   $s2->{size},   "current size equal";

# Full-queue behavior: push_wait(0) == try_push (non-blocking)
$q1->push_wait($_, 0) for 4..10;
$q2->push($_)         for 4..10;

is $q1->size, $q2->size, "after bulk pushes, sizes match";

done_testing;
