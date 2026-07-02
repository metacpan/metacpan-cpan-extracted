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
use Data::CuckooFilter::Shared;

# "Have I seen this before?" -- a dedup pass over a stream with a Cuckoo filter.
# A Cuckoo filter does not dedup on add (re-adding stores a duplicate), so we ask
# contains() first and only add() when the item is new. Membership uses a tiny,
# fixed amount of memory, and -- unlike a Bloom filter -- entries can be removed.

my @stream = qw(
    apple banana apple cherry date apple banana
    elderberry fig cherry grape apple fig date
);

my $cf = Data::CuckooFilter::Shared->new(undef, 1000);

print "first time each item is seen (dedup):\n";
for my $item (@stream) {
    if ($cf->contains($item)) {
        print "  seen: $item\n";
    } else {
        $cf->add($item);              # remember it the first time only
        print "  new:  $item\n";
    }
}

# membership queries afterwards
print "\nmembership queries:\n";
for my $q (qw(apple kiwi banana mango)) {
    printf "  contains(%-7s): %s\n", $q, $cf->contains($q) ? "probably yes" : "definitely no";
}

# Cuckoo filters support delete -- forget an item, then re-detect it as new.
$cf->remove("apple");
printf "\nafter remove('apple'): contains(apple) = %s\n",
    $cf->contains("apple") ? "probably yes" : "definitely no";

my $st = $cf->stats;
printf "\nfilter: capacity %d, %d buckets, %d slots\n",
    @{$st}{qw(capacity buckets slots)};
printf "stored %d / %d (fill %.4f), memory %d bytes\n",
    @{$st}{qw(count slots fill_ratio mmap_size)};
