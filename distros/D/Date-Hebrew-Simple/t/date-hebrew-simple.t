#!/usr/bin/perl

use 5.006;
use Test::More tests => 18;
use strict; use warnings;
use Date::Hebrew::Simple;

my $date = Date::Hebrew::Simple->new({year => 5778, month => 11, day => 1});
is($date->as_string, '1, Shevat 5778');
is($date->to_julian, 2458134.5);
is($date->day_of_week, 1);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2018-01-16');

ok($date->validate_year(5778));
eval { $date->validate_year(-5778); };
like($@, qr/ERROR: Invalid year \[\-5778\]./);

ok($date->validate_month(11));
eval { $date->validate_month(13); };
like($@, qr/ERROR: Invalid month \[13\]./);

ok($date->validate_day(30));
eval { $date->validate_day(32); };
like($@, qr/ERROR: Invalid day \[32\]./);

my $j_date = $date->from_julian(2458134.5);
is($j_date->year, 5778);
is($j_date->month, 11);
is($j_date->day, 1);

my $g_date = $date->from_gregorian(2018, 2, 11);
is($g_date->year, 5778);
is($g_date->month, 11);
is($g_date->day, 27);

is($date->days_in_month_year(11, 5778), 30);
ok(!!$date->is_leap_year(5778) == 0);

done_testing();
