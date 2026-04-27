use strict;
use warnings;
use Test::More;
use Data::Queue::Shared;

# --- minimum capacity (Vyukov rounds up to power-of-2; cap=1 → effective 2) ---
{
    my $q = Data::Queue::Shared::Int->new(undef, 1);
    is $q->capacity, 2, 'cap=1 rounds up to 2 (MPMC power-of-2 constraint)';
    ok $q->push(42);
    ok $q->push(43);
    ok !$q->push(44), 'third push fails at full';
    is $q->pop, 42, 'FIFO: 42 first';
    is $q->pop, 43, 'FIFO: 43 second';
    ok !defined $q->pop, 'empty';
    ok $q->push(99), 'push after drain';
    is $q->pop, 99;
}

# --- all-null / all-0xFF binary data (Str) ---
{
    my $q = Data::Queue::Shared::Str->new(undef, 4, 16);
    my $nulls = "\x00" x 8;
    my $maxes = "\xFF" x 8;
    ok $q->push($nulls), 'push all-null string';
    ok $q->push($maxes), 'push all-0xFF string';
    ok $q->push(""),     'push empty string';
    is $q->pop, $nulls, 'pop all-null preserved';
    is $q->pop, $maxes, 'pop all-0xFF preserved';
    is $q->pop, "",     'pop empty preserved';
}

# --- odd (non-power-of-2) capacity ---
{
    my $q = Data::Queue::Shared::Int->new(undef, 17);
    # Wrap past capacity twice to exercise modulo
    for my $cycle (1..3) {
        $q->push($_) for 1..17;
        is $q->size, 17, "filled cycle $cycle";
        is $q->pop, $_, "pop $_ cycle $cycle" for 1..17;
        is $q->size, 0, "drained cycle $cycle";
    }
}

done_testing;
