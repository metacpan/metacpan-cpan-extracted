#!/usr/bin/perl

use 5.006;
use Test::More tests => 18;
use strict; use warnings;
use Date::Saka::Simple;

my $date = Date::Saka::Simple->new({year => 1937, month => 1, day => 1});
is($date, '01, Chaitra 1937');
is($date->to_julian, 2457103.5);
is($date->day_of_week, 0);
is($date->days_in_month_year(1, 1938), 30);
is($date->days_in_month_year(2, 1938), 31);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2015-03-22');

is($date->add_days(10)->as_string, '11, Chaitra 1937');
is($date->minus_days(5)->as_string, '06, Chaitra 1937');

is($date->add_months(2)->as_string, '06, Jyaistha 1937');
is($date->minus_months(1)->as_string, '06, Vaisakha 1937');

is($date->add_years(2)->as_string, '06, Vaisakha 1939');
is($date->minus_years(1)->as_string, '06, Vaisakha 1938');

my $gdate = $date->from_gregorian(2015, 3, 22);
is($gdate->year, 1937);
is($gdate->month, 1);
is($gdate->day, 1);

my $jdate = $date->from_julian(2457103.5);
is($jdate->year, 1937);
is($jdate->month, 1);
is($jdate->day, 1);

done_testing();
