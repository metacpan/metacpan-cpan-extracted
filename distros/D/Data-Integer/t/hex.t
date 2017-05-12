use warnings;
use strict;

use Test::More tests => 116;

BEGIN { use_ok "Data::Integer", qw(natint_hex hex_natint natint_bits); }

like natint_hex(0), qr/\A\+0x0{4,}\z/;
like natint_hex(+0.0), qr/\A\+0x0{4,}\z/;
like natint_hex(-0.0), qr/\A\+0x0{4,}\z/;
like natint_hex(0x1), qr/\A\+0x0+1\z/;
like natint_hex(0xf), qr/\A\+0x0+f\z/;
like natint_hex(0x12ab), qr/\A\+0x0*12ab\z/;
like natint_hex(-0x1), qr/\A\-0x0+1\z/;
like natint_hex(-0xf), qr/\A\-0x0+f\z/;
like natint_hex(-0x12ab), qr/\A\-0x0*12ab\z/;

sub nint_is($$) {
	my($tval, $cval) = @_;
	my $tval0 = $tval;
	ok defined($tval) && ref(\$tval) eq "SCALAR" &&
		int($tval0) == $tval0 && "$tval" eq "$cval" &&
		((my $tval1 = $tval) <=> 0) == ((my $cval1 = $cval) <=> 0) &&
		do { use integer; $tval == $cval },
		"$tval match $cval";
}

sub zpat($) { my($z) = @_; sprintf("%+.f%+.f%+.f", $z, -$z, - -$z) }
my $z;
$z = hex_natint("0"); is zpat($z), "+0+0+0"; nint_is $z, 0;
$z = hex_natint("+0"); is zpat($z), "+0+0+0"; nint_is $z, 0;
$z = hex_natint("-0"); is zpat($z), "+0+0+0"; nint_is $z, 0;

nint_is hex_natint("b"), 11;
nint_is hex_natint("B"), 11;
nint_is hex_natint("00B"), 11;

nint_is hex_natint("0x0012"), 18;
nint_is hex_natint("0012"), 18;
nint_is hex_natint("0x12"), 18;
nint_is hex_natint("12"), 18;
nint_is hex_natint("+0x0012"), 18;
nint_is hex_natint("+0012"), 18;
nint_is hex_natint("+0x12"), 18;
nint_is hex_natint("+12"), 18;
nint_is hex_natint("-0x0012"), -18;
nint_is hex_natint("-0012"), -18;
nint_is hex_natint("-0x12"), -18;
nint_is hex_natint("-12"), -18;

sub uns_shr($$) { no integer; $_[0] >> $_[1] }
sub sig_shr($$) { use integer; $_[0] >> $_[1] }
sub uns_shl($$) { no integer; $_[0] << $_[1] }
sub sig_shl($$) { use integer; $_[0] << $_[1] }
sub negate($) { use integer; -$_[0] }

my $tail_digits = uns_shr(natint_bits - 2, 2);
my $tval = uns_shl(1, natint_bits - 2) | 3;
my $head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint($head_digit.("0" x ($tail_digits-1))."3"), $tval;

$tval = ~uns_shl(1, natint_bits - 1);
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint($head_digit.("f" x $tail_digits)), $tval;

$tail_digits = uns_shr(natint_bits - 1, 2);
$tval = uns_shl(1, natint_bits - 1);
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint($head_digit.("0" x $tail_digits)), $tval;

$tval = uns_shl(~uns_shl(1, natint_bits - 1), 1);
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint($head_digit.("f" x ($tail_digits-1))."e"), $tval;

$tval = uns_shl(~uns_shl(1, natint_bits - 1), 1) | 1;
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint($head_digit.("f" x $tail_digits)), $tval;

for(my $i = 1; $i != 16; $i++) {
	my $over_digit = sprintf("%x", hex($head_digit) + $i);
	eval { hex_natint($over_digit.("0" x $tail_digits)) };
	like $@, qr/\Ainteger value too large/;
	eval { hex_natint($over_digit.("0" x ($tail_digits-1))."1") };
	like $@, qr/\Ainteger value too large/;
	eval { hex_natint($over_digit.("f" x $tail_digits)) };
	like $@, qr/\Ainteger value too large/;
}
for(my $i = 16; $i <= 256; $i += 16) {
	my $over_digit = sprintf("%x", hex($head_digit) + $i);
	eval { hex_natint($over_digit.("0" x $tail_digits)) };
	like $@, qr/\Ainteger value too large/;
}

$tail_digits = uns_shr(natint_bits - 2, 2);
$tval = uns_shl(1, natint_bits - 2) | 3;
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint("-".$head_digit.("0" x ($tail_digits-1))."3"),
	negate($tval);

$tval = ~uns_shl(1, natint_bits - 1);
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint("-".$head_digit.("f" x $tail_digits)), negate($tval);

$tail_digits = uns_shr(natint_bits - 1, 2);
$tval = sig_shl(1, natint_bits - 1);
$head_digit = sprintf("%x", uns_shr($tval, uns_shl($tail_digits, 2)));
nint_is hex_natint("-".$head_digit.("0" x $tail_digits)), $tval;

eval { hex_natint("-".$head_digit.("0" x ($tail_digits-1))."1") };
like $@, qr/\Ainteger value too large/;

for(my $i = 1; $i != 16; $i++) {
	my $over_digit = sprintf("%x", hex($head_digit) + $i);
	eval { hex_natint("-".$over_digit.("0" x $tail_digits)) };
	like $@, qr/\Ainteger value too large/;
}

1;
