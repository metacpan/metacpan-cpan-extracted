#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CPAN::Mini::FromList' );
}

diag( "Testing CPAN::Mini::FromList $CPAN::Mini::FromList::VERSION, Perl $], $^X" );
