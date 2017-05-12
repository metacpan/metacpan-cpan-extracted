use warnings;
use strict;

use Test::More tests => 1 + 4*4 + (4*8 + 4*8 + 2*8)*2 + 4*8 + 4*8 + 4*5;

BEGIN { use_ok "Data::Integer", qw(
	sint_not uint_not
	sint_and uint_and
	sint_nand uint_nand
	sint_andn uint_andn
	sint_or uint_or
	sint_nor uint_nor
	sint_orn uint_orn
	sint_xor uint_xor
	sint_nxor uint_nxor
	sint_mux uint_mux
	uint_bits_as_sint max_uint min_sint max_sint
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

foreach([ 0, max_uint ],
	[ 1, max_uint&~1 ],
	[ 0x123, max_uint&~0x123 ],
	[ max_sint, min_sint|0 ],
) {
	my($ua, $ub) = @$_;
	nint_is uint_not($ua), $ub;
	nint_is uint_not($ub), $ua;
	my($sa, $sb) = (uint_bits_as_sint($ua), uint_bits_as_sint($ub));
	nint_is sint_not($sa), $sb;
	nint_is sint_not($sb), $sa;
}

foreach([ 0, 0, 0 ],
	[ 0x1234, 0, 0 ],
	[ 0x1234, 0xf0f0, 0x1030 ],
	[ 0x1234, 0x0f0f, 0x0204 ],
	[ min_sint|0, max_sint, 0 ],
	[ min_sint|0x1234, max_sint, 0x1234 ],
	[ min_sint|0x1234, min_sint|0xf0f0, min_sint|0x1030 ],
	[ max_uint&~0xff, 0x1234, 0x1200 ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_and($ua, $ub), $ur;
	nint_is uint_and($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_and($sa, $sb), $sr;
	nint_is sint_and($sb, $sa), $sr;
}

foreach([ 0, 0, max_uint ],
	[ 0x1234, 0, max_uint ],
	[ 0x1234, 0xf0f0, max_uint&~0x1030 ],
	[ 0x1234, 0x0f0f, max_uint&~0x0204 ],
	[ min_sint|0, max_sint, max_uint ],
	[ min_sint|0x1234, max_sint, max_uint&~0x1234 ],
	[ min_sint|0x1234, min_sint|0xf0f0, max_sint&~0x1030 ],
	[ max_uint&~0xff, 0x1234, max_uint&~0x1200 ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_nand($ua, $ub), $ur;
	nint_is uint_nand($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_nand($sa, $sb), $sr;
	nint_is sint_nand($sb, $sa), $sr;
}

foreach([ 0, 0, 0 ],
	[ 0x1234, 0, 0x1234 ],
	[ 0x1234, 0xf0f0, 0x0204 ],
	[ 0x1234, 0x0f0f, 0x1030 ],
	[ min_sint|0, max_sint, min_sint|0 ],
	[ min_sint|0x1234, max_sint, min_sint|0 ],
	[ min_sint|0x1234, min_sint|0xf0f0, 0x0204 ],
	[ max_uint&~0xff, 0x1234, max_uint&~0x12ff ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_andn($ua, $ub), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_andn($sa, $sb), $sr;
}

foreach([ 0, 0, 0 ],
	[ 0x1234, 0, 0x1234 ],
	[ 0x1234, 0xf0f0, 0xf2f4 ],
	[ 0x1234, 0x0f0f, 0x1f3f ],
	[ min_sint|0, max_sint, max_uint ],
	[ min_sint|0x1234, 0x0f0f, min_sint|0x1f3f ],
	[ min_sint|0x1234, min_sint|0xf0f0, min_sint|0xf2f4 ],
	[ max_uint&~0xff, 0x1234, max_uint&~0xcb ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_or($ua, $ub), $ur;
	nint_is uint_or($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_or($sa, $sb), $sr;
	nint_is sint_or($sb, $sa), $sr;
}

foreach([ 0, 0, max_uint ],
	[ 0x1234, 0, max_uint&~0x1234 ],
	[ 0x1234, 0xf0f0, max_uint&~0xf2f4 ],
	[ 0x1234, 0x0f0f, max_uint&~0x1f3f ],
	[ min_sint|0, max_sint, 0 ],
	[ min_sint|0x1234, 0x0f0f, max_sint&~0x1f3f ],
	[ min_sint|0x1234, min_sint|0xf0f0, max_sint&~0xf2f4 ],
	[ max_uint&~0xff, 0x1234, 0xcb ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_nor($ua, $ub), $ur;
	nint_is uint_nor($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_nor($sa, $sb), $sr;
	nint_is sint_nor($sb, $sa), $sr;
}

foreach([ 0, 0, max_uint ],
	[ 0x1234, 0, max_uint ],
	[ 0x1234, 0xf0f0, max_uint&~0xe0c0 ],
	[ 0x1234, 0x0f0f, max_uint&~0x0d0b ],
	[ min_sint|0, max_sint, min_sint|0 ],
	[ min_sint|0x1234, 0x0f0f, max_uint&~0x0d0b ],
	[ min_sint|0x1234, min_sint|0xf0f0, max_uint&~0xe0c0 ],
	[ max_uint&~0xff, 0x1234, max_uint&~0x34 ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_orn($ua, $ub), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_orn($sa, $sb), $sr;
}

foreach([ 0, 0, 0 ],
	[ 0x1234, 0, 0x1234 ],
	[ 0x1234, 0xf0f0, 0xe2c4 ],
	[ 0x1234, 0x0f0f, 0x1d3b ],
	[ min_sint|0, max_sint, max_uint ],
	[ min_sint|0x1234, 0x0f0f, min_sint|0x1d3b ],
	[ min_sint|0x1234, min_sint|0xf0f0, 0xe2c4 ],
	[ max_uint&~0xff, 0x1234, max_uint&~0x12cb ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_xor($ua, $ub), $ur;
	nint_is uint_xor($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_xor($sa, $sb), $sr;
	nint_is sint_xor($sb, $sa), $sr;
}

foreach([ 0, 0, max_uint ],
	[ 0x1234, 0, max_uint&~0x1234 ],
	[ 0x1234, 0xf0f0, max_uint&~0xe2c4 ],
	[ 0x1234, 0x0f0f, max_uint&~0x1d3b ],
	[ min_sint|0, max_sint, 0 ],
	[ min_sint|0x1234, 0x0f0f, max_sint&~0x1d3b ],
	[ min_sint|0x1234, min_sint|0xf0f0, max_uint&~0xe2c4 ],
	[ max_uint&~0xff, 0x1234, 0x12cb ],
) {
	my($ua, $ub, $ur) = @$_;
	nint_is uint_nxor($ua, $ub), $ur;
	nint_is uint_nxor($ub, $ua), $ur;
	my($sa, $sb, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_nxor($sa, $sb), $sr;
	nint_is sint_nxor($sb, $sa), $sr;
}

foreach([ 0, 0, 0, 0 ],
	[ 0, min_sint|0x1234, 0x8765, 0x8765 ],
	[ max_uint, min_sint|0x1234, 0x8765, min_sint|0x1234 ],
	[ 0xf0f0, min_sint|0x1234, 0x8765, 0x1735 ],
	[ max_uint&~0xf0f0, min_sint|0x1234, 0x8765, min_sint|0x8264 ],
) {
	my($ua, $ub, $uc, $ur) = @$_;
	nint_is uint_mux($ua, $ub, $uc), $ur;
	nint_is uint_mux(~$ua, $uc, $ub), $ur;
	my($sa, $sb, $sc, $sr) = map { uint_bits_as_sint($_) } @$_;
	nint_is sint_mux($sa, $sb, $sc), $sr;
	nint_is sint_mux(do { use integer; ~$sa }, $sc, $sb), $sr;
}

1;
