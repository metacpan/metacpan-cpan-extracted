use warnings;
use strict;

use Test::More tests => 18;

BEGIN { use_ok "Data::Integer", qw(
	natint_bits
	min_nint max_nint min_natint max_natint
	min_sint max_sint min_signed_natint max_signed_natint
	min_uint max_uint min_unsigned_natint max_unsigned_natint
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

ok int(natint_bits) == natint_bits;
ok natint_bits >= 16;

use integer;

my $min_sint = -1;
for(my $i = natint_bits-1; $i--; ) { $min_sint += $min_sint; }
ok $min_sint < 0;
nint_is min_sint, $min_sint;
nint_is min_signed_natint, $min_sint;
nint_is min_nint, $min_sint;
nint_is min_natint, $min_sint;

nint_is min_sint + max_sint, -1;

nint_is min_uint, 0;
nint_is min_unsigned_natint, 0;

my $max_sint = min_sint - 1;
ok $max_sint > 0;
nint_is max_sint, $max_sint;
nint_is max_signed_natint, $max_sint;

no integer;

my $max_uint = $min_sint | $max_sint;
nint_is max_uint, $max_uint;
nint_is max_unsigned_natint, $max_uint;
nint_is max_nint, $max_uint;
nint_is max_natint, $max_uint;

1;
