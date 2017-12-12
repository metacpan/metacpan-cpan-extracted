#!perl -T

use utf8;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( is_business_day ) );
}

ok is_business_day( 2018, 01, 03 ), 'business day';
ok !is_business_day( 2018, 02, 03 ), 'saturday';
ok !is_business_day( 2018, 03, 04 ), 'sunday';
ok !is_business_day( 2018, 04, 30 ), 'holiday on business day';
ok is_business_day( 2018, 12, 29 ), 'business day on weekend';

done_testing();
