#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Record' );
}

diag( "Testing Data::Record $Data::Record::VERSION, Perl $], $^X" );
