# $Id$

use strict;
use Test::More tests => 58;
use DateTime;

#test 1
use_ok( "Date::Pregnancy", qw(calculate_week));

my $dt = DateTime->new(
	year  => 2004,
	month => 3,
	day   => 19,
);

#test 2
is($dt->week_number, 12);

my $week;

#test 3
ok($week = calculate_week(
	first_day_of_last_period => $dt,
));

#test 4
like($week, qr/\d+/);

my $dt2 = DateTime->new(
	year  => 2004,
	month => 10,
	day   => 9,
);

#test 5
ok($week = calculate_week(
	first_day_of_last_period => $dt,
	date                     => $dt2,
));

#test 6
is($week, 29);

$dt2 = DateTime->new(
	year  => 2004,
	month => 12,
	day   => 24,
);

#test 7
ok($week = calculate_week(
	first_day_of_last_period => $dt,
	date                     => $dt2,
));

#test 8
is($week, 40);

#test 9
is(calculate_week(), undef);

#Testing week numbers

my $weeks_dt = $dt->clone();
for(my $i = 1; $i < 50; $i++) {
	$weeks_dt->add(days => 7);
	is(calculate_week(first_day_of_last_period => $dt, date => $weeks_dt), $i);
}