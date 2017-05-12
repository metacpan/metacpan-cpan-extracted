#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Amazon::SQS::Simple' );
}

diag( "Testing Amazon::SQS::Simple $Amazon::SQS::Simple::VERSION, Perl $], $^X" );
