#!/usr/bin/env perl
# Basic LIFO lifecycle: push, pop, peek, fill, drain
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Stack::Shared;
$| = 1;

my $stk = Data::Stack::Shared::Int->new(undef, 8);
printf "stack: capacity=%d\n\n", $stk->capacity;

# push/pop — LIFO
$stk->push(10);
$stk->push(20);
$stk->push(30);
printf "pushed 10, 20, 30\n";
printf "pop: %d (LIFO)\n", $stk->pop;
printf "pop: %d\n", $stk->pop;
printf "peek: %d (non-destructive)\n", $stk->peek;
printf "pop: %d\n", $stk->pop;
printf "size: %d, empty: %s\n\n", $stk->size, $stk->is_empty ? "yes" : "no";

# fill and drain
$stk->push($_) for 1..8;
printf "filled: size=%d, full=%s\n", $stk->size, $stk->is_full ? "yes" : "no";
printf "push when full: %s\n", $stk->push(99) ? "ok" : "rejected";
my @vals;
push @vals, $stk->pop while !$stk->is_empty;
printf "drained (LIFO): %s\n\n", join(' ', @vals);

my $s = $stk->stats;
printf "stats: pushes=%d pops=%d\n", $s->{pushes}, $s->{pops};
