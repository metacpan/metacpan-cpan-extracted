#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archive::Zip::Crypt' ) || print "Bail out!\n";
}

diag( "Testing Archive::Zip::Crypt $Archive::Zip::Crypt::VERSION, Perl $], $^X" );
