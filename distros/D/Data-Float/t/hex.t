use warnings;
use strict;

use Test::More tests => 102;

BEGIN { use_ok "Data::Float", qw(
	float_hex hex_float
	have_signed_zero have_infinite have_nan float_is_nan
); }

my %str_opt = (
	exp_neg_sign => "(ENS)", exp_pos_sign => "(EPS)",
	hex_prefix_string => "(HEX)",
	infinite_string => "(INF)", nan_string => "(NAN)",
	neg_sign => "(VNS)", pos_sign => "(VPS)",
	zero_strategy => "STRING=(ZERO)",
);

SKIP: {
	skip "no infinities", 22 unless have_infinite;
	no strict "refs";
	my $pinf = &{"Data::Float::pos_infinity"};
	my $ninf = &{"Data::Float::neg_infinity"};
	is float_hex($pinf), "+inf";
	is float_hex($ninf), "-inf";
	is float_hex($pinf, \%str_opt), "(VPS)(INF)";
	is float_hex($ninf, \%str_opt), "(VNS)(INF)";
	ok hex_float("inf") == $pinf;
	ok hex_float("Inf") == $pinf;
	ok hex_float("iNf") == $pinf;
	ok hex_float("+inf") == $pinf;
	ok hex_float("+Inf") == $pinf;
	ok hex_float("+iNf") == $pinf;
	ok hex_float("-inf") == $ninf;
	ok hex_float("-Inf") == $ninf;
	ok hex_float("-iNf") == $ninf;
	ok hex_float("infinity") == $pinf;
	ok hex_float("Infinity") == $pinf;
	ok hex_float("iNfiniTy") == $pinf;
	ok hex_float("+infinity") == $pinf;
	ok hex_float("+Infinity") == $pinf;
	ok hex_float("+iNfiniTy") == $pinf;
	ok hex_float("-infinity") == $ninf;
	ok hex_float("-Infinity") == $ninf;
	ok hex_float("-iNfiniTy") == $ninf;
}

SKIP: {
	skip "no NaN", 20 unless have_nan;
	no strict "refs";
	is float_hex(&{"Data::Float::nan"}), "nan";
	is float_hex(&{"Data::Float::nan"}, \%str_opt), "(NAN)";
	ok float_is_nan(hex_float("nan"));
	ok float_is_nan(hex_float("Nan"));
	ok float_is_nan(hex_float("nAn"));
	ok float_is_nan(hex_float("+nan"));
	ok float_is_nan(hex_float("+Nan"));
	ok float_is_nan(hex_float("+nAn"));
	ok float_is_nan(hex_float("-nan"));
	ok float_is_nan(hex_float("-Nan"));
	ok float_is_nan(hex_float("-nAn"));
	ok float_is_nan(hex_float("snan"));
	ok float_is_nan(hex_float("sNan"));
	ok float_is_nan(hex_float("SnAn"));
	ok float_is_nan(hex_float("+snan"));
	ok float_is_nan(hex_float("+sNan"));
	ok float_is_nan(hex_float("+SnAn"));
	ok float_is_nan(hex_float("-snan"));
	ok float_is_nan(hex_float("-sNan"));
	ok float_is_nan(hex_float("-SnAn"));
}

my %opt = ( frac_digits_bits_mod => "IGNORE" );
foreach([ +1, "+0x1p+0" ],
	[ +3.75, "+0x1.ep+1" ],
	[ -3.75, "-0x1.ep+1" ],
	[ +0.375, "+0x1.8p-2" ],
	[ +1.09375, "+0x1.18p+0" ],
) {
	my($val, $hex) = @$_;
	is float_hex($val, \%opt), $hex;
	ok hex_float($hex) == $val;
}

ok hex_float("1.ep1") == +3.75;
ok hex_float("3.c") == +3.75;
ok hex_float("1ep-3") == +3.75;
ok hex_float("0.01ep9") == +3.75;

foreach(1023013230.1, 1.23e30, 3.564e-30) {
	ok hex_float(float_hex($_)) == $_;
}

sub zpat($) { my($z) = @_; my $nz = -$z; sprintf("%+.f%+.f%+.f",$z,$nz,-$nz) }
my $z;

$z = 0; is float_hex($z), "+0.0"; is zpat($z), "+0+0+0";
SKIP: {
	skip "no signed zero", 4 unless have_signed_zero;
	$z = +0.0; is float_hex($z), "+0.0"; is zpat($z), "+0-0+0";
	$z = -0.0; is float_hex($z), "-0.0"; is zpat($z), "-0+0-0";
}
is float_hex(0, \%str_opt), "(VPS)(ZERO)";
like float_hex(0, { %str_opt, zero_strategy => "SUBNORMAL" }),
	qr/\A\(VPS\)\(HEX\)0\.0+p\(ENS\)[1-9][0-9]*\z/;
like float_hex(0, { %str_opt, zero_strategy => "EXPONENT=-33" }),
	qr/\A\(VPS\)\(HEX\)0\.0+p\(ENS\)33\z/;

$z = hex_float("0"); is zpat($z), zpat(+0.0); ok $z == 0.0;
$z = hex_float("+0"); is zpat($z), zpat(+0.0); ok $z == 0.0;
$z = hex_float("-0"); is zpat($z), zpat(-0.0); ok $z == 0.0;
$z = hex_float("0.0"); is zpat($z), zpat(+0.0); ok $z == 0.0;
$z = hex_float("+0.0"); is zpat($z), zpat(+0.0); ok $z == 0.0;
$z = hex_float("-0.0"); is zpat($z), zpat(-0.0); ok $z == 0.0;

like float_hex(2, { exp_digits => 5 }), qr/\A\+0x1\.0+p\+00001\z/;
like float_hex(2, { exp_digits_range_mod => "ATLEAST" }),
	qr/\A\+0x1\.0+p\+0+1\z/;

%opt = ( %str_opt, frac_digits_bits_mod => "IGNORE" );
is float_hex(+3.75, \%opt), "(VPS)(HEX)1.ep(EPS)1";
is float_hex(-3.75, \%opt), "(VNS)(HEX)1.ep(EPS)1";
is float_hex(+0.375, \%opt), "(VPS)(HEX)1.8p(ENS)2";
is float_hex(-0.375, \%opt), "(VNS)(HEX)1.8p(ENS)2";

is float_hex(+3.75, { frac_digits => 5, frac_digits_bits_mod => "IGNORE" }),
	"+0x1.e0000p+1";
is float_hex(+3.75, { frac_digits => 1, frac_digits_bits_mod => "IGNORE" }),
	"+0x1.ep+1";
is float_hex(+1.09375, { frac_digits => 5, frac_digits_bits_mod => "IGNORE" }),
	"+0x1.18000p+0";
is float_hex(+1.09375, { frac_digits => 2, frac_digits_bits_mod => "IGNORE" }),
	"+0x1.18p+0";
is float_hex(+1.09375, { frac_digits => 1, frac_digits_bits_mod => "IGNORE" }),
	"+0x1.18p+0";

%opt = ( frac_digits_bits_mod => "IGNORE", frac_digits_value_mod => "IGNORE" );
is float_hex(+1.09375, { %opt, frac_digits => 5 }), "+0x1.18000p+0";
is float_hex(+1.09375, { %opt, frac_digits => 2 }), "+0x1.18p+0";
is float_hex(+1.09375, { %opt, frac_digits => 1 }), "+0x1.2p+0";
is float_hex(+1.09375, { %opt, frac_digits => 0 }), "+0x1p+0";
is float_hex(+1.90625, { %opt, frac_digits => 5 }), "+0x1.e8000p+0";
is float_hex(+1.90625, { %opt, frac_digits => 2 }), "+0x1.e8p+0";
is float_hex(+1.90625, { %opt, frac_digits => 1 }), "+0x1.ep+0";
is float_hex(+1.90625, { %opt, frac_digits => 0 }), "+0x1p+1";

like float_hex(1, { exp_digits_range_mod => "ATLEAST" }),
	qr/\A\+0x1\.0+p\+00+\z/;
like float_hex(1, { exp_digits => 5 }), qr/\A\+0x1\.0+p\+00000\z/;

1;
