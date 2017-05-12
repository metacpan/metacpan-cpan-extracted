#!perl
use strict;
use Test::More tests => 3;

my $package = 'Date::Holidays::USFederal';
use_ok( $package );

is( is_usfed_holiday( 2004,  1, 14 ), undef,
    "14th January isn't a Bank Holiday (yet)" );
is( is_usfed_holiday( 2004, 12, 24 ), "Christmas Day",
    "oddball christmas on a Saturday" );
