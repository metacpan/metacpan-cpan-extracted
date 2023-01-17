#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Parse::Modern' ) || print "Bail out!\n";
}

diag( "Testing Date::Parse::Modern $Date::Parse::Modern::VERSION, Perl $], $^X" );
