package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __trad_weekday_narrow };
use Test::More 0.47;	# The best we can do with Perl 5.7.2.

plan tests => 8;

is( __trad_weekday_narrow( 0 ), '', q<No weekday> );

is( __trad_weekday_narrow( 1 ), 'St', q<Weekday 1> );

is( __trad_weekday_narrow( 2 ), 'Su', q<Weekday 2> );

is( __trad_weekday_narrow( 3 ), 'Mo', q<Weekday 3> );

is( __trad_weekday_narrow( 4 ), 'Tr', q<Weekday 4> );

is( __trad_weekday_narrow( 5 ), 'He', q<Weekday 5> );

is( __trad_weekday_narrow( 6 ), 'Me', q<Weekday 6> );

is( __trad_weekday_narrow( 7 ), 'Hi', q<Weekday 7> );

1;

# ex: set textwidth=72 :
