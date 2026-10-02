#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Tiny::Math' ) || print "Bail out!\n";
}

diag( "Testing Date::Tiny::Math $Date::Tiny::Math::VERSION, Perl $], $^X" );
