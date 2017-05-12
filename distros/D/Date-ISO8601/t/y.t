use warnings;
use strict;

use Test::More tests => 1 + 3*14;

BEGIN { use_ok "Date::ISO8601", qw(present_y); }

my $have_bigint = eval("use Math::BigInt; 1");
my $have_bigrat = eval("use Math::BigRat 0.02; 1");

my @prep = (
	sub { $_[0] },
	sub { $have_bigint ? Math::BigInt->new($_[0]) : undef },
	sub { $have_bigrat ? Math::BigRat->new($_[0]) : undef },
);

sub check($$) {
	my($y, $pres) = @_;
	foreach my $prep (@prep) { SKIP: {
		my $py = $prep->($y);
		skip "numeric type unavailable", 1 unless defined $py;
		is present_y($py), $pres;
	} }
}

check(-123456, "-123456");
check(-12345, "-12345");
check(-1234, "-1234");
check(-123, "-0123");
check(-12, "-0012");
check(-1, "-0001");
check(0, "0000");
check(1, "0001");
check(12, "0012");
check(123, "0123");
check(1234, "1234");
check(12345, "+12345");
check(123456, "+123456");
check("+00000123", "0123");

1;
