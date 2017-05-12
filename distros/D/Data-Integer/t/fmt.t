use warnings;
use strict;

use Test::More tests => 1 + 4*5 + 6*4;

BEGIN { use_ok "Data::Integer", qw(
	nint_bits_as_sint nint_bits_as_uint
	sint_bits_as_uint uint_bits_as_sint
	max_sint max_uint min_sint
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

foreach(0, 1, 0x123, max_sint&~1, max_sint) {
	nint_is nint_bits_as_sint($_), $_;
	nint_is nint_bits_as_uint($_), $_;
	nint_is sint_bits_as_uint($_), $_;
	nint_is uint_bits_as_sint($_), $_;
}

foreach([ -1, max_uint ],
	[ -2, max_uint&~1 ],
	[ do { use integer; min_sint|1 }, min_sint|1 ],
	[ min_sint, min_sint|0 ],
) {
	my($si, $ui) = @$_;
	nint_is nint_bits_as_sint($si), $si;
	nint_is nint_bits_as_sint($ui), $si;
	nint_is nint_bits_as_uint($si), $ui;
	nint_is nint_bits_as_uint($ui), $ui;
	nint_is sint_bits_as_uint($si), $ui;
	nint_is uint_bits_as_sint($ui), $si;
}

1;
