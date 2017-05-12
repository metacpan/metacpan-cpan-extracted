use warnings;
use strict;

use Test::More tests => 65;

BEGIN { use_ok "Data::Float", qw(
	nextup nextdown nextafter
	have_signed_zero have_infinite have_nan
	significand_bits min_finite max_finite max_number
	float_is_nan pow2
); }

ok nextup(   1)     == 1 + pow2(-significand_bits());
ok nextafter(1, +9) == 1 + pow2(-significand_bits());
ok nextdown( 1)     ==
	(1-pow2(-significand_bits())) + pow2(-significand_bits()-1);
ok nextafter(1, -9) ==
	(1-pow2(-significand_bits())) + pow2(-significand_bits()-1);

ok nextup(   3.5)     == 3.5 + pow2(1-significand_bits());
ok nextafter(3.5, +9) == 3.5 + pow2(1-significand_bits());
ok nextdown( 3.5)     == 3.5 - pow2(1-significand_bits());
ok nextafter(3.5, -9) == 3.5 - pow2(1-significand_bits());

ok nextafter(1.2, 1.2) == 1.2;
ok nextup(max_number) == max_number;
ok nextdown(-max_number()) == -max_number();

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
my($za, $zb, $r);

if(have_signed_zero) {
	$za = +0.0; $zb = +0.0; $r = nextafter($za, $zb);
	is zpat($za), "+0-0+0"; is zpat($zb), "+0-0+0";
	is zpat($r), "+0-0+0"; ok $r == 0;
	$za = -0.0; $zb = +0.0; $r = nextafter($za, $zb);
	is zpat($za), "-0+0-0"; is zpat($zb), "+0-0+0";
	is zpat($r), "+0-0+0"; ok $r == 0;
	$za = +0.0; $zb = -0.0; $r = nextafter($za, $zb);
	is zpat($za), "+0-0+0"; is zpat($zb), "-0+0-0";
	is zpat($r), "-0+0-0"; ok $r == 0;
	$za = -0.0; $zb = -0.0; $r = nextafter($za, $zb);
	is zpat($za), "-0+0-0"; is zpat($zb), "-0+0-0";
	is zpat($r), "-0+0-0"; ok $r == 0;
} else {
	$za = 0; $zb = 0; $r = nextafter($za, $zb);
	is zpat($za), "+0+0+0"; is zpat($zb), "+0+0+0";
	is zpat($r), "+0+0+0"; ok $r == 0;
	SKIP: { skip "no signed zero", 12; }
}

$za = +0.0; ok nextup(   $za)     == +min_finite(); is zpat($za), zpat(+0.0);
$za = +0.0; ok nextafter($za, +9) == +min_finite(); is zpat($za), zpat(+0.0);
$za = +0.0; ok nextdown( $za)     == -min_finite(); is zpat($za), zpat(+0.0);
$za = +0.0; ok nextafter($za, -9) == -min_finite(); is zpat($za), zpat(+0.0);
SKIP: {
	skip "negative zero not available", 8 unless have_signed_zero;
	$za = -0.0; ok nextup(   $za)     == +min_finite();
	is zpat($za), zpat(-0.0);
	$za = -0.0; ok nextafter($za, +9) == +min_finite();
	is zpat($za), zpat(-0.0);
	$za = -0.0; ok nextdown( $za)     == -min_finite();
	is zpat($za), zpat(-0.0);
	$za = -0.0; ok nextafter($za, -9) == -min_finite();
	is zpat($za), zpat(-0.0);
}

$r = nextup(   -min_finite());     is zpat($r), zpat(-0.0); ok $r == 0.0;
$r = nextafter(-min_finite(), +9); is zpat($r), zpat(-0.0); ok $r == 0.0;
$r = nextdown( +min_finite());     is zpat($r), zpat(+0.0); ok $r == 0.0;
$r = nextafter(+min_finite(), -9); is zpat($r), zpat(+0.0); ok $r == 0.0;

SKIP: {
	skip "infinities not available", 8 unless have_infinite;
	no strict "refs";
	my $pinf = &{"Data::Float::pos_infinity"};
	my $ninf = &{"Data::Float::neg_infinity"};
	ok nextup(   +max_finite())        == $pinf;
	ok nextafter(+max_finite(), $pinf) == $pinf;
	ok nextdown( -max_finite())        == $ninf;
	ok nextafter(-max_finite(), $ninf) == $ninf;
	ok nextup(   $ninf)        == -max_finite();
	ok nextafter($ninf, $pinf) == -max_finite();
	ok nextdown( $pinf)        == +max_finite();
	ok nextafter($pinf, $ninf) == +max_finite();
}

SKIP: {
	skip "NaN not available", 5 unless have_nan;
	no strict "refs";
	my $nan = &{"Data::Float::nan"};
	ok float_is_nan(nextup($nan));
	ok float_is_nan(nextdown($nan));
	ok float_is_nan(nextafter($nan, +9));
	ok float_is_nan(nextafter(+1.2, $nan));
	ok float_is_nan(nextafter($nan, $nan));
}

1;
