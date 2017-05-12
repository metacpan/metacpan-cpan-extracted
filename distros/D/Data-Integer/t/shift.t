use warnings;
use strict;

use Test::More tests => 1 + 2*21 + 1*17 + 1*17 + 4*21;

BEGIN { use_ok "Data::Integer", qw(
	sint_shl uint_shl
	sint_shr uint_shr
	sint_rol uint_rol
	sint_ror uint_ror
	uint_bits_as_sint natint_bits min_sint
); }

sub nint_is($$) {
	my($tval, $cval) = @_;
	my $tval0 = $tval;
	ok defined($tval) && ref(\$tval) eq "SCALAR" &&
		int($tval0) == $tval0 && "$tval" eq "$cval" &&
		((my $tval1 = $tval) <=> 0) == ((my $cval1 = $cval) <=> 0) &&
		do { use integer; $tval == $cval },
		"$tval match $cval";
}

my $bm1 = min_sint|0;
my $bm2 = $bm1 >> 1;
my $bm3 = $bm2 >> 1;
my $bm4 = $bm3 >> 1;

foreach([ 0, 0, 0 ],
	[ 0, 1, 0 ],
	[ 0, 16, 0 ],
	[ 0, natint_bits-1, 0 ],
	[ 1, 0, 1 ],
	[ 1, 1, 2 ],
	[ 1, 5, 32 ],
	[ 1, natint_bits-1, $bm1 ],
	[ 2, 0, 2 ],
	[ 2, 1, 4 ],
	[ 2, 5, 64 ],
	[ 2, natint_bits-2, $bm1 ],
	[ 2, natint_bits-1, 0 ],
	[ 3, 0, 3 ],
	[ 3, 1, 6 ],
	[ 3, 5, 96 ],
	[ 3, natint_bits-1, $bm1 ],
	[ 0x123, 0, 0x123 ],
	[ 0x123, 4, 0x1230 ],
	[ $bm1|0x123, 0, $bm1|0x123 ],
	[ $bm1|0x123, 4, 0x1230 ],
) {
	my($ua, $dist, $ur) = @$_;
	nint_is uint_shl($ua, $dist), $ur;
	my($sa, $sr) = (uint_bits_as_sint($ua), uint_bits_as_sint($ur));
	nint_is sint_shl($sa, $dist), $sr;
}

foreach([ 0, 1, 0 ],
	[ 0, 16, 0 ],
	[ 0, natint_bits-1, 0 ],
	[ 1, 1, 0 ],
	[ 1, 16, 0 ],
	[ 1, natint_bits-1, 0 ],
	[ 0xa5c0, 1, 0x52e0 ],
	[ 0xa5c0, 4, 0xa5c ],
	[ 0xa5c0, 8, 0xa5 ],
	[ 0xa5c0, 12, 0xa ],
	[ 0xa5c0, 16, 0 ],
	[ 0xa5c0, natint_bits-1, 0 ],
	[ $bm1, 1, $bm2 ],
	[ $bm1|6, 1, $bm2|3 ],
	[ $bm1, natint_bits-2, 2 ],
	[ $bm1|6, natint_bits-2, 2 ],
	[ $bm1|6, natint_bits-1, 1 ],
) {
	my($ua, $dist, $ur) = @$_;
	nint_is uint_shr($ua, $dist), $ur;
}

foreach([ 0, 1, 0 ],
	[ 0, 16, 0 ],
	[ 0, natint_bits-1, 0 ],
	[ 1, 1, 0 ],
	[ 1, 16, 0 ],
	[ 1, natint_bits-1, 0 ],
	[ 0xa5c0, 1, 0x52e0 ],
	[ 0xa5c0, 4, 0xa5c ],
	[ 0xa5c0, 8, 0xa5 ],
	[ 0xa5c0, 12, 0xa ],
	[ 0xa5c0, 16, 0 ],
	[ 0xa5c0, natint_bits-1, 0 ],
	[ uint_bits_as_sint($bm1), 1, uint_bits_as_sint($bm1|$bm2) ],
	[ uint_bits_as_sint($bm1|6), 1, uint_bits_as_sint($bm1|$bm2|3) ],
	[ uint_bits_as_sint($bm1), natint_bits-2, -2 ],
	[ uint_bits_as_sint($bm1|6), natint_bits-2, -2 ],
	[ uint_bits_as_sint($bm1|6), natint_bits-1, -1 ],
) {
	my($sa, $dist, $sr) = @$_;
	nint_is sint_shr($sa, $dist), $sr;
}

foreach([ 0, 0, 0 ],
	[ 0, 1, 0 ],
	[ 0, 16, 0 ],
	[ 0, -1, 0 ],
	[ 1, 0, 1 ],
	[ 1, 1, 2 ],
	[ 1, 5, 32 ],
	[ 1, -1, $bm1 ],
	[ 2, 0, 2 ],
	[ 2, 1, 4 ],
	[ 2, 5, 64 ],
	[ 2, -1, 1 ],
	[ 2, -2, $bm1 ],
	[ 2, -3, $bm2 ],
	[ 0x123, 4, 0x1230 ],
	[ 0x123, -4, 0x12|$bm3|$bm4 ],
	[ $bm2|$bm4, 0, $bm2|$bm4 ],
	[ $bm2|$bm4, 1, $bm1|$bm3 ],
	[ $bm2|$bm4, 2, 1|$bm2 ],
	[ $bm2|$bm4, 3, 2|$bm1 ],
	[ $bm2|$bm4, 4, 5 ],
) {
	my($ua, $dist, $ur) = @$_;
	my $ldist = (natint_bits + $dist) % natint_bits;
	my $rdist = (natint_bits - $dist) % natint_bits;
	nint_is uint_rol($ua, $ldist), $ur;
	nint_is uint_ror($ua, $rdist), $ur;
	my($sa, $sr) = (uint_bits_as_sint($ua), uint_bits_as_sint($ur));
	nint_is sint_rol($sa, $ldist), $sr;
	nint_is sint_ror($sa, $rdist), $sr;
}

1;
