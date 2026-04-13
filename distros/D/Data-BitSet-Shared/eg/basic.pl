#!/usr/bin/env perl
# Basic bitset: set/clear/test/toggle, popcount, first_set/first_clear
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::BitSet::Shared;
$| = 1;

my $bs = Data::BitSet::Shared->new(undef, 64);

$bs->set(0);
$bs->set(10);
$bs->set(42);
$bs->set(63);

printf "bits set: %d\n", $bs->count;
printf "test(10): %d\n", $bs->test(10);
printf "test(11): %d\n", $bs->test(11);
printf "first_set: %d\n", $bs->first_set;
printf "toggle(10): new=%d\n", $bs->toggle(10);
printf "set_bits: %s\n", join(' ', $bs->set_bits);
printf "string: %s\n", $bs;
printf "\nstats: sets=%d clears=%d\n", $bs->stats->{sets}, $bs->stats->{clears};
