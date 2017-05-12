use warnings;
use strict;

use Test::More tests => 30;

BEGIN { use_ok "Data::Float", qw(
	have_signed_zero have_subnormal have_infinite have_nan
	significand_bits significand_step
	max_finite_exp max_finite_pow2 max_finite
	max_number max_integer
	min_normal_exp min_normal
	min_finite_exp min_finite
); }

foreach (significand_bits, max_finite_exp, max_finite_pow2, max_finite,
		max_number, max_integer, min_normal_exp, min_finite_exp) {
	ok int($_) == $_;
}

my $a = 1;
for(my $i = max_finite_exp; $i-- > 0; ) { $a += $a; }
is $a, max_finite_pow2;
ok max_finite > max_finite_pow2;
ok max_finite - max_finite_pow2 < max_finite_pow2;

$a = 1;
for(my $i = min_normal_exp; $i++ < 0; ) { $a *= 0.5; }
is $a, min_normal;

$a = 1;
for(my $i = min_finite_exp; $i++ < 0; ) { $a *= 0.5; }
is $a, min_finite;

$a = 1;
for(my $i = significand_bits; $i-- > 0; ) { $a *= 0.5; }
is $a, significand_step;

$a = 1;
for(my $i = significand_bits+1; $i--; ) { $a += $a; }
is $a, max_integer;

if(have_subnormal) {
	ok min_finite_exp < min_normal_exp;
} else {
	ok min_finite_exp <= min_normal_exp;
}

ok max_integer - (max_integer-1) == 1;

ok +(min_finite * 0.5) * 2.0 != min_finite;

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }

if(have_signed_zero) {
	no strict "refs";
	is zpat(0.0), "+0-0+0";
	is zpat(-0.0), "-0+0-0";
	my $pos_zero = &{"Data::Float::pos_zero"};
	my $neg_zero = &{"Data::Float::neg_zero"};
	is zpat($pos_zero), "+0-0+0";
	is zpat($neg_zero), "-0+0-0";
	{
		no warnings "void";
		$pos_zero == $pos_zero;
		$neg_zero == $neg_zero;
	}
	$pos_zero = &{"Data::Float::pos_zero"};
	$neg_zero = &{"Data::Float::neg_zero"};
	is zpat($pos_zero), "+0-0+0";
	is zpat($neg_zero), "-0+0-0";
} else {
	is zpat(0.0), "+0+0+0";
	is zpat(-0.0), "+0+0+0";
	SKIP: { skip "no signed zeroes", 4; }
}

if(have_infinite) {
	no strict "refs";
	ok &{"Data::Float::pos_infinity"} > max_finite;
	ok &{"Data::Float::neg_infinity"} < -max_finite();
	ok max_number == &{"Data::Float::pos_infinity"};
	ok max_number > max_finite;
} else {
	SKIP: { skip "no infinities", 3; }
	ok max_number == max_finite;
}

SKIP: {
	skip "no NaNs", 1 unless have_nan;
	no strict "refs";
	my $nan = &{"Data::Float::nan"};
	ok $nan != $nan;
}

1;
