#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Israeli' );
}

diag( "Testing Acme::CPANAuthors::Israeli $Acme::CPANAuthors::Israeli::VERSION, Perl $], $^X" );
