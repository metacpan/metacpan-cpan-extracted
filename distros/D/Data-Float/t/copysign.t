use warnings;
use strict;

use Test::More tests => 46;

BEGIN { use_ok "Data::Float", qw(
	copysign
	have_signed_zero have_infinite have_nan significand_bits float_is_nan
); }

ok copysign(+1.2, +5) == +1.2;
ok copysign(-1.2, +5) == +1.2;
ok copysign(+1.2, -5) == -1.2;
ok copysign(-1.2, -5) == -1.2;

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
my($z, $r);

$z = 0; $r = copysign($z, +5);
is zpat($z), "+0+0+0"; is zpat($r), "+0+0+0"; ok $r == 0;
$z = 0; $r = copysign($z, -5);
is zpat($z), "+0+0+0"; is zpat($r), "+0+0+0"; ok $r == 0;
SKIP: {
	skip "no signed zero", 12 unless have_signed_zero;
	$z = +0.0; $r = copysign($z, +5);
	is zpat($z), "+0-0+0"; is zpat($r), "+0-0+0"; ok $r == 0;
	$z = -0.0; $r = copysign($z, +5);
	is zpat($z), "-0+0-0"; is zpat($r), "+0-0+0"; ok $r == 0;
	$z = +0.0; $r = copysign($z, -5);
	is zpat($z), "+0-0+0"; is zpat($r), "-0+0-0"; ok $r == 0;
	$z = -0.0; $r = copysign($z, -5);
	is zpat($z), "-0+0-0"; is zpat($r), "-0+0-0"; ok $r == 0;
}

$z = 0; ok copysign(+1.2, $z) == +1.2; is zpat($z), "+0+0+0";
$z = 0; ok copysign(-1.2, $z) == +1.2; is zpat($z), "+0+0+0";
SKIP: {
	skip "no signed zero", 8 unless have_signed_zero;
	$z = +0.0; ok copysign(+1.2, $z) == +1.2; is zpat($z), "+0-0+0";
	$z = +0.0; ok copysign(-1.2, $z) == +1.2; is zpat($z), "+0-0+0";
	$z = -0.0; ok copysign(+1.2, $z) == -1.2; is zpat($z), "-0+0-0";
	$z = -0.0; ok copysign(-1.2, $z) == -1.2; is zpat($z), "-0+0-0";
}

SKIP: {
	skip "infinities not available", 8 unless have_infinite;
	no strict "refs";
	my $pinf = &{"Data::Float::pos_infinity"};
	my $ninf = &{"Data::Float::neg_infinity"};
	ok copysign($pinf, +5) == $pinf;
	ok copysign($ninf, +5) == $pinf;
	ok copysign($pinf, -5) == $ninf;
	ok copysign($ninf, -5) == $ninf;
	ok copysign(+1.2, $pinf) == +1.2;
	ok copysign(-1.2, $pinf) == +1.2;
	ok copysign(+1.2, $ninf) == -1.2;
	ok copysign(-1.2, $ninf) == -1.2;
}

SKIP: {
	skip "NaN not available", 3 unless have_nan;
	no strict "refs";
	my $nan = &{"Data::Float::nan"};
	ok float_is_nan(copysign($nan, +5));
	ok float_is_nan(copysign($nan, $nan));
	ok abs(copysign(+1.2, $nan)) == 1.2;
}

1;
