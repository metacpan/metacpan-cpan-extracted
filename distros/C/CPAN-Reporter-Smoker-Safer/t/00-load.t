#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CPAN::Reporter::Smoker::Safer' );
}

diag( "Testing CPAN::Reporter::Smoker::Safer $CPAN::Reporter::Smoker::Safer::VERSION, Perl $], $^X" );
