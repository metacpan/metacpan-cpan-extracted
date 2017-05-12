#!perl -T

use Test::More tests => 3;

use Date::Holidays::CN qw/is_cn_lunar_holiday/;

is( is_cn_lunar_holiday( 2004, 2, 5 ), '元宵节', 'Chinese festival day' );
is( is_cn_lunar_holiday( 2005, 9, 18 ), '中秋节', 'Moon day' );
is( is_cn_lunar_holiday( 2005, 10, 11 ), '重阳节', '99 day' );