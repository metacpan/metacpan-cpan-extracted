#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::PBC::WIBE' ) || print "Bail out!
";
}

diag( "Testing Crypt::PBC::WIBE module, Perl $], $^X" );
