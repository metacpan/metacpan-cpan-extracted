#!/usr/bin/perl

use 5.006;
use Test::More tests => 29;
use strict; use warnings;
use Date::Bahai::Simple;

my $date = Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1});
is($date->as_string, '1, Baha 172 BE');
is($date->to_julian, 2457102.5);
is($date->get_year, 172);
is($date->year, 1);
is($date->month, 1);
is($date->major, 1);
is($date->cycle, 10);
is($date->day_of_week, 6);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2015-03-21');
is(join(", ", $date->get_major_cycle_year(171)), '1, 10, 1');

is($date->is_same($date->get_date(1, 1, 172)), 1, "dates are same");
is($date->is_same($date->get_date(2, 1, 172)), 0, "dates are not same");

eval { $date->validate_year(-168); };
like($@, qr/ERROR: Invalid year \[\-168\]./);

eval { $date->validate_month(21); };
like($@, qr/ERROR: Invalid month \[21\]./);

eval { $date->validate_month('Bahax'); };
like($@, qr/ERROR: Invalid month name/);

eval { $date->validate_month_name('Jalal'); };
like($@, qr/^\s*$/);

eval { $date->validate_day(20); };
like($@, qr/ERROR: Invalid day \[20\]./);

my @gregorian = Date::Bahai::Simple->new({ major => 1, cycle => 10, year => 1, month => 2, day => 8 })->to_gregorian;
is(sprintf("%04d-%02d-%02d", @gregorian), '2015-04-16');

my $g_date = Date::Bahai::Simple->new->from_gregorian(2015, 4, 16);
is($g_date->major, 1);
is($g_date->cycle, 10);
is($g_date->year, 1);
is($g_date->month, 2);
is($g_date->day, 8);

my $j_date = Date::Bahai::Simple->new->from_julian(2457102.5);
is($j_date->major, 1);
is($j_date->cycle, 10);
is($j_date->year, 1);
is($j_date->month, 1);
is($j_date->day, 1);
is($j_date->to_julian, 2457102.5);

done_testing();
