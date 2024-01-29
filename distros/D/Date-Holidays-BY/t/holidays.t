#!perl -T

use utf8;
use Test::More tests => 13;

BEGIN {
	use_ok( 'Date::Holidays::BY', qw( holidays ) );
}

is Date::Holidays::BY::is_by_holiday( 2017, 1, 1 ), Date::Holidays::BY::is_holiday( 2017, 1, 1 ), 'alias';

my $ref = holidays( 2017 );
ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0509' }, 'women day afterparty';
is $ref->{ '0310' }, undef, 'bad luck';

my $ref = holidays( 2019 );
ok $ref->{ '0101' }, 'ny';
is $ref->{ '0102' }, undef, 'not ny before 2020';

my $ref = holidays( 2023 );
ok $ref->{ '0425' }, 'radonitsa';

my $ref = holidays( 5201 );
ok $ref->{ '0101' }, 'ny';
ok $ref->{ '0102' }, 'ny';
ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0522' }, 'radonitsa';
is $ref->{ '0312' }, undef, 'bad luck';

