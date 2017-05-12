#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bio::Util::DNA' );
}

diag( "Testing Bio::Util::DNA $Bio::Util::DNA::VERSION, Perl $], $^X" );
