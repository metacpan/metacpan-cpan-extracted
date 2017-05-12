package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __holiday_name
    __holiday_name_to_number
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 15;

is( __holiday_name( 0 ), '', q<Not a holiday> );

cmp_ok( __holiday_name_to_number( '' ), '==', 0,
    q<Holiday number of empty string> );

is( __holiday_name( 1 ), '2 Yule', q<Holiday 1> );

cmp_ok( __holiday_name_to_number( '2 Yule' ), '==', 1,
    q<Holiday number of '2 Yule'> );

is( __holiday_name( 2 ), '1 Lithe', q<Holiday 2> );

cmp_ok( __holiday_name_to_number( '1lithe' ), '==', 2,
    q<Holiday number of '1lithe'> );

is( __holiday_name( 3 ), q<Midyear's day>, q<Holiday 3> );

cmp_ok( __holiday_name_to_number( 'mi' ), '==', 3,
    q<Holiday number of 'm'> );

is( __holiday_name( 4 ), 'Overlithe', q<Holiday 4> );

cmp_ok( __holiday_name_to_number( 'oli' ), '==', 4,
    q<Holiday number of 'oli'> );

is( __holiday_name( 5 ), '2 Lithe', q<Holiday 5> );

cmp_ok( __holiday_name_to_number( '2l' ), '==', 5,
    q<Holiday number of '2l'> );

is( __holiday_name( 6 ), '1 Yule', q<Holiday 6> );

cmp_ok( __holiday_name_to_number( '1  yul' ), '==', 6,
    q<Holiday number of '1  yul'> );

cmp_ok( __holiday_name_to_number( 'fubar' ), '==', 0,
    q<Holiday number of 'fubar'> );

1;

# ex: set textwidth=72 :
