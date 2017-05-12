use warnings;
use strict;

use Test::More tests => 1 + 4*3 + 2*2 + 5*17;

BEGIN { use_ok "Data::Float", qw(
	have_signed_zero have_subnormal have_infinite
	min_normal_exp significand_bits mult_pow2
	float_sign signbit float_parts
); }

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
sub test_sign($$$) {
	my($val, $sign, $is_zero) = @_;
	my $tval = $val;
	is float_sign($tval), $sign;
	is zpat($tval), zpat($val) if $is_zero;
	$tval = $val;
	is signbit($val), $sign eq "-" ? 1 : 0;
	is zpat($tval), zpat($val) if $is_zero;
}
test_sign(0, "+", 1);
SKIP: {
	skip "no signed zero", 8 unless have_signed_zero;
	test_sign(+0.0, "+", 1);
	test_sign(-0.0, "-", 1);
}
SKIP: {
	skip "infinities not available", 4 unless have_infinite;
	no strict "refs";
	test_sign(&{"Data::Float::pos_infinity"}, "+", 0);
	test_sign(&{"Data::Float::neg_infinity"}, "-", 0);
}

sub test_parts($$$$) {
	my($val, $sign, $exp, $sgnf) = @_;
	is float_sign($val), $sign;
	is signbit($val), $sign eq "-" ? 1 : 0;
	my($tsign, $texp, $tsgnf) = float_parts($val);
	ok $tsign eq $sign;
	ok $texp == $exp;
	ok $tsgnf == $sgnf;
}

test_parts(+1, "+", 0, 1.0);
test_parts(+2, "+", 1, 1.0);
test_parts(+3, "+", 1, 1.5);
test_parts(-1, "-", 0, 1.0);
test_parts(-2, "-", 1, 1.0);
test_parts(-3, "-", 1, 1.5);

test_parts(+1.0, "+", 0, 1.0);
test_parts(+2.0, "+", 1, 1.0);
test_parts(+3.0, "+", 1, 1.5);
test_parts(+0.375, "+", -2, 1.5);
test_parts(-1.0, "-", 0, 1.0);
test_parts(-2.0, "-", 1, 1.0);
test_parts(-3.0, "-", 1, 1.5);
test_parts(-0.375, "-", -2, 1.5);

test_parts(+512.5, "+", 9, 1.0009765625);
test_parts(-0.078125, "-", -4, 1.25);

SKIP: {
	skip "subnormals not available", 5 unless have_subnormal;
	no strict "refs";
	test_parts(+3.0*&{"Data::Float::min_finite"},
		"+", min_normal_exp, mult_pow2(3.0, -significand_bits()));
}

1;
