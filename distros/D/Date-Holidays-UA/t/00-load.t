#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Holidays::UA' ) || print "Bail out!\n";
}

diag( "Testing Date::Holidays::UA $Date::Holidays::UA::VERSION, Perl $], $^X" );
