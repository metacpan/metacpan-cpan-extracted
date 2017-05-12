use warnings;
use strict;

use Test::More tests => 1 + 3*19 + 6 + 6*11 + 11;

BEGIN {
	use_ok "Date::ISO8601",
		qw(month_days cjdn_to_ymd ymd_to_cjdn present_ymd);
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

sub check_days($$$) {
	my($y, $m, $md) = @_;
	foreach my $prep (@prep) { SKIP: {
		my $py = $prep->($y);
		skip "numeric type unavailable", 1 unless defined $py;
		match_val month_days($py, $m), $md;
	} }
}

check_days(-2000, 2, 29);
check_days(-1999, 2, 28);
check_days(-1996, 2, 29);
check_days(-1900, 2, 28);
check_days(2000, 2, 29);
check_days(2001, 2, 28);
check_days(2004, 2, 29);
check_days(2100, 2, 28);
check_days(2100, 1, 31);
check_days(2100, 3, 31);
check_days(2100, 4, 30);
check_days(2100, 5, 31);
check_days(2100, 6, 30);
check_days(2100, 7, 31);
check_days(2100, 8, 31);
check_days(2100, 9, 30);
check_days(2100, 10, 31);
check_days(2100, 11, 30);
check_days(2100, 12, 31);

eval { ymd_to_cjdn(2000, 0, 1); };
like $@, qr/\Amonth number /;
eval { ymd_to_cjdn(2000, 13, 1); };
like $@, qr/\Amonth number /;
eval { ymd_to_cjdn(2000, 1, 0); };
like $@, qr/\Aday number /;
eval { ymd_to_cjdn(2000, 1, 32); };
like $@, qr/\Aday number /;
eval { ymd_to_cjdn(2000, 2, 30); };
like $@, qr/\Aday number /;
eval { ymd_to_cjdn(2001, 2, 29); };
like $@, qr/\Aday number /;

sub check_conv($$$$) {
	my($cjdn, $y, $m, $d) = @_;
	foreach my $prep (@prep) { SKIP: {
		skip "numeric type unavailable", 2 unless defined $prep->(0);
		match_vec [ cjdn_to_ymd($prep->($cjdn)) ],
			[ $prep->($y), $m, $d ];
		match_vec [ $prep->($cjdn) ],
			[ ymd_to_cjdn($prep->($y), $m, $d) ];
	} }
}

check_conv(0, -4713, 11, 24);
check_conv(1721060, 0, 1, 1);
check_conv(2406029, 1875, 5, 20);
check_conv(2441317, 1971, 12, 31);
check_conv(2441318, 1972, 1, 1);
check_conv(2443144, 1976, 12, 31);
check_conv(2443145, 1977, 1, 1);
check_conv(2451544, 1999, 12, 31);
check_conv(2451545, 2000, 1, 1);
check_conv(2451604, 2000, 2, 29);
check_conv(2451605, 2000, 3, 1);

is present_ymd(2406029), "1875-05-20";
is present_ymd(1875, 5, 20), "1875-05-20";
is present_ymd(2451545), "2000-01-01";
is present_ymd(2000, 1, 1), "2000-01-01";

is present_ymd(1233, 0, 0), "1233-00-00";
is present_ymd(1233, 2, 29), "1233-02-29";
is present_ymd(1233, 99, 99), "1233-99-99";
eval { present_ymd(1233, -1, 1) }; isnt $@, "";
eval { present_ymd(1233, 100, 1) }; isnt $@, "";
eval { present_ymd(1233, 1, -1) }; isnt $@, "";
eval { present_ymd(1233, 1, 100) }; isnt $@, "";

1;
