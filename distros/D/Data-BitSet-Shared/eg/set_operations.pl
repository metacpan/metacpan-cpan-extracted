#!/usr/bin/env perl
# Set operations: intersection, union, difference via two bitsets
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::BitSet::Shared;
$| = 1;

my $cap = 32;
my $a = Data::BitSet::Shared->new(undef, $cap);
my $b = Data::BitSet::Shared->new(undef, $cap);

# set A = {1, 2, 3, 5, 8, 13}
$a->set($_) for (1, 2, 3, 5, 8, 13);

# set B = {2, 3, 5, 7, 11, 13}
$b->set($_) for (2, 3, 5, 7, 11, 13);

printf "A = {%s}\n", join(', ', $a->set_bits);
printf "B = {%s}\n", join(', ', $b->set_bits);

# intersection: elements in both A and B
my $inter = Data::BitSet::Shared->new(undef, $cap);
for my $i ($a->set_bits) {
    $inter->set($i) if $b->test($i);
}
printf "A ∩ B = {%s}\n", join(', ', $inter->set_bits);

# union: elements in A or B
my $union = Data::BitSet::Shared->new(undef, $cap);
$union->set($_) for $a->set_bits;
$union->set($_) for $b->set_bits;
printf "A ∪ B = {%s}\n", join(', ', $union->set_bits);

# difference: elements in A but not B
my $diff = Data::BitSet::Shared->new(undef, $cap);
for my $i ($a->set_bits) {
    $diff->set($i) unless $b->test($i);
}
printf "A \\ B = {%s}\n", join(', ', $diff->set_bits);

# symmetric difference: elements in A xor B
my $sym = Data::BitSet::Shared->new(undef, $cap);
for my $i (0..$cap-1) {
    $sym->set($i) if $a->test($i) != $b->test($i);
}
printf "A △ B = {%s}\n", join(', ', $sym->set_bits);
