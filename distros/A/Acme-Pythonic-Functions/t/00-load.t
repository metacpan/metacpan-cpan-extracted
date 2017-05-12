#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Pythonic::Functions' ) || print "Bail out!\n";
}

diag( "Testing Acme::Pythonic::Functions $Acme::Pythonic::Functions::VERSION, Perl $], $^X" );
