#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bio::Tools::CodonOptTable' );
}

diag( "Testing Bio::Tools::CodonOptTable $Bio::Tools::CodonOptTable::VERSION, Perl $], $^X" );
