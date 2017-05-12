use warnings;
use strict;

use Test::More tests => 1 + 5*16 + 3*3;

BEGIN { use_ok "Data::Integer", qw(
	nint sint uint
	nint_is_sint nint_is_uint
	min_sint max_sint max_uint
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

foreach(0, +0.0, -0.0) {
	nint_is nint($_), 0;
	nint_is sint($_), 0;
	nint_is uint($_), 0;
	ok nint_is_sint($_);
	ok nint_is_uint($_);
}

foreach(1, 0x123, max_sint&~1, max_sint) {
	nint_is nint($_), $_;
	nint_is sint($_), $_;
	nint_is uint($_), $_;
	ok nint_is_sint($_);
	ok nint_is_uint($_);
}

foreach(-1, -0x123, do { use integer; min_sint|1 }, min_sint) {
	nint_is nint($_), $_;
	nint_is sint($_), $_;
	eval { uint($_) }; like $@, qr/\Anot an unsigned native integer/;
	ok nint_is_sint($_);
	ok !nint_is_uint($_);
}

foreach(min_sint|0, min_sint|1, min_sint|0x123, max_uint&~1, max_uint) {
	nint_is nint($_), $_;
	eval { sint($_) }; like $@, qr/\Anot a signed native integer/;
	nint_is uint($_), $_;
	ok !nint_is_sint($_);
	ok nint_is_uint($_);
}

foreach(0.5, max_uint*3/2, min_sint*3/2) {
	eval { nint($_) }; like $@, qr/\Anot a native integer/;
	eval { sint($_) }; like $@, qr/\Anot a signed native integer/;
	eval { uint($_) }; like $@, qr/\Anot an unsigned native integer/;
}

1;
