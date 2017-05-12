#!perl -T

use utf8;
use Test::More;

BEGIN {
	use_ok( 'Date::Holidays::RU', qw( is_short_business_day ) );
}

ok is_short_business_day( 2015, 04, 30 ), 'short day';
ok !is_short_business_day( 2015, 04, 29 ), 'work day';
ok !is_short_business_day( 2015, 05, 1 ), 'holiday';

done_testing();
