#!perl -T

use utf8;
use Test::More tests => 7;

BEGIN {
	use_ok( 'Date::Holidays::KZ', qw( holidays ) );
}

my $ref = holidays( 2018 );

ok $ref->{ '0102' }, 'new year';
ok $ref->{ '0508' }, 'holiday on business day';
ok $ref->{ '0501' }, 'holiday';
ok $ref->{ '0308' }, 'women day';
ok $ref->{ '0831' }, 'holiday on business day';
is $ref->{ '0312' }, undef, 'bad luck';
