use warnings;
use strict;

use Test::More tests => 1 + 3*12 + 5 + 6*21 + 11;

BEGIN {
	use_ok "Date::ISO8601",
		qw(year_weeks cjdn_to_ywd ywd_to_cjdn present_ywd);
}

my $have_bigint = eval("use Math::BigInt 1.16; 1");
my $have_bigrat = eval("use Math::BigRat 0.04; 1");

sub match_val($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub match_vec($$) {
	my($a, $b) = @_;
	unless(@$a == @$b) {
		ok 0;
		return;
	}
	for(my $i = 0; $i != @$a; $i++) {
		my $aval = $a->[$i];
		my $bval = $b->[$i];
		unless(ref($aval) eq ref($bval) && $aval == $bval) {
			ok 0;
			return;
		}
	}
	ok 1;
}

my @prep = (
	sub { $_[0] },
	sub { $have_bigint ? Math::BigInt->new($_[0]) : undef },
	sub { $have_bigrat ? Math::BigRat->new($_[0]) : undef },
);

sub check_weeks($$) {
	my($y, $yw) = @_;
	foreach my $prep (@prep) { SKIP: {
		my $py = $prep->($y);
		skip "numeric type unavailable", 1 unless defined $py;
		match_val year_weeks($py), $yw;
	} }
}

check_weeks(-1994, 52);
check_weeks(-1993, 52);
check_weeks(-1991, 53);
check_weeks(-1985, 53);
check_weeks(-1980, 53);
check_weeks(-1975, 52);
check_weeks(2006, 52);
check_weeks(2007, 52);
check_weeks(2009, 53);
check_weeks(2015, 53);
check_weeks(2020, 53);
check_weeks(2025, 52);

eval { ywd_to_cjdn(2006, 0, 1); };
like $@, qr/\Aweek number /;
eval { ywd_to_cjdn(2006, 53, 1); };
like $@, qr/\Aweek number /;
eval { ywd_to_cjdn(2009, 54, 1); };
like $@, qr/\Aweek number /;
eval { ywd_to_cjdn(2000, 1, 0); };
like $@, qr/\Aday number /;
eval { ywd_to_cjdn(2000, 1, 8); };
like $@, qr/\Aday number /;

sub check_conv($$$$) {
	my($cjdn, $y, $w, $d) = @_;
	foreach my $prep (@prep) { SKIP: {
		skip "numeric type unavailable", 2 unless defined $prep->(0);
		match_vec [ cjdn_to_ywd($prep->($cjdn)) ],
			[ $prep->($y), $w, $d ];
		match_vec [ $prep->($cjdn) ],
			[ ywd_to_cjdn($prep->($y), $w, $d) ];
	} }
}

check_conv(0, -4713, 48, 1);
check_conv(1721060, -1, 52, 6);
check_conv(2406029, 1875, 20, 4);
check_conv(2441317, 1971, 52, 5);
check_conv(2441318, 1971, 52, 6);
check_conv(2441319, 1971, 52, 7);
check_conv(2441320, 1972, 1, 1);
check_conv(2441683, 1972, 52, 7);
check_conv(2441684, 1973, 1, 1);
check_conv(2442047, 1973, 52, 7);
check_conv(2442048, 1974, 1, 1);
check_conv(2442049, 1974, 1, 2);
check_conv(2443139, 1976, 52, 7);
check_conv(2443140, 1976, 53, 1);
check_conv(2443141, 1976, 53, 2);
check_conv(2443142, 1976, 53, 3);
check_conv(2443143, 1976, 53, 4);
check_conv(2443144, 1976, 53, 5);
check_conv(2443145, 1976, 53, 6);
check_conv(2443146, 1976, 53, 7);
check_conv(2443147, 1977, 1, 1);

is present_ywd(2406029), "1875-W20-4";
is present_ywd(1875, 20, 4), "1875-W20-4";
is present_ywd(2441320), "1972-W01-1";
is present_ywd(1972, 1, 1), "1972-W01-1";

is present_ywd(1233, 0, 0), "1233-W00-0";
is present_ywd(1233, 53, 1), "1233-W53-1";
is present_ywd(1233, 99, 9), "1233-W99-9";
eval { present_ywd(1233, -1, 1) }; isnt $@, "";
eval { present_ywd(1233, 100, 1) }; isnt $@, "";
eval { present_ywd(1233, 1, -1) }; isnt $@, "";
eval { present_ywd(1233, 1, 10) }; isnt $@, "";

1;
