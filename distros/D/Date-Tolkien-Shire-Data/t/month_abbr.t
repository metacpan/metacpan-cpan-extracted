package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __month_abbr };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 13;

is( __month_abbr( 0 ), '', q<A holiday> );

is( __month_abbr( 1 ), 'Ayu', q<Month 1> );

is( __month_abbr( 2 ), 'Sol', q<Month 2> );

is( __month_abbr( 3 ), 'Ret', q<Month 3> );

is( __month_abbr( 4 ), 'Ast', q<Month 4> );

is( __month_abbr( 5 ), 'Thr', q<Month 5> );

is( __month_abbr( 6 ), 'Fli', q<Month 6> );

is( __month_abbr( 7 ), 'Ali', q<Month 7> );

is( __month_abbr( 8 ), 'Wed', q<Month 8> );

is( __month_abbr( 9 ), 'Hal', q<Month 9> );

is( __month_abbr( 10 ), 'Win', q<Month 10> );

is( __month_abbr( 11 ), 'Blo', q<Month 11> );

is( __month_abbr( 12 ), 'Fyu', q<Month 12> );

1;

# ex: set textwidth=72 :
