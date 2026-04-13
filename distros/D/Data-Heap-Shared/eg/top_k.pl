#!/usr/bin/env perl
# Top-K: maintain K largest values using a min-heap of size K
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Heap::Shared;
$| = 1;

my $K = 5;
my $heap = Data::Heap::Shared->new(undef, $K);

# stream of values
srand(42);
my @stream = map { int(rand(1000)) } 1..50;

for my $val (@stream) {
    if ($heap->size < $K) {
        $heap->push($val, $val);
    } else {
        my ($min_pri) = $heap->peek;
        if ($val > $min_pri) {
            $heap->pop;           # remove smallest
            $heap->push($val, $val);  # insert new
        }
    }
}

printf "top %d from %d values:\n", $K, scalar @stream;
my @top;
while (!$heap->is_empty) {
    my ($p, $v) = $heap->pop;
    push @top, $v;
}
printf "  %s\n", join(', ', reverse @top);

my @sorted = sort { $b <=> $a } @stream;
printf "  verify: %s\n", join(', ', @sorted[0..$K-1]);
