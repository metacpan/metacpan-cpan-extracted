use strict;
use warnings;
use Test::More;

use Data::RingBuffer::Shared;

# Capacity 1
{
    my $r = Data::RingBuffer::Shared::Int->new_memfd("e1", 1);
    is $r->capacity, 1, "capacity=1";
    $r->write(42);
    is $r->latest, 42, "only slot";
    $r->write(99);
    is $r->latest, 99, "overwritten";
}

# F64 variant
{
    my $r = Data::RingBuffer::Shared::F64->new_memfd("e2", 8);
    $r->write(3.14);
    $r->write(2.71);
    cmp_ok abs($r->latest - 2.71), '<', 1e-9, "F64 latest";
    cmp_ok abs($r->latest(1) - 3.14), '<', 1e-9, "F64 latest(1)";
}

# Latest(n) beyond written count
{
    my $r = Data::RingBuffer::Shared::Int->new_memfd("e3", 16);
    $r->write($_) for 1..3;
    ok !defined $r->latest(10), "latest(n) beyond count returns undef";
}

# Stats
{
    my $r = Data::RingBuffer::Shared::Int->new_memfd("e4", 4);
    $r->write($_) for 1..10;
    my $s = $r->stats;
    is $s->{writes}, 10, "stat_writes counted";
    cmp_ok $s->{overwrites}, '>', 0, "overwrites counted";
}

# Signed extremes
{
    my $r = Data::RingBuffer::Shared::Int->new_memfd("e5", 4);
    $r->write(0x7FFFFFFFFFFFFFFF);
    $r->write(-0x8000000000000000);
    is $r->latest, -0x8000000000000000, "int64 min preserved";
    is $r->latest(1), 0x7FFFFFFFFFFFFFFF, "int64 max preserved";
}

done_testing;
