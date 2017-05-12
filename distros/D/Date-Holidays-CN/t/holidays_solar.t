#!perl -T

use Test::More tests => 3;

use Date::Holidays::CN qw/is_cn_solar_holiday/;

is( is_cn_solar_holiday( 2005, 5, 8 ), '母亲节', 'mother\'s day' );
is( is_cn_solar_holiday( 2005, 6, 19 ), '父亲节', 'father\'s day' );
is( is_cn_solar_holiday( 2005, 10, 1 ), '国庆节', 'national day' );