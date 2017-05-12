#!perl
use strict;
use Test::More tests => 3;

my $package = 'Date::Holidays::UK';
use_ok( $package );

is( is_uk_holiday( 2004,  1, 14 ), undef,
    "14th January isn't a Bank Holiday (yet)" );
is( is_uk_holiday( 2004, 12, 28 ), "Substitute Bank Holiday in lieu of 25th",
    "oddball christmas on a Saturday" );
