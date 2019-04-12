#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::TT::Progressive' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::View::TT::Progressive $Catalyst::View::TT::Progressive::VERSION, Perl $], $^X" );
