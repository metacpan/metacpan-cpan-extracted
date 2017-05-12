package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __trad_weekday_abbr };
use Test::More 0.47;	# The best we can do with Perl 5.7.2.

plan tests => 8;

is( __trad_weekday_abbr( 0 ), '', q<No weekday> );

is( __trad_weekday_abbr( 1 ), 'Ste', q<Weekday 1> );

is( __trad_weekday_abbr( 2 ), 'Sun', q<Weekday 2> );

is( __trad_weekday_abbr( 3 ), 'Mon', q<Weekday 3> );

is( __trad_weekday_abbr( 4 ), 'Tre', q<Weekday 4> );

is( __trad_weekday_abbr( 5 ), 'Hev', q<Weekday 5> );

is( __trad_weekday_abbr( 6 ), 'Mer', q<Weekday 6> );

is( __trad_weekday_abbr( 7 ), 'Hig', q<Weekday 7> );

1;

# ex: set textwidth=72 :
