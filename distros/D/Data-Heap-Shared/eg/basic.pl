#!/usr/bin/env perl
# Basic priority queue: push with priorities, pop in min-priority order
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Heap::Shared;
$| = 1;

my $h = Data::Heap::Shared->new(undef, 20);

$h->push(5, 500);
$h->push(1, 100);
$h->push(3, 300);
$h->push(2, 200);
$h->push(4, 400);

printf "size=%d, capacity=%d\n\n", $h->size, $h->capacity;

printf "pop order (min-priority first):\n";
while (!$h->is_empty) {
    my ($pri, $val) = $h->pop;
    printf "  priority=%d value=%d\n", $pri, $val;
}
