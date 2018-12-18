#!perl -T

use utf8;
use Test::More tests => 7;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( holidays ) );
}

my $ref = holidays( 2017 );

ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0509' }, 'women day afterparty';
is $ref->{ '0310' }, undef, 'bad luck';


my $ref = holidays( 2040 );

ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0101' }, 'new year';
is $ref->{ '0310' }, undef, 'bad luck';
