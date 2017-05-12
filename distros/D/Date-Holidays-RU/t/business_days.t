#!perl -T

use utf8;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Date::Holidays::RU', qw( is_business_day ) );
}

ok is_business_day( 2014, 11, 25 ), 'business day';
ok !is_business_day( 2014, 11, 29 ), 'saturday';
ok !is_business_day( 2014, 11, 30 ), 'sunday';
ok !is_business_day( 2014, 11, 04 ), 'holiday on business day';
ok is_business_day( 2012, 03, 11 ), 'business day on weekend';