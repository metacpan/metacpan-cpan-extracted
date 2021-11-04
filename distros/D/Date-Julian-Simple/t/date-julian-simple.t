#!/usr/bin/perl

use 5.006;
use Test::More;
use strict; use warnings;
use Date::Julian::Simple;

my $date = Date::Julian::Simple->new({ year => 2018, month => 1, day => 9 });
is($date->as_string, '9, January 2018');
is($date->to_julian, 2458140.5);
is($date->day_of_week, 1);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2018-01-22');

my $gdate = $date->from_gregorian(2018, 1, 22);
is($gdate->year, 2018);
is($gdate->month, 1);
is($gdate->day, 9);

my $jdate = $date->from_julian(2458140.5);
is($jdate->year, 2018);
is($jdate->month, 1);
is($jdate->day, 9);

my $mjd = Date::Julian::Simple->new({ year => 2020, month => 11, day => 12 });
is($mjd->from_modified_julian(59165), "12, November 2020");
is($mjd->to_modified_julian, 59165);

is($date->is_leap_year(1800), 1);
is($date->is_leap_year(2000), 1);
is($date->is_leap_year(2021), 0);

is($date->days_in_year(1800), 366);
is($date->days_in_year(2000), 366);
is($date->days_in_year(2021), 365);

is($date->days_in_month_year(02,1800), 29);
is($date->days_in_month_year(02,2000), 29);
is($date->days_in_month_year(02,2021), 28);
is($date->days_in_month_year(03,2021), 31);

done_testing();
