#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Version::Same' ) || print "Bail out!\n";
}

diag( "Testing Acme::Version::Same $Acme::Version::Same::VERSION, Perl $], $^X" );
