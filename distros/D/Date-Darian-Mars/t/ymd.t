use warnings;
use strict;

use Test::More tests => 1 + 3*37 + 6 + 6*9 + 11;

BEGIN {
	use_ok "Date::Darian::Mars",
		qw(month_days cmsdn_to_ymd ymd_to_cmsdn present_ymd);
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

check_days(-2000, 24, 28);
check_days(-1999, 24, 28);
check_days(-1998, 24, 27);
check_days(-1997, 24, 28);
check_days(-1996, 24, 27);
check_days(-1990, 24, 28);
check_days(-1900, 24, 27);
check_days(2000, 24, 28);
check_days(2001, 24, 28);
check_days(2002, 24, 27);
check_days(2003, 24, 28);
check_days(2004, 24, 27);
check_days(2010, 24, 28);
check_days(2100, 24, 27);
for(my $m = 1; $m != 24; $m++) {
	check_days(2100, $m, $m % 6 == 0 ? 27 : 28);
}

eval { ymd_to_cmsdn(500, 0, 1); };
like $@, qr/\Amonth number /;
eval { ymd_to_cmsdn(500, 25, 1); };
like $@, qr/\Amonth number /;
eval { ymd_to_cmsdn(500, 1, 0); };
like $@, qr/\Aday number /;
eval { ymd_to_cmsdn(500, 6, 28); };
like $@, qr/\Aday number /;
eval { ymd_to_cmsdn(500, 24, 29); };
like $@, qr/\Aday number /;
eval { ymd_to_cmsdn(502, 24, 28); };
like $@, qr/\Aday number /;

sub check_conv($$$$) {
	my($cmsdn, $y, $m, $d) = @_;
	foreach my $prep (@prep) { SKIP: {
		skip "numeric type unavailable", 2 unless defined $prep->(0);
		match_vec [ cmsdn_to_ymd($prep->($cmsdn)) ],
			[ $prep->($y), $m, $d ];
		match_vec [ $prep->($cmsdn) ],
			[ ymd_to_cmsdn($prep->($y), $m, $d) ];
	} }
}

check_conv(0, -608, 23, 20);
check_conv(405871, 0, 1, 1);
check_conv(546236, 209, 23, 18);
check_conv(546943, 210, 24, 28);
check_conv(546944, 211, 1, 1);
check_conv(547612, 211, 24, 28);
check_conv(547613, 212, 1, 1);
check_conv(548280, 212, 24, 27);
check_conv(548281, 213, 1, 1);

is present_ymd(546236), "0209-23-18";
is present_ymd(209, 23, 18), "0209-23-18";
is present_ymd(548281), "0213-01-01";
is present_ymd(213, 1, 1), "0213-01-01";

is present_ymd(1233, 0, 0), "1233-00-00";
is present_ymd(1233, 2, 29), "1233-02-29";
is present_ymd(1233, 99, 99), "1233-99-99";
eval { present_ymd(1233, -1, 1) }; isnt $@, "";
eval { present_ymd(1233, 100, 1) }; isnt $@, "";
eval { present_ymd(1233, 1, -1) }; isnt $@, "";
eval { present_ymd(1233, 1, 100) }; isnt $@, "";

1;
