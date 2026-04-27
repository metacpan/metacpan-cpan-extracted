use strict;
use warnings;
use Test::More;
use Data::Deque::Shared;

# --- capacity=1 ---
{
    my $d = Data::Deque::Shared::Int->new(undef, 1);
    is $d->capacity, 1;
    ok $d->push_back(42);
    ok !$d->push_back(43), 'push_back fails at full';
    ok !$d->push_front(44), 'push_front also fails at full';
    is $d->pop_front, 42;
    ok $d->push_front(99);
    is $d->pop_back, 99, 'push_front then pop_back on cap=1';
}

# --- all-null / all-0xFF (Str) ---
{
    my $d = Data::Deque::Shared::Str->new(undef, 4, 16);
    my $nulls = "\x00" x 10;
    my $maxes = "\xFF" x 10;
    ok $d->push_back($nulls);
    ok $d->push_front($maxes);
    ok $d->push_back("");
    is $d->pop_front, $maxes, 'pop_front returns front-inserted';
    is $d->pop_front, $nulls;
    is $d->pop_front, "";
}

# --- odd capacity ---
{
    my $d = Data::Deque::Shared::Int->new(undef, 11);
    $d->push_back($_) for 1..11;
    ok $d->is_full;
    is $d->pop_front, $_, "FIFO pop_front $_" for 1..11;
    ok $d->is_empty;
}

done_testing;
