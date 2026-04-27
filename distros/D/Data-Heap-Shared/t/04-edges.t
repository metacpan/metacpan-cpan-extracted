use strict;
use warnings;
use Test::More;
use Data::Heap::Shared;

# --- capacity=1 ---
{
    my $h = Data::Heap::Shared->new(undef, 1);
    is $h->capacity, 1;
    ok $h->push(5, 100);
    ok !$h->push(3, 200), 'second push fails at full';
    my ($p, $v) = $h->peek;
    is $p, 5;
    is $v, 100;
    ($p, $v) = $h->pop;
    is $p, 5;
    ok $h->is_empty;
    # priority preservation across empty
    ok $h->push(1, 11);
    ($p, $v) = $h->pop;
    is $p, 1;
    is $v, 11;
}

# --- odd capacity ---
{
    my $h = Data::Heap::Shared->new(undef, 7);
    # Insert in random-ish order; heap-order should emerge
    $h->push($_, $_ * 10) for (4, 1, 7, 3, 2, 6, 5);
    ok $h->is_full;
    # Min-heap pop sequence should be 1,2,3,4,5,6,7
    for my $expected (1..7) {
        my ($p, $v) = $h->pop;
        is $p, $expected, "pop priority $expected";
        is $v, $expected * 10, "value $expected";
    }
    ok $h->is_empty;
}

# --- negative priorities ---
{
    my $h = Data::Heap::Shared->new(undef, 5);
    $h->push(-5, 100);
    $h->push(0, 200);
    $h->push(-100, 300);
    $h->push(50, 400);
    my ($p, $v) = $h->pop;
    is $p, -100, 'min heap respects negative priorities';
    is $v, 300;
}

done_testing;
