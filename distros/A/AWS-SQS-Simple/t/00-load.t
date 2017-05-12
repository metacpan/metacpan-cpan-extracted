#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AWS::SQS::Simple' );
}

diag( "Testing AWS::SQS::Simple $AWS::SQS::Simple::VERSION, Perl $], $^X" );
