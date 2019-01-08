#!perl -T

use utf8;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( is_short_business_day ) );
}
