#!perl

use utf8;
use Test::More tests => 9;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( is_short_business_day short_business_days ) );
}

ok is_short_business_day( 2017, 03, 07 ), 'short day';
ok !is_short_business_day( 2017, 12, 24 ), 'holiday';
ok !is_short_business_day( 2015, 11, 4 ), 'business day';

ok is_short_business_day( 2015, 12, 31 ), 'calculated: missing in the old table';
ok is_short_business_day( 2024, 12, 31 ), 'calculated: before New Year';
ok !is_short_business_day( 2024, 5, 13 ), 'calculated: day before holiday, but postponed day off';
ok !is_short_business_day( 2024, 1, 6 ), 'calculated: weekend before holiday';
is_deeply [ sort keys %{ short_business_days( 2024 ) } ], [ qw( 0307 0430 0508 0702 1106 1224 1231 ) ], 'calculated days of 2024';
