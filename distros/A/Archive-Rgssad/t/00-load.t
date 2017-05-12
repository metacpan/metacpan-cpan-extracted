#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Archive::Rgssad' ) || print "Bail out!\n";
    use_ok( 'Archive::Rgssad::Entry' ) || print "Bail out!\n";
}

diag( "Testing Archive::Rgssad $Archive::Rgssad::VERSION, Perl $], $^X" );
