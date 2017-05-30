#!perl -T

use utf8;
use Test::More;
use Test::Exception;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( is_holiday is_by_holiday ) );
}

dies_ok { is_holiday( 1989, 3, 3 ) } 'prehistoric time';
is is_by_holiday( 2017, 1, 1 ), is_holiday( 2017, 1, 1 ), 'alias';

done_testing();
