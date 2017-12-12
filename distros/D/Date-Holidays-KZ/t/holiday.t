#!perl -T

use utf8;
use Test::More;
use Test::Exception;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( is_holiday is_kz_holiday ) );
}

dies_ok { is_holiday( 1989, 3, 3 ) } 'prehistoric time';
is is_kz_holiday( 2018, 1, 1 ), is_holiday( 2018, 1, 1 ), 'alias';

done_testing();
