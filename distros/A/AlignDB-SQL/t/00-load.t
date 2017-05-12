#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AlignDB::SQL' );
}

diag( "Testing AlignDB::SQL $AlignDB::SQL::VERSION, Perl $], $^X" );
