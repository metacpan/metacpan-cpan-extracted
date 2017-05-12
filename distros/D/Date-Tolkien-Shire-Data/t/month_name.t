package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __month_name
    __month_name_to_number
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 27;

is( __month_name( 0 ), '', q<A holiday> );

cmp_ok( __month_name_to_number( '' ), '==', 0,
    q<Month number of the empty string> );

is( __month_name( 1 ), 'Afteryule', q<Month 1> );

cmp_ok( __month_name_to_number( 'Afteryule' ), '==', 1,
    q<Month number of 'Afteryule'> );

is( __month_name( 2 ), 'Solmath', q<Month 2> );

cmp_ok( __month_name_to_number( 'solmath' ), '==', 2,
    q<Month number of 'solmath'> );

is( __month_name( 3 ), 'Rethe', q<Month 3> );

cmp_ok( __month_name_to_number( 'ret' ), '==', 3,
    q<Month number of 'ret'> );

is( __month_name( 4 ), 'Astron', q<Month 4> );

cmp_ok( __month_name_to_number( 'As' ), '==', 4,
    q<Month number of 'As'> );

is( __month_name( 5 ), 'Thrimidge', q<Month 5> );

cmp_ok( __month_name_to_number( ' thr ' ), '==', 5,
    q<Month number of ' thr '> );

is( __month_name( 6 ), 'Forelithe', q<Month 6> );

cmp_ok( __month_name_to_number( 'fl' ), '==', 6,
    q<Month number of 'fl'> );

is( __month_name( 7 ), 'Afterlithe', q<Month 7> );

cmp_ok( __month_name_to_number( 'AL' ), '==', 7,
    q<Month number of 'AL'> );

is( __month_name( 8 ), 'Wedmath', q<Month 8> );

cmp_ok( __month_name_to_number( 'wed' ), '==', 8,
    q<Month number of 'wed'> );

is( __month_name( 9 ), 'Halimath', q<Month 9> );

cmp_ok( __month_name_to_number( 'Hali' ), '==', 9,
    q<Month number of 'Hali'> );

is( __month_name( 10 ), 'Winterfilth', q<Month 10> );

cmp_ok( __month_name_to_number( 'Wint' ), '==', 10,
    q<Month number of 'Wint'> );

is( __month_name( 11 ), 'Blotmath', q<Month 11> );

cmp_ok( __month_name_to_number( 'bl' ), '==', 11,
    q<Month number of 'bl'> );

is( __month_name( 12 ), 'Foreyule', q<Month 12> );

cmp_ok( __month_name_to_number( 'fore yule' ), '==', 12,
    q<Month number of 'fore yule'> );

cmp_ok( __month_name_to_number( 'fubar' ), '==', 0,
    q<Month number of 'fubar'> );

1;

# ex: set textwidth=72 :
