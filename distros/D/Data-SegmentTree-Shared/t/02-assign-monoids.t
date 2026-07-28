use strict;
use warnings;
use Test::More;
use Data::SegmentTree::Shared;

# ----------------------------------------------------------------------------
# range_assign + gcd/product monoids, cross-checked against a brute-force array.
# ----------------------------------------------------------------------------

sub gcd2 { my ($x, $y) = (abs $_[0], abs $_[1]); ($x, $y) = ($y, $x % $y) while $y; $x }
sub arr_gcd { my $g = 0; $g = gcd2($g, $_) for @_; $g }
sub arr_sum { my $s = 0; $s += $_ for @_; $s }
sub arr_min { my $m = $_[0]; $m = $_ < $m ? $_ : $m for @_; $m }
sub arr_max { my $m = $_[0]; $m = $_ > $m ? $_ : $m for @_; $m }
# exact int64 product, or undef if it overflows int64 (detected with a float shadow)
sub arr_prod_or_ovf {
    my $p = 1; my $fp = 1.0;
    for (@_) { $p *= $_; $fp *= $_; }
    return abs($fp) > 9.0e18 ? undef : $p;
}

my $seed = 20260712;
srand($seed);

# ---- Oracle A: assign/set only -> sum/min/max/gcd exact vs brute force ----
{
    my $N = 40;
    my $t = Data::SegmentTree::Shared->new(undef, $N);
    my @ref = (0) x $N;
    my $bad = 0;
    for my $step (1 .. 400) {
        my ($l, $r) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        if (int(rand 2)) {
            my $v = int(rand 19) - 9;            # -9..9
            $t->range_assign($l, $r, $v);
            $ref[$_] = $v for $l .. $r;
        } else {
            my $i = int(rand $N);
            my $v = int(rand 19) - 9;
            $t->set($i, $v);
            $ref[$i] = $v;
        }
        my ($ql, $qr) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        my @slice = @ref[$ql .. $qr];
        $bad++ unless $t->sum($ql, $qr) == arr_sum(@slice)
                   && $t->min($ql, $qr) == arr_min(@slice)
                   && $t->max($ql, $qr) == arr_max(@slice)
                   && $t->gcd($ql, $qr) == arr_gcd(@slice);
    }
    is $bad, 0, 'oracle A: 400 assign/set steps match sum/min/max/gcd on random ranges';
    ok $t->monoids_valid, 'assign-only tree keeps the monoids valid';
}

# ---- Oracle B: product exact (small values) or croaks on overflow ----
{
    my $N = 40;
    my $t = Data::SegmentTree::Shared->new(undef, $N);
    my @ref = (0) x $N;
    my $bad = 0;
    for my $step (1 .. 300) {
        my ($l, $r) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        my $v = int(rand 5) - 2;                 # -2..2 (products stay clean powers of two)
        $t->range_assign($l, $r, $v);
        $ref[$_] = $v for $l .. $r;

        my ($ql, $qr) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        my $want = arr_prod_or_ovf(@ref[$ql .. $qr]);
        if (defined $want) {
            $bad++ unless $t->product($ql, $qr) == $want;
        } else {
            eval { $t->product($ql, $qr) };
            $bad++ unless $@ =~ /overflow/;
        }
    }
    is $bad, 0, 'oracle B: 300 assign steps match product (or croak on overflow) on random ranges';
}

# ---- Oracle C: mixed assign + add -> sum/min/max still exact ----
{
    my $N = 32;
    my $t = Data::SegmentTree::Shared->new(undef, $N);
    my @ref = (0) x $N;
    my $bad = 0;
    for my $step (1 .. 300) {
        my ($l, $r) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        my $k = int(rand 3);
        if ($k == 0) { my $v = int(rand 21) - 10; $t->range_assign($l, $r, $v); $ref[$_] = $v      for $l .. $r; }
        elsif ($k == 1) { my $d = int(rand 21) - 10; $t->range_add($l, $r, $d); $ref[$_] += $d      for $l .. $r; }
        else { my $i = int(rand $N); my $v = int(rand 21) - 10; $t->set($i, $v); $ref[$i] = $v; }
        my ($ql, $qr) = sort { $a <=> $b } (int(rand $N), int(rand $N));
        my @slice = @ref[$ql .. $qr];
        $bad++ unless $t->sum($ql, $qr) == arr_sum(@slice)
                   && $t->min($ql, $qr) == arr_min(@slice)
                   && $t->max($ql, $qr) == arr_max(@slice);
    }
    is $bad, 0, 'oracle C: 300 mixed assign/add/set steps match sum/min/max';
}

# ---- gcd/product gating around range_add + clear ----
{
    my $t = Data::SegmentTree::Shared->new(undef, 16);
    $t->range_assign(0, 15, 12);
    $t->set(3, 18);
    is $t->gcd(0, 15), 6, 'gcd(12.., 18) = 6';
    is $t->gcd(0, 0), 12, 'gcd of a single 12';
    ok $t->monoids_valid, 'monoids valid before any add';

    $t->range_add(5, 7, 1);                       # breaks gcd/product
    ok !$t->monoids_valid, 'monoids invalid after range_add';
    eval { $t->gcd(0, 15) };     like $@, qr/unavailable after range_add/, 'gcd croaks after range_add';
    eval { $t->product(0, 15) }; like $@, qr/unavailable after range_add/, 'product croaks after range_add';
    is $t->sum(0, 15), 16*12 + 6 + 3, 'sum still correct after the add';   # 16*12, pos3 +6, pos5-7 +1 each = 201

    $t->clear;
    ok $t->monoids_valid, 'clear restores monoid capability';
    is $t->gcd(0, 15), 0, 'gcd of all-zero cleared tree is 0';
}

# ---- gcd/product gating around POINT add() (oracle for the add_used=1 gate in add()) ----
{
    my $t = Data::SegmentTree::Shared->new(undef, 8);
    $t->range_assign(0, 7, 6);
    ok $t->monoids_valid, 'monoids valid after assign (point-add gate)';
    is $t->gcd(0, 7), 6, 'gcd before point add()';
    $t->add(3, 1);                                # POINT add() must also gate off gcd/product
    ok !$t->monoids_valid, 'point add() invalidates monoids';
    eval { $t->gcd(0, 7) };     like $@, qr/unavailable after range_add/, 'gcd croaks after point add()';
    eval { $t->product(0, 7) }; like $@, qr/unavailable after range_add/, 'product croaks after point add()';
}

# ---- product basics + overflow ----
{
    my $t = Data::SegmentTree::Shared->new(undef, 64);
    $t->range_assign(0, 4, 3);
    is $t->product(0, 4), 3**5, 'product of five 3s = 243';
    is $t->product(1, 3), 27,   'product of three 3s = 27';
    $t->set(2, 0);
    is $t->product(0, 4), 0,    'product with a zero is 0';

    $t->clear;
    $t->range_assign(0, 62, 2);                   # 2^63 overflows int64 (max 2^63-1)
    eval { $t->product(0, 62) };
    like $@, qr/overflow/, 'product overflow croaks (2^63)';
    is $t->product(0, 61), 1<<62, 'product 2^62 is fine';
}

# ---- assign/add persistence via reopen ----
{
    my $path = "/tmp/st-assign-$$-" . int(rand 1e6) . ".shm";
    unlink $path;
    { my $w = Data::SegmentTree::Shared->new($path, 20); $w->range_assign(0, 19, 7); $w->sync; }
    { my $r = Data::SegmentTree::Shared->new($path, 1);   # geometry ignored on reopen
      is $r->gcd(0, 19), 7, 'reopen: assigned value persists (gcd)';
      is $r->product(0, 1), 49, 'reopen: product persists'; }
    unlink $path;
}

# ---- regression: product with a zero must be 0 even if a sibling overflowed ----
{
    my $t = Data::SegmentTree::Shared->new(undef, 4);
    $t->set(0, 4000000000); $t->set(1, 4000000000);   # 4e9 * 4e9 overflows int64
    $t->set(2, 0);
    is $t->product(0, 2), 0, 'product is 0 when the range has a zero (sibling overflow ignored)';
    is $t->product(0, 3), 0, 'product 0 across the whole range containing a zero';
    eval { $t->product(0, 1) }; like $@, qr/overflow/, 'genuine overflow (no zero) still croaks';

    my $u = Data::SegmentTree::Shared->new(undef, 64);
    $u->range_assign(0, 30, 6); $u->set(30, 0);        # 6^30 overflows, but pos 30 is 0
    is $u->product(0, 30), 0, 'assign path: a zero collapses an overflowing product to 0';
}

# ---- regression: gcd of INT64_MIN is 2^63, returned as an unsigned magnitude ----
{
    my $t = Data::SegmentTree::Shared->new(undef, 4);
    my $imin = -9223372036854775807 - 1;               # INT64_MIN without the literal warning
    $t->set(0, $imin);
    is $t->gcd(0, 0), 9223372036854775808, 'gcd of INT64_MIN is 2^63 (unsigned, not negative)';
    $t->set(1, $imin); $t->set(2, 0);
    is $t->gcd(0, 2), 9223372036854775808, 'gcd of {INT64_MIN, INT64_MIN, 0} is 2^63';
    $t->set(3, 4);
    is $t->gcd(0, 3), 4, 'gcd with a 4 mixed in is 4 (magnitude re-abs works)';
}

done_testing;
