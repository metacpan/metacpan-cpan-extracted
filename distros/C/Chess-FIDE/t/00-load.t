#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Chess::FIDE::Player' ) || print "Bail out!\n";
    use_ok( 'Chess::FIDE' ) || print "Bail out!\n";
}

diag( "Testing Chess::FIDE $Chess::FIDE::VERSION, Perl $], $^X" );
