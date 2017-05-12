#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Cat::Schroedinger' ) || print "Bail out!\n";
}

diag( "Testing Acme::Cat::Schroedinger $Acme::Cat::Schroedinger::VERSION, Perl $], $^X" );
