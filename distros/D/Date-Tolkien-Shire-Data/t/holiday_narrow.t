package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __holiday_narrow };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 7;

is( __holiday_narrow( 0 ), '', q<Not a holiday> );

is( __holiday_narrow( 1 ), '2Y', q<Holiday 1> );

is( __holiday_narrow( 2 ), '1L', q<Holiday 2> );

is( __holiday_narrow( 3 ), 'My', q<Holiday 3> );

is( __holiday_narrow( 4 ), 'Ol', q<Holiday 4> );

is( __holiday_narrow( 5 ), '2L', q<Holiday 5> );

is( __holiday_narrow( 6 ), '1Y', q<Holiday 6> );

1;

# ex: set textwidth=72 :
