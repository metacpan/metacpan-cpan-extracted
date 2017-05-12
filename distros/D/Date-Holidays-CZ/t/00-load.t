#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Date::Holidays::CZ' ) || print "Bail out!\n";
}

diag( "Testing Date::Holidays::CZ $Date::Holidays::CZ::VERSION, Perl $], $^X" );
