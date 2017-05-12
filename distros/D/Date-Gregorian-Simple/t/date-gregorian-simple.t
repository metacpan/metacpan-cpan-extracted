#!/usr/bin/perl

use 5.006;
use Test::More tests => 15;
use strict; use warnings;
use Date::Gregorian::Simple;

my $date = Date::Gregorian::Simple->new({year => 2016, month => 4, day => 7});
is($date->as_string, '7, April 2016');
is($date->to_julian, 2457485.5);
is($date->day_of_week, 4);

ok($date->validate_year(1394));
eval { $date->validate_year(-1394); };
like($@, qr/ERROR: Invalid year \[\-1394\]./);

eval { $date->validate_month('DecemberX'); };
like($@, qr/ERROR: Invalid month name/);

eval { $date->validate_month_name('MAY'); };
like($@, qr/^\s*$/);

eval { $date->validate_month_name('May'); };
like($@, qr/^\s*$/);

ok($date->validate_month(11));
eval { $date->validate_month(13); };
like($@, qr/ERROR: Invalid month \[13\]./);

ok($date->validate_day(30));
eval { $date->validate_day(32); };
like($@, qr/ERROR: Invalid day \[32\]./);

my $j_date = $date->from_julian(2457485.5);
is($j_date->year, 2016);
is($j_date->month, 4);
is($j_date->day, 7);

done_testing();
