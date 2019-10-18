#!perl

use utf8;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( is_short_business_day ) );
}

ok is_short_business_day( 2017, 03, 07 ), 'short day';
ok !is_short_business_day( 2017, 12, 24 ), 'holiday';
ok !is_short_business_day( 2015, 11, 4 ), 'business day';
