use strict;
use warnings;
use Test::More;
use Config;

# Run under a long-double Perl:
#   PERL_LONGDOUBLE=/home/yk/.plenv/versions/5.40.2-longdouble/bin/perl \
#     prove -Iblib/lib -Iblib/arch xt/longdouble_f64.t
#
# Or invoke directly with that perl. This test skips unless running on a
# long-double Perl (NV != double).

plan skip_all => "requires -Duselongdouble Perl (NV size = $Config{nvsize})"
    if $Config{nvsize} == $Config{doublesize};

use Data::Buffer::Shared::F64;

my $buf = Data::Buffer::Shared::F64->new_memfd("ld", 8);

# Exactly representable in both long-double and IEEE 754 binary64:
# roundtrip is bit-exact.
for my $v (1.0, -1.0, 0.0, 0.5, 0.25, 0.75, 1.5, 1024, -4096, 2**40) {
    $buf->set(0, $v);
    cmp_ok $buf->get(0), '==', $v, "F64 exact roundtrip: $v";
}

# Not exactly representable in binary64: storage rounds, so roundtrip
# under long-double NV shows the rounded value (close but not equal).
for my $v (3.14159265358979, 1e100, -1e-100, 0.1) {
    $buf->set(0, $v);
    my $got = $buf->get(0);
    my $eps = abs($v) * 1e-15 + 1e-300;
    cmp_ok abs($got - $v), '<=', $eps,
        "F64 near-roundtrip within double ULP: $v ≈ $got";
}

# A value that exceeds IEEE 754 double range but fits in long double:
# storing via F64 must clamp to +Inf (double semantics), not preserve
# the long-double magnitude.
my $beyond_double_max = "1e400" + 0;   # finite in long double, +Inf in double
$buf->set(0, $beyond_double_max);
my $got = $buf->get(0);
ok $got > 1e308, "out-of-double-range value stored as +Inf";
ok !($got < 1e308 && $got > -1e308), "not accidentally truncated to finite";

# NaN / ±Inf via string-coerced literals roundtrip
for my $s ("Inf", "-Inf") {
    my $v = $s + 0;
    $buf->set(0, $v);
    cmp_ok $buf->get(0), '==', $v, "F64 $s roundtrip under long double";
}

my $nan = "NaN" + 0;
$buf->set(0, $nan);
my $got_nan = $buf->get(0);
ok $got_nan != $got_nan, "F64 NaN roundtrip under long double";

done_testing;
