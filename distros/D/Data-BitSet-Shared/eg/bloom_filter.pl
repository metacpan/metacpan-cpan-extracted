#!/usr/bin/env perl
# Simple bloom filter using shared bitset
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::BitSet::Shared;
$| = 1;

my $size = 1024;
my $k = 3;  # hash functions

my $bloom = Data::BitSet::Shared->new(undef, $size);

sub bloom_add {
    my ($item) = @_;
    for my $i (0..$k-1) {
        my $h = _hash($item, $i) % $size;
        $bloom->set($h);
    }
}

sub bloom_test {
    my ($item) = @_;
    for my $i (0..$k-1) {
        my $h = _hash($item, $i) % $size;
        return 0 unless $bloom->test($h);
    }
    return 1;
}

sub _hash {
    my ($s, $seed) = @_;
    my $h = $seed * 0x9e3779b9;
    $h ^= ord($_) * 31 + $h for split //, $s;
    return $h & 0xFFFFFFFF;
}

# add some items
my @items = map { "item_$_" } 1..50;
bloom_add($_) for @items;

printf "bloom filter: %d bits, %d set (%.1f%% fill)\n",
    $size, $bloom->count, 100.0 * $bloom->count / $size;

# test membership
my $fp = 0;
for my $i (1..100) {
    my $item = "item_$i";
    my $in_set = $i <= 50;
    my $bloom_says = bloom_test($item);
    $fp++ if $bloom_says && !$in_set;
}
printf "false positives: %d/50 (%.1f%%)\n", $fp, $fp * 2.0;
