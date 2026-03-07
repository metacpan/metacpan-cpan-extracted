use strict;
use warnings;
use Test::More;

use Data::HashMap::II;

# Insert and verify 100k entries
{
    my $map = Data::HashMap::II->new();
    my $count = 100_000;
    for my $i (1 .. $count) {
        hm_ii_put $map, $i, $i * 2;
    }
    is(hm_ii_size $map, $count, "inserted $count");

    my $ok = 1;
    for my $i (1 .. $count) {
        if ((hm_ii_get $map, $i) != $i * 2) { $ok = 0; last; }
    }
    ok($ok, "all $count verified");
}

# Counter stress
{
    my $map = Data::HashMap::II->new();
    for (1 .. 10_000) { hm_ii_incr $map, 1; }
    is(hm_ii_get $map, 1, 10_000, '10k increments');
}

# Alternating incr/decr
{
    my $map = Data::HashMap::II->new();
    for (1 .. 5_000) {
        hm_ii_incr $map, 1;
        hm_ii_decr $map, 1;
    }
    is(hm_ii_get $map, 1, 0, '5k incr/decr cancels');
}

# Insert/delete cycles
{
    my $map = Data::HashMap::II->new();
    for my $cycle (1 .. 5) {
        for my $i (1 .. 50_000) { hm_ii_put $map, $i, $i; }
        for my $i (1 .. 50_000) { hm_ii_remove $map, $i; }
    }
    is(hm_ii_size $map, 0, 'size 0 after cycles');
}

done_testing;
