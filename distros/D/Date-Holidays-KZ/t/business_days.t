#!perl -T

use utf8;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( is_business_day ) );
}

ok is_business_day( 2017, 02, 02 ), 'business day';
ok !is_business_day( 2017, 03, 04 ), 'saturday';
ok !is_business_day( 2017, 04, 02 ), 'sunday';
ok !is_business_day( 2017, 07, 07 ), 'holiday on business day';
ok is_business_day( 2017, 03, 18 ), 'business day on weekend';

done_testing();
