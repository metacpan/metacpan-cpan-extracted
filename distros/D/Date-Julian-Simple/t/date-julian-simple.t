#!/usr/bin/perl

use 5.006;
use Test::More tests => 10;
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

done_testing();
