#!perl

use utf8;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( is_business_day ) );
}

ok is_business_day( 2017, 01, 03 ), 'business day';
ok !is_business_day( 2017, 03, 04 ), 'saturday';
ok !is_business_day( 2017, 04, 02 ), 'sunday';
ok !is_business_day( 2017, 06, 03 ), 'holiday on business day';
ok is_business_day( 2017, 01, 21 ), 'business day on weekend';

done_testing();
