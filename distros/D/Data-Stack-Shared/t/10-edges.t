use strict;
use warnings;
use Test::More;
use Data::Stack::Shared;

# --- capacity=1 LIFO ---
{
    my $s = Data::Stack::Shared::Int->new(undef, 1);
    is $s->capacity, 1;
    ok $s->push(42);
    ok !$s->push(43), 'second push fails (full)';
    is $s->peek, 42;
    is $s->pop, 42;
    ok !defined $s->pop, 'empty';
    ok $s->push(99);
    is $s->pop, 99;
}

# --- all-null / all-0xFF binary (Str) ---
{
    my $s = Data::Stack::Shared::Str->new(undef, 4, 16);
    my $nulls = "\x00" x 10;
    my $maxes = "\xFF" x 10;
    ok $s->push($nulls);
    ok $s->push($maxes);
    ok $s->push("");
    is $s->pop, "",     'empty string preserved (LIFO top)';
    is $s->pop, $maxes, 'all-0xFF preserved';
    is $s->pop, $nulls, 'all-null preserved';
}

# --- odd (non-power-of-2) capacity ---
{
    my $s = Data::Stack::Shared::Int->new(undef, 13);
    $s->push($_) for 1..13;
    ok $s->is_full;
    is $s->pop, $_, "LIFO pop $_" for reverse 1..13;
    ok $s->is_empty;
}

done_testing;
