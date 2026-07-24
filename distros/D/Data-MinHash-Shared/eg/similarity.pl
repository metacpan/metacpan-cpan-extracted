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
use Data::MinHash::Shared;

# Estimate the Jaccard similarity of two sets from their MinHash sketches, and
# compare the estimate against the exact value.  A MinHash sketch summarises a
# set in a fixed k*8 bytes, no matter how big the set is, and two sketches with
# the same k can be compared in O(k) regardless of set size.

my $k = 512;   # more registers -> tighter estimate (std error ~ 1/sqrt(k))

sub union { my %u; $u{$_} = 1 for @{$_[0]}, @{$_[1]}; return keys %u }

sub exact_jaccard {
    my ($a, $b) = @_;
    my %in_a = map { $_ => 1 } @$a;
    my $inter = grep { $in_a{$_} } @$b;
    return $inter / scalar(union($a, $b));
}

sub sketch_of {
    my @elems = @_;
    my $mh = Data::MinHash::Shared->new(undef, $k);
    $mh->add($_) for @elems;
    return $mh;
}

# three overlapping sets of shingles
my @a = (1 .. 1000);
my @b = (700 .. 1700);      # overlaps a on 700..1000
my @c = (1 .. 950);         # almost all of a

printf "MinHash sketches with k=%d registers (%d bytes of registers each)\n\n",
    $k, $k * 8;

for my $pair (['A', \@a, 'B', \@b], ['A', \@a, 'C', \@c], ['B', \@b, 'C', \@c]) {
    my ($na, $sa, $nb, $sb) = @$pair;
    my $est   = sketch_of(@$sa)->similarity(sketch_of(@$sb));
    my $exact = exact_jaccard($sa, $sb);
    printf "J(%s,%s): estimate %.3f   exact %.3f   error %+.3f\n",
        $na, $nb, $est, $exact, $est - $exact;
}

# merge is the sketch of the union: sim(A union B, C) uses one merged sketch
my $ab = sketch_of(@a);
$ab->merge(sketch_of(@b));
printf "\nA merged with B: %d/%d registers filled\n", $ab->filled, $ab->size;
printf "J(A union B, C): estimate %.3f   exact %.3f\n",
    $ab->similarity(sketch_of(@c)), exact_jaccard([union(\@a, \@b)], \@c);
