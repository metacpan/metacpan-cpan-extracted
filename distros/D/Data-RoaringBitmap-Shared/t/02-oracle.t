use strict;
use warnings;
use Test::More;
use Data::RoaringBitmap::Shared;

# Deterministic oracle. No RNG, no sleep: two fixed integer sets A and B are
# built in both the XS Roaring bitmap and a pure-Perl reference (a plain %hash
# set). Each set deliberately mixes DENSE clusters (which the bitmap promotes to
# bitmap containers) and SPARSE scattered values (array containers), so the
# set-op code exercises every container-type combination. Every observable --
# cardinality, membership, to_array, min, max, union, intersect -- is checked
# against the pure-Perl reference.

# Generous capacity so the oracle never hits exhaustion.
my $CAP = 4096;

# ---- build the two reference sets deterministically ----
my (%refA, %refB);

# Set A:
#   - dense cluster 0..3000          (bucket 0, becomes a bitmap)
#   - dense cluster 200000..205000   (buckets 3..4, becomes bitmaps)
#   - sparse scatter i*9973 for i=0..400 (spread across many buckets -> arrays)
$refA{$_} = 1 for 0 .. 3000;
$refA{$_} = 1 for 200000 .. 205000;
$refA{ $_ * 9973 } = 1 for 0 .. 400;

# Set B (overlapping A in places):
#   - dense cluster 1500..4500       (overlaps A's bucket-0 cluster, extends past it)
#   - dense cluster 204000..206000   (overlaps A's 200000..205000 cluster tail)
#   - sparse scatter i*9973+1 for i=0..400 (mostly disjoint from A's scatter)
#   - a few exact shared points
$refB{$_} = 1 for 1500 .. 4500;
$refB{$_} = 1 for 204000 .. 206000;
$refB{ $_ * 9973 + 1 } = 1 for 0 .. 400;
$refB{$_} = 1 for (0, 3000, 200000, 9973 * 7);   # explicit overlaps with A

# ---- helper: build a fresh XS bitmap from a reference hash ----
sub build_from {
    my ($ref) = @_;
    my $bm = Data::RoaringBitmap::Shared->new(undef, $CAP);
    $bm->add_many([ keys %$ref ]);
    return $bm;
}

my $A = build_from(\%refA);
my $B = build_from(\%refB);

# ---- (a) cardinality matches keys %ref ----
is $A->cardinality, scalar(keys %refA), 'cardinality(A) == distinct keys of refA';
is $B->cardinality, scalar(keys %refB), 'cardinality(B) == distinct keys of refB';

# ---- (b) membership matches for a deterministic probe set ----
{
    my @probes = (
        0, 1, 1500, 3000, 3001, 4500, 4501,
        199999, 200000, 205000, 205001, 206000, 206001,
        9973, 9973 * 7, 9973 * 400, 9973 * 401,
        9973 * 7 + 1, 70000, 140000, 4294967295,
    );
    my ($abad, $bbad) = (0, 0);
    for my $x (@probes) {
        $abad++ if !!$A->contains($x) != !!exists $refA{$x};
        $bbad++ if !!$B->contains($x) != !!exists $refB{$x};
    }
    is $abad, 0, 'contains(A) matches refA for every probe';
    is $bbad, 0, 'contains(B) matches refB for every probe';
}

# ---- (c) to_array(A) sorted == sorted keys %refA ----
is_deeply $A->to_array, [ sort { $a <=> $b } keys %refA ], 'to_array(A) == sorted refA';
is_deeply $B->to_array, [ sort { $a <=> $b } keys %refB ], 'to_array(B) == sorted refB';

# ---- (d) min / max == min / max key ----
{
    my @sa = sort { $a <=> $b } keys %refA;
    is $A->min, $sa[0],  'min(A) == smallest key';
    is $A->max, $sa[-1], 'max(A) == largest key';
    my @sb = sort { $a <=> $b } keys %refB;
    is $B->min, $sb[0],  'min(B) == smallest key';
    is $B->max, $sb[-1], 'max(B) == largest key';
}

# ---- (e) union: clone A, union with B, compare to the Perl-hash union ----
{
    my %refU = (%refA, %refB);    # set union of the two reference hashes
    my $U = build_from(\%refA);   # clone A from scratch
    $U->union($B);
    is $U->cardinality, scalar(keys %refU), 'cardinality(A | B) == |refA U refB|';
    is_deeply $U->to_array, [ sort { $a <=> $b } keys %refU ], 'to_array(A | B) == sorted union';
    # spot-check a sample of memberships
    my $bad = 0;
    for my $x (0 .. 3000, 4000, 4500, 206000, map { $_ * 9973 } 0 .. 50) {
        $bad++ if !!$U->contains($x) != !!exists $refU{$x};
    }
    is $bad, 0, 'union membership sample matches the reference union';
    # A and B themselves are unchanged by the (cloned) union
    is $A->cardinality, scalar(keys %refA), 'A unchanged after union of a clone';
    is $B->cardinality, scalar(keys %refB), 'B unchanged after union of a clone';
}

# ---- (f) intersect: clone A, intersect B, compare to the Perl-hash intersection ----
{
    my %refI = map { exists $refB{$_} ? ($_ => 1) : () } keys %refA;
    my $I = build_from(\%refA);   # clone A
    $I->intersect($B);
    is $I->cardinality, scalar(keys %refI), 'cardinality(A & B) == |refA n refB|';
    is_deeply $I->to_array, [ sort { $a <=> $b } keys %refI ], 'to_array(A & B) == sorted intersection';
    my $bad = 0;
    for my $x (0 .. 4500, 200000 .. 200010, map { $_ * 9973 } 0 .. 50) {
        $bad++ if !!$I->contains($x) != !!exists $refI{$x};
    }
    is $bad, 0, 'intersect membership sample matches the reference intersection';
}

# ---- (g) union then intersect chaining on a fresh clone returns to A ----
# (A | B) & A == A  -- a basic absorption identity
{
    my $X = build_from(\%refA);
    $X->union($B)->intersect($A);
    is_deeply $X->to_array, [ sort { $a <=> $b } keys %refA ],
        '(A | B) & A == A (chained ops, absorption law)';
}

# ---- container mix sanity: A must use both array and bitmap containers ----
{
    my $st = $A->stats;
    cmp_ok $st->{buckets_used}, '>', 1, 'A spans multiple buckets';
    cmp_ok $st->{containers_used}, '<=', $st->{containers_capacity}, 'containers within capacity';
    diag sprintf "oracle A: cardinality=%d containers_used=%d/%d buckets_used=%d",
        $st->{cardinality}, $st->{containers_used}, $st->{containers_capacity}, $st->{buckets_used};
    my $stb = $B->stats;
    diag sprintf "oracle B: cardinality=%d containers_used=%d buckets_used=%d",
        $stb->{cardinality}, $stb->{containers_used}, $stb->{buckets_used};
}

done_testing;
