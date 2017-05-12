use warnings;
use strict;

use Test::More tests => 1 + 3*14*14 + 3*11*11 + 3*9*9 + 108 + 1749;

BEGIN { use_ok "Data::Integer", qw(
	nint_sgn sint_sgn uint_sgn
	nint_abs sint_abs uint_abs
	nint_cmp sint_cmp uint_cmp
	nint_min sint_min uint_min
	nint_max sint_max uint_max
	nint_neg sint_neg uint_neg
	nint_add sint_add uint_add
	nint_sub sint_sub uint_sub
	min_sint max_sint max_uint
	nint_is_sint nint_is_uint
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

my @values = (
	min_sint,
	do { use integer; min_sint|1 },
	do { use integer; min_sint>>1 },
	-0x123,
	-1,
	0,
	1,
	0x123,
	min_sint>>1,
	max_sint&~1,
	max_sint,
	min_sint|0,
	max_uint&~1,
	max_uint,
);

for(my $ia = @values; $ia--; ) {
	for(my $ib = @values; $ib--; ) {
		my($a, $b) = @values[$ia, $ib];
		is nint_cmp($a, $b), $ia <=> $ib;
		nint_is nint_min($a, $b), ($ia < $ib ? $a : $b);
		nint_is nint_max($a, $b), ($ia < $ib ? $b : $a);
		if(nint_is_sint($a) && nint_is_sint($b)) {
			is sint_cmp($a, $b), $ia <=> $ib;
			nint_is sint_min($a, $b), ($ia < $ib ? $a : $b);
			nint_is sint_max($a, $b), ($ia < $ib ? $b : $a);
		}
		if(nint_is_uint($a) && nint_is_uint($b)) {
			is uint_cmp($a, $b), $ia <=> $ib;
			nint_is uint_min($a, $b), ($ia < $ib ? $a : $b);
			nint_is uint_max($a, $b), ($ia < $ib ? $b : $a);
		}
	}
}

foreach([ 0, 0, 0 ],
	[ 1, 1, -1 ],
	[ -1, -1, 1 ],
	[ 0x123, 1, -0x123 ],
	[ -0x123, -1, 0x123 ],
	[ max_sint, 1, do { use integer; min_sint|1 } ],
	[ do { use integer; min_sint|1 }, -1, max_sint ],
	[ min_sint|0, 1, min_sint ],
	[ min_sint, -1, min_sint|0 ],
	[ min_sint|1, 1, undef ],
	[ min_sint|0x123, 1, undef ],
	[ max_uint, 1, undef ],
) {
	my($a, $sgn, $neg) = @$_;
	my $abs = (my $ta = $a) >= 0 ? $a : $neg;
	{
		is nint_sgn($a), $sgn;
		nint_is nint_abs($a), $abs;
		my $r = eval { nint_neg($a) };
		if(defined $neg) {
			is $@, "";
			nint_is $r, $neg;
		} else {
			like $@, qr/\Ainteger overflow/;
		}
	}
	if(nint_is_sint($a)) {
		is sint_sgn($a), $sgn;
		my $ra = eval { sint_abs($a) };
		if(nint_is_sint($abs)) {
			is $@, "";
			nint_is $ra, $abs;
		} else {
			like $@, qr/\Ainteger overflow/;
		}
		my $r = eval { sint_neg($a) };
		if(defined($neg) && nint_is_sint($neg)) {
			is $@, "";
			nint_is $r, $neg;
		} else {
			like $@, qr/\Ainteger overflow/;
		}
	}
	if(nint_is_uint($a)) {
		is uint_sgn($a), $sgn;
		nint_is uint_abs($a), $abs;
		my $r = eval { uint_neg($a) };
		if(defined($neg) && nint_is_uint($neg)) {
			is $@, "";
			nint_is $r, $neg;
		} else {
			like $@, qr/\Ainteger overflow/;
		}
	}
}

foreach([ undef, max_uint, min_sint ],
	[ undef, max_uint&~1, min_sint ],
	[ undef, max_uint, do { use integer; min_sint|1 } ],
	[ undef, min_sint|0, min_sint ],
	[ undef, min_sint|0, do { use integer; min_sint|2 } ],
	[ undef, max_uint, -1 ],
	[ undef, max_sint, min_sint ],
	[ undef, min_sint|0, do { use integer; min_sint|1 } ],
	[ undef, max_uint, 0 ],
	[ undef, max_sint&~1, min_sint ],
	[ undef, max_sint, do { use integer; min_sint|1 } ],
	[ undef, min_sint|0, do { use integer; min_sint|2 } ],
	[ undef, max_uint, 1 ],
	[ undef, 2, min_sint ],
	[ undef, 3, do { use integer; min_sint|1 } ],
	[ undef, max_sint, -3 ],
	[ undef, min_sint|1, -1 ],
	[ undef, min_sint|2, 0 ],
	[ undef, min_sint|3, 1 ],
	[ undef, max_uint&~1, max_sint&~3 ],
	[ undef, max_uint, max_sint&~2 ],
	[ undef, 1, min_sint ],
	[ undef, 2, do { use integer; min_sint|1 } ],
	[ undef, max_sint, -2 ],
	[ undef, min_sint|0, -1 ],
	[ undef, min_sint|1, 0 ],
	[ undef, min_sint|2, 1 ],
	[ undef, max_uint&~1, max_sint&~2 ],
	[ undef, max_uint, max_sint&~1 ],
	[ min_sint, min_sint, undef ],
	[ min_sint, do { use integer; min_sint|1 }, undef ],
	[ min_sint, -1, undef ],
	[ min_sint, 0, min_sint ],
	[ min_sint, 1, do { use integer; min_sint|1 } ],
	[ min_sint, max_sint, -1 ],
	[ min_sint, min_sint|0, 0 ],
	[ min_sint, min_sint|1, 1 ],
	[ min_sint, max_uint&~1, max_sint&~1 ],
	[ min_sint, max_uint, max_sint ],
	[ min_sint, undef, min_sint|0 ],
	[ min_sint, undef, max_uint&~1 ],
	[ min_sint, undef, max_uint ],
	[ do { use integer; min_sint|1 }, do { use integer; min_sint|1 }, undef ],
	[ do { use integer; min_sint|1 }, do { use integer; min_sint|2 }, undef ],
	[ do { use integer; min_sint|1 }, -2, undef ],
	[ do { use integer; min_sint|1 }, -1, min_sint ],
	[ do { use integer; min_sint|1 }, 0, do { use integer; min_sint|1 } ],
	[ do { use integer; min_sint|1 }, 1, do { use integer; min_sint|2 } ],
	[ do { use integer; min_sint|1 }, max_sint&~1, -1 ],
	[ do { use integer; min_sint|1 }, max_sint, 0 ],
	[ do { use integer; min_sint|1 }, min_sint|0, 1 ],
	[ do { use integer; min_sint|1 }, max_uint&~2, max_sint&~1 ],
	[ do { use integer; min_sint|1 }, max_uint&~1, max_sint ],
	[ do { use integer; min_sint|1 }, max_uint, min_sint|0 ],
	[ do { use integer; min_sint|1 }, undef, max_uint&~1 ],
	[ do { use integer; min_sint|1 }, undef, max_uint ],
	[ do { use integer; min_sint|~(min_sint>>1) }, do { use integer; min_sint|~(min_sint>>1) }, undef ],
	[ do { use integer; min_sint|~(min_sint>>1) }, do { use integer; min_sint>>1 }, undef ],
	[ do { use integer; min_sint|~(min_sint>>1) }, do { use integer; (min_sint>>1)|1 }, min_sint ],
	[ do { use integer; min_sint|~(min_sint>>1) }, do { use integer; (min_sint>>1)|2 }, do { use integer; min_sint|1 } ],
	[ do { use integer; min_sint|~(min_sint>>1) }, min_sint>>1,  -1 ],
	[ do { use integer; min_sint|~(min_sint>>1) }, (min_sint>>1)|1, 0 ],
	[ do { use integer; min_sint|~(min_sint>>1) }, (min_sint>>1)|2, 1 ],
	[ do { use integer; min_sint|~(min_sint>>1) }, max_sint&~1, (max_sint>>1)&~2 ],
	[ do { use integer; min_sint|~(min_sint>>1) }, max_sint, (max_sint>>1)&~1 ],
	[ do { use integer; min_sint|~(min_sint>>1) }, min_sint|0, max_sint>>1 ],
	[ do { use integer; min_sint>>1 }, do { use integer; min_sint>>1 }, min_sint ],
	[ do { use integer; min_sint>>1 }, do { use integer; (min_sint>>1)|1 }, do { use integer; min_sint|1 } ],
	[ do { use integer; min_sint>>1 }, max_sint>>1, -1 ],
	[ do { use integer; min_sint>>1 }, min_sint>>1,  0 ],
	[ do { use integer; min_sint>>1 }, (min_sint>>1)|1, 1 ],
	[ do { use integer; min_sint>>1 }, max_sint&~1, (max_sint>>1)&~1 ],
	[ do { use integer; min_sint>>1 }, max_sint, max_sint>>1 ],
	[ do { use integer; min_sint>>1 }, min_sint|0, min_sint>>1,  ],
	[ do { use integer; (min_sint>>1)|1 }, do { use integer; (min_sint>>1)|1 }, do { use integer; min_sint|2 } ],
	[ do { use integer; (min_sint>>1)|1 }, (max_sint>>1)&~1, -1 ],
	[ do { use integer; (min_sint>>1)|1 }, max_sint>>1, 0 ],
	[ do { use integer; (min_sint>>1)|1 }, min_sint>>1,  1 ],
	[ do { use integer; (min_sint>>1)|1 }, max_sint&~1, max_sint>>1 ],
	[ do { use integer; (min_sint>>1)|1 }, max_sint, min_sint>>1,  ],
	[ do { use integer; (min_sint>>1)|1 }, min_sint|0, (min_sint>>1)|1 ],
	[ -0x123, -0x123, -0x246 ],
	[ -0x123, -1, -0x124 ],
	[ -0x123, 0, -0x123 ],
	[ -0x123, 1, -0x122 ],
	[ -0x123, 0x122, -1 ],
	[ -0x123, 0x123, 0 ],
	[ -0x123, 0x124, 1 ],
	[ -0x123, max_sint&~1, max_sint&~0x124 ],
	[ -0x123, max_sint, max_sint&~0x123 ],
	[ -0x123, min_sint|0, max_sint&~0x122 ],
	[ -0x123, min_sint|0x121, max_sint&~1 ],
	[ -0x123, min_sint|0x122, max_sint ],
	[ -0x123, min_sint|0x123, min_sint|0 ],
	[ -0x123, max_uint&~1, max_uint&~0x124 ],
	[ -0x123, max_uint, max_uint&~0x123 ],
	[ -0x123, undef, max_uint&~0x122 ],
	[ -0x123, undef, max_uint&~1 ],
	[ -0x123, undef, max_uint ],
	[ -1, -1, -2 ],
	[ -1, 0, -1 ],
	[ -1, 1, 0 ],
	[ -1, 0x123, 0x122 ],
	[ -1, max_sint&~1, max_sint&~2 ],
	[ -1, max_sint, max_sint&~1 ],
	[ -1, min_sint|0, max_sint ],
	[ -1, min_sint|1, min_sint|0 ],
	[ -1, max_uint&~1, max_uint&~2 ],
	[ -1, max_uint, max_uint&~1 ],
	[ -1, undef, max_uint ],
	[ 0, 0, 0 ],
	[ 0, 1, 1 ],
	[ 0, 0x123, 0x123 ],
	[ 0, max_sint&~1, max_sint&~1 ],
	[ 0, max_sint, max_sint ],
	[ 0, min_sint|0, min_sint|0 ],
	[ 0, max_uint&~1, max_uint&~1 ],
	[ 0, max_uint, max_uint ],
	[ 1, 1, 2 ],
	[ 1, 0x123, 0x124 ],
	[ 1, max_sint&~1, max_sint ],
	[ 1, max_sint, min_sint|0 ],
	[ 1, min_sint|0, min_sint|1 ],
	[ 1, max_uint&~1, max_uint ],
	[ 1, max_uint, undef ],
	[ 0x123, 0x123, 0x246 ],
	[ 0x123, max_sint&~0x124, max_sint&~1 ],
	[ 0x123, max_sint&~0x123, max_sint ],
	[ 0x123, max_sint&~0x122, min_sint|0 ],
	[ 0x123, max_sint&~1, min_sint|0x121 ],
	[ 0x123, max_sint, min_sint|0x122 ],
	[ 0x123, min_sint|0, min_sint|0x123 ],
	[ 0x123, max_uint&~0x124, max_uint&~1 ],
	[ 0x123, max_uint&~0x123, max_uint ],
	[ 0x123, max_uint&~0x122, undef ],
	[ 0x123, max_uint&~1, undef ],
	[ 0x123, max_uint, undef ],
	[ max_sint>>1, max_sint>>1, max_sint&~1 ],
	[ max_sint>>1, min_sint>>1,  max_sint ],
	[ max_sint>>1, (min_sint>>1)|1, min_sint|0 ],
	[ max_sint>>1, max_uint&~1, undef ],
	[ max_sint>>1, max_uint, undef ],
	[ min_sint>>1, min_sint>>1,  min_sint|0 ],
	[ min_sint>>1, (min_sint>>1)|1, min_sint|1 ],
	[ min_sint>>1, max_uint&~1, undef ],
	[ min_sint>>1, max_uint, undef ],
	[ max_sint&~1, max_sint&~1, max_uint&~3 ],
	[ max_sint&~1, max_sint, max_uint&~2 ],
	[ max_sint&~1, min_sint|0, max_uint&~1 ],
	[ max_sint&~1, min_sint|1, max_uint ],
	[ max_sint&~1, min_sint|2, undef ],
	[ max_sint&~1, max_uint&~1, undef ],
	[ max_sint&~1, max_uint, undef ],
	[ max_sint, max_sint, max_uint&~1 ],
	[ max_sint, min_sint|0, max_uint ],
	[ max_sint, min_sint|1, undef ],
	[ max_sint, max_uint&~1, undef ],
	[ max_sint, max_uint, undef ],
	[ min_sint|0, min_sint|0, undef ],
	[ min_sint|0, max_uint&~1, undef ],
	[ min_sint|0, max_uint, undef ],
	[ max_uint&~1, max_uint&~1, undef ],
	[ max_uint&~1, max_uint, undef ],
	[ max_uint, max_uint, undef ],
) {
	my($a, $b, $c) = @$_;
	if(defined($a) && defined($b)) {
		{
			my $r = eval { nint_add($a, $b) };
			if(defined $c) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
			$r = eval { nint_add($b, $a) };
			if(defined $c) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_sint($a) && nint_is_sint($b)) {
			my $r = eval { sint_add($a, $b) };
			if(defined($c) && nint_is_sint($c)) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
			$r = eval { sint_add($b, $a) };
			if(defined($c) && nint_is_sint($c)) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_uint($a) && nint_is_uint($b)) {
			my $r = eval { uint_add($a, $b) };
			if(defined($c) && nint_is_uint($c)) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
			$r = eval { uint_add($b, $a) };
			if(defined($c) && nint_is_uint($c)) {
				is $@, "";
				nint_is $r, $c;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
	}
	if(defined($a) && defined($c)) {
		{
			my $r = eval { nint_sub($c, $a) };
			if(defined $b) {
				is $@, "";
				nint_is $r, $b;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_sint($a) && nint_is_sint($c)) {
			my $r = eval { sint_sub($c, $a) };
			if(defined($b) && nint_is_sint($b)) {
				is $@, "";
				nint_is $r, $b;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_uint($a) && nint_is_uint($c)) {
			my $r = eval { uint_sub($c, $a) };
			if(defined($b) && nint_is_uint($b)) {
				is $@, "";
				nint_is $r, $b;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
	}
	if(defined($b) && defined($c)) {
		{
			my $r = eval { nint_sub($c, $b) };
			if(defined $a) {
				is $@, "";
				nint_is $r, $a;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_sint($b) && nint_is_sint($c)) {
			my $r = eval { sint_sub($c, $b) };
			if(defined($a) && nint_is_sint($a)) {
				is $@, "";
				nint_is $r, $a;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
		if(nint_is_uint($b) && nint_is_uint($c)) {
			my $r = eval { uint_sub($c, $b) };
			if(defined($a) && nint_is_uint($a)) {
				is $@, "";
				nint_is $r, $a;
			} else {
				like $@, qr/\Ainteger overflow/;
			}
		}
	}
}

1;
