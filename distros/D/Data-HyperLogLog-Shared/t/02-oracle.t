use strict;
use warnings;
use Test::More;
use Data::HyperLogLog::Shared;

# Deterministic accuracy checks. No RNG, no sleep: the only entropy is the
# fixed XXH3 hash of fixed input strings, so results are reproducible.

sub rel_err { my ($est, $true) = @_; abs($est - $true) / $true }

# (a) 100k distinct strings at precision 14 (~0.81% std err -> 3-sigma ~2.4%).
{
    my $hll = Data::HyperLogLog::Shared->new(undef, 14);
    $hll->add("item-$_") for 0 .. 99_999;
    my $n = $hll->count;
    my $e = rel_err($n, 100_000);
    ok $e < 0.03, sprintf("100k distinct: estimate %d, rel err %.4f < 0.03", $n, $e);
}

# (b) small cardinality: 200 distinct -> exercises linear counting. Within 15%.
{
    my $hll = Data::HyperLogLog::Shared->new(undef, 14);
    $hll->add("small-$_") for 0 .. 199;
    my $n = $hll->count;
    my $e = rel_err($n, 200);
    ok $e < 0.15, sprintf("200 distinct (linear counting): estimate %d, rel err %.4f < 0.15", $n, $e);
}

# (c) idempotence: re-adding the same 100k barely changes the estimate (within 1%).
{
    my $hll = Data::HyperLogLog::Shared->new(undef, 14);
    $hll->add("dup-$_") for 0 .. 99_999;
    my $n1 = $hll->count;
    $hll->add("dup-$_") for 0 .. 99_999;   # exact same items again
    my $n2 = $hll->count;
    my $e = rel_err($n2, $n1);
    ok $e < 0.01, sprintf("idempotence: %d then %d, change %.5f < 0.01", $n1, $n2, $e);
    # adding the identical set must not move any register
    is $hll->add("dup-12345"), 0, 'a re-added item bumps no register';
}

# (d) merge of two disjoint 50k sets -> union ~= 100k within 3%.
{
    my $a = Data::HyperLogLog::Shared->new(undef, 14);
    my $b = Data::HyperLogLog::Shared->new(undef, 14);
    $a->add("A-$_") for 0 .. 49_999;
    $b->add("B-$_") for 0 .. 49_999;
    $a->merge($b);
    my $n = $a->count;
    my $e = rel_err($n, 100_000);
    ok $e < 0.03, sprintf("merge of disjoint 50k+50k: union %d, rel err %.4f < 0.03", $n, $e);
}

# (e) precision 12 and 16 both estimate 10k within their error bands.
#     std err ~ 1.04/sqrt(m); use a generous 4-sigma band to stay deterministic-safe.
{
    for my $p (12, 16) {
        my $m   = 1 << $p;
        my $se  = 1.04 / sqrt($m);          # relative std error
        my $tol = 4 * $se;                  # 4-sigma band
        my $hll = Data::HyperLogLog::Shared->new(undef, $p);
        $hll->add("p$p-$_") for 0 .. 9_999;
        my $n = $hll->count;
        my $e = rel_err($n, 10_000);
        ok $e < $tol,
            sprintf("precision %d: 10k -> est %d, rel err %.4f < %.4f (4 sigma)", $p, $n, $e, $tol);
    }
}

done_testing;
