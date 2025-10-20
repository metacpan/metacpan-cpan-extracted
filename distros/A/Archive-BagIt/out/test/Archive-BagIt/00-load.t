#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archive::BagIt' ) || print "Bail out!\n";
}

diag( "Testing Archive::BagIt $Archive::BagIt::VERSION, Perl $], $^X" );
