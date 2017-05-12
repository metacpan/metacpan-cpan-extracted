# $Id: calculate_month.t 1630 2006-08-18 20:47:12Z jonasbn $

use strict;
use Test::More tests => 15;

#test 1
use_ok( "Date::Pregnancy", qw(calculate_month));

my $dt = DateTime->new(
	year  => 2004,
	month => 3,
	day   => 19,
);

my $month;

#test 2
ok($month = calculate_month(
	first_day_of_last_period => $dt,
));

#test 3
like($month, qr/\d+/);

my $dt2 = DateTime->new(
	year  => 2004,
	month => 12,
	day   => 23,
);

#test 4
ok($month = calculate_month(
	first_day_of_last_period => $dt,
	date                     => $dt2,
));

#test 5
is($month, 9);

#test 6
is(calculate_month(), undef);

my $months_dt = $dt->clone();
for(my $i = 1; $i < 10; $i++) {
	$months_dt->add(months => 1);
	is(calculate_month(first_day_of_last_period => $dt, date => $months_dt), $i);
}