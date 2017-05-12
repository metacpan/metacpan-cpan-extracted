package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __trad_weekday_name };
use Test::More 0.47;	# The best we can do with Perl 5.7.2.

plan tests => 8;

is( __trad_weekday_name( 0 ), '', q<No weekday> );

is( __trad_weekday_name( 1 ), 'Sterrendei', q<Weekday 1> );

is( __trad_weekday_name( 2 ), 'Sunnendei', q<Weekday 2> );

is( __trad_weekday_name( 3 ), 'Monendei', q<Weekday 3> );

is( __trad_weekday_name( 4 ), 'Trewesdei', q<Weekday 4> );

is( __trad_weekday_name( 5 ), 'Hevenesdei', q<Weekday 5> );

is( __trad_weekday_name( 6 ), 'Meresdei', q<Weekday 6> );

is( __trad_weekday_name( 7 ), 'Highdei', q<Weekday 7> );

1;

# ex: set textwidth=72 :
