#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::CountingBloomFilter::Shared;

# "Have I seen this before?" -- a dedup pass over a stream using a Bloom filter.
# add() returns 1 the first time it sees an item and 0 afterwards, so it doubles
# as a probabilistic "is this new?" test in a tiny, fixed amount of memory.

my @stream = qw(
    apple banana apple cherry date apple banana
    elderberry fig cherry grape apple fig date
);

my $bf = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);

print "first time each item is seen (dedup):\n";
for my $item (@stream) {
    if ($bf->add($item)) {
        print "  new:  $item\n";
    } else {
        print "  seen: $item\n";
    }
}

# membership queries afterwards
print "\nmembership queries:\n";
for my $q (qw(apple kiwi banana mango)) {
    printf "  contains(%-7s): %s\n", $q, $bf->contains($q) ? "probably yes" : "definitely no";
}

my $st = $bf->stats;
printf "\nfilter: capacity %d, fp_rate %g, %d counters, %d hashes\n",
    @{$st}{qw(capacity fp_rate counters hashes)};
printf "counters set %d / %d (fill %.4f), estimated distinct %d, memory %d bytes\n",
    @{$st}{qw(counters_set counters fill_ratio count mmap_size)};
