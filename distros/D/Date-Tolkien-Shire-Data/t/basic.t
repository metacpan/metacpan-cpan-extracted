package main;

use 5.006002;

use strict;
use warnings;

use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 6;

require_ok( 'Date::Tolkien::Shire::Data' );

my $is_leap = Date::Tolkien::Shire::Data->can( '__is_leap_year' );

ok( $is_leap, 'Have __is_leap_year()' );

is( $is_leap->( 1 ), 0, 'Shire year 1 is not a leap year' );

is( $is_leap->( 4 ), 1, 'Shire year 4 is a leap year' );

is( $is_leap->( 100 ), 0, 'Shire year 100 is not a leap year' );

is( $is_leap->( 400 ), 1, 'Shire year 400 not a leap year' );

1;

# ex: set textwidth=72 :
