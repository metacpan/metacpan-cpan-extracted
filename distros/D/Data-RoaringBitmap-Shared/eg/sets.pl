#!/usr/bin/env perl
use strict;
use warnings;
use Data::RoaringBitmap::Shared;

# A small set-algebra demo. Build two integer sets -- "even users" and "premium
# users" -- as shared-memory Roaring bitmaps, then show their union and
# intersection cardinalities plus a few membership checks. Roaring bitmaps store
# such id sets compactly and combine them with fast in-place set operations.

# everyone with an even id in 0..99999  (a dense set -> bitmap containers)
my $even = Data::RoaringBitmap::Shared->new(undef, 4096);
$even->add_many([ map { $_ * 2 } 0 .. 49999 ]);

# a scattered "premium" cohort  (sparse -> array containers, plus some overlap)
my $premium = Data::RoaringBitmap::Shared->new(undef, 4096);
$premium->add_many([ map { $_ * 333 } 0 .. 600 ]);   # 0, 333, 666, ...

printf "even users:    %d\n", $even->cardinality;
printf "premium users: %d\n", $premium->cardinality;
printf "even range:    [%d .. %d]\n", $even->min, $even->max;

# intersection: premium users who also have an even id (a fresh clone of premium)
my $both = Data::RoaringBitmap::Shared->new(undef, 4096);
$both->add_many($premium->to_array);
$both->intersect($even);
printf "\npremium AND even: %d users\n", $both->cardinality;

# union: everyone who is even OR premium (a fresh clone of even)
my $either = Data::RoaringBitmap::Shared->new(undef, 4096);
$either->add_many($even->to_array);
$either->union($premium);
printf "premium OR  even: %d users\n", $either->cardinality;

# a few membership probes
print "\nmembership checks:\n";
for my $id (0, 333, 666, 1000, 99998, 99999) {
    printf "  id %-6d  even=%-3s premium=%-3s\n",
        $id,
        ($even->contains($id)    ? 'yes' : 'no'),
        ($premium->contains($id) ? 'yes' : 'no');
}

my $st = $either->stats;
printf "\nunion bitmap: cardinality=%d containers=%d/%d buckets=%d mmap=%d bytes\n",
    $st->{cardinality}, $st->{containers_used}, $st->{containers_capacity},
    $st->{buckets_used}, $st->{mmap_size};
