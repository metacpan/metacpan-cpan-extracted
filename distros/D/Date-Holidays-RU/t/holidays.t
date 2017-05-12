#!perl -T

use utf8;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Date::Holidays::RU', qw( holidays ) );
}

my $ref = holidays( 2015 );

ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0309' }, 'women day afterparty';
is $ref->{ '0310' }, undef, 'bad luck';
