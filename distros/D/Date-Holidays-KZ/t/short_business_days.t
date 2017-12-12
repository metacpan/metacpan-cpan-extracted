#!perl -T

use utf8;
use Test::More;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( is_short_business_day ) );
}

ok !is_short_business_day( 2018, 5, 5 ), 'holiday';
ok !is_short_business_day( 2015, 3, 7 ), 'business day';

done_testing();
