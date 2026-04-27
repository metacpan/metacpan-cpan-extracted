use strict;
use warnings;
use Test::More;

use Data::Heap::Shared;

# Pop from empty
{
    my $h = Data::Heap::Shared->new_memfd("e1", 8);
    my @r = $h->pop;
    ok !@r, "pop from empty returns empty list";
}

# Fill to capacity
{
    my $h = Data::Heap::Shared->new_memfd("e2", 4);
    ok $h->push(1, 10), "push 1/4";
    ok $h->push(2, 20), "push 2/4";
    ok $h->push(3, 30), "push 3/4";
    ok $h->push(4, 40), "push 4/4";
    # 5th push to full heap
    my $ok = eval { $h->push(5, 50); 1 };
    ok !$ok || !$h->push(5, 50), "push on full returns false or croaks";
}

# Equal priorities preserved in insertion order (or any deterministic order)
{
    my $h = Data::Heap::Shared->new_memfd("e3", 8);
    $h->push(5, $_) for (100, 200, 300);
    my @got;
    while ($h->size) {
        my @p = $h->pop;
        push @got, $p[1];
    }
    is scalar(@got), 3, "equal-priority entries all popped";
}

# Negative priorities
{
    my $h = Data::Heap::Shared->new_memfd("e4", 8);
    $h->push($_, $_) for (-5, 0, 5, -10, 10);
    my @p = $h->pop;
    is $p[0], -10, "min-heap handles negative priorities";
}

# Extreme values
{
    my $h = Data::Heap::Shared->new_memfd("e5", 4);
    $h->push(0x7FFFFFFF, 1);
    $h->push(-0x80000000, 2);
    my @p = $h->pop;
    is $p[0], -0x80000000, "int32 min sorts first";
}

done_testing;
