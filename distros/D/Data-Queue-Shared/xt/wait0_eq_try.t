use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# pop_wait(0) and pop should both be non-blocking with identical results
# under the same state. Same for push_wait(val, 0) and push(val).

my $q = Data::Queue::Shared::Int->new(undef, 4);

# Empty queue: both return undef quickly
{
    my $t0 = time;
    my $a = $q->pop;
    my $b = $q->pop_wait(0);
    my $elapsed = time - $t0;
    is $a, undef, 'pop on empty returns undef';
    is $b, undef, 'pop_wait(0) on empty returns undef';
    cmp_ok $elapsed, '<', 0.1, "both non-blocking (elapsed=${elapsed}s)";
}

# Full queue: push fails, push_wait(0) fails
{
    $q->push($_) for 1..4;
    my $t0 = time;
    my $a = $q->push(99);
    my $b = $q->push_wait(99, 0);
    my $elapsed = time - $t0;
    ok !$a, 'push on full returns false';
    ok !$b, 'push_wait(0) on full returns false';
    cmp_ok $elapsed, '<', 0.1, "both non-blocking (elapsed=${elapsed}s)";
}

# Partial queue: pop returns expected; pop_wait(0) returns same
{
    is $q->pop, 1, 'pop returns 1';
    is $q->pop_wait(0), 2, 'pop_wait(0) returns 2 (next FIFO)';
}

done_testing;
