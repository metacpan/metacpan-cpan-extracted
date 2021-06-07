#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Version::Regress' ) || print "Bail out!\n";
}

diag( "Testing Acme::Version::Regress $Acme::Version::Regress::VERSION, Perl $], $^X" );
