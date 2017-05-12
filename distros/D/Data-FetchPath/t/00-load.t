#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::FetchPath' );
}

diag( "Testing Data::FetchPath $Data::FetchPath::VERSION, Perl $], $^X" );
