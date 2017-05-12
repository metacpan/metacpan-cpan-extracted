package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __weekday_name };
use Test::More 0.47;	# The best we can do with Perl 5.7.2.

plan tests => 8;

is( __weekday_name( 0 ), '', q<No weekday> );

is( __weekday_name( 1 ), 'Sterday', q<Weekday 1> );

is( __weekday_name( 2 ), 'Sunday', q<Weekday 2> );

is( __weekday_name( 3 ), 'Monday', q<Weekday 3> );

is( __weekday_name( 4 ), 'Trewsday', q<Weekday 4> );

is( __weekday_name( 5 ), 'Hevensday', q<Weekday 5> );

is( __weekday_name( 6 ), 'Mersday', q<Weekday 6> );

is( __weekday_name( 7 ), 'Highday', q<Weekday 7> );

1;

# ex: set textwidth=72 :
