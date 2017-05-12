#!/usr/bin/perl

use 5.006;
use Test::More tests => 18;
use strict; use warnings;
use Date::Persian::Simple;

my $date = Date::Persian::Simple->new({year => 1394, month => 1, day => 1});
is($date->as_string, '1, Farvardin 1394');
is($date->to_julian, 2457102.5);
is($date->day_of_week, 6);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2015-03-21');

ok($date->validate_year(1394));
eval { $date->validate_year(-1394); };
like($@, qr/ERROR: Invalid year \[\-1394\]./);

ok($date->validate_month(11));
eval { $date->validate_month(13); };
like($@, qr/ERROR: Invalid month \[13\]./);

ok($date->validate_day(30));
eval { $date->validate_day(32); };
like($@, qr/ERROR: Invalid day \[32\]./);

my $j_date = $date->from_julian(2455538.5);
is($j_date->year, 1389);
is($j_date->month, 9);
is($j_date->day, 17);

my $g_date = $date->from_gregorian(2010, 12, 8);
is($g_date->year, 1389);
is($g_date->month, 9);
is($g_date->day, 17);

is($date->days_in_month_year(1, 1394), 31);
ok(!!$date->is_leap_year(1394) == 0);

done_testing();
