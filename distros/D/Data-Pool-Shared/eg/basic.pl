#!/usr/bin/env perl
# Basic lifecycle: alloc, set, get, atomic ops, free

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
$| = 1;
use Data::Pool::Shared;

my $pool = Data::Pool::Shared::I64->new(undef, 8);
printf "pool: capacity=%d, used=%d, available=%d\n",
    $pool->capacity, $pool->used, $pool->available;

# alloc and set
my $a = $pool->alloc;
my $b = $pool->alloc;
$pool->set($a, 100);
$pool->set($b, 200);
printf "slot %d = %d, slot %d = %d\n", $a, $pool->get($a), $b, $pool->get($b);

# atomic operations
$pool->add($a, 50);
printf "after add(50): slot %d = %d\n", $a, $pool->get($a);

$pool->incr($b);
$pool->incr($b);
$pool->decr($b);
printf "after incr/incr/decr: slot %d = %d\n", $b, $pool->get($b);

# CAS
my $ok = $pool->cas($a, 150, 999);
printf "cas(150 -> 999): %s, value = %d\n", $ok ? "ok" : "fail", $pool->get($a);

$ok = $pool->cas($a, 150, 0);
printf "cas(150 -> 0): %s, value = %d\n", $ok ? "ok" : "fail", $pool->get($a);

# free
$pool->free($a);
$pool->free($b);
printf "after free: used=%d, available=%d\n", $pool->used, $pool->available;

# stats
my $s = $pool->stats;
printf "stats: allocs=%d, frees=%d\n", $s->{allocs}, $s->{frees};
