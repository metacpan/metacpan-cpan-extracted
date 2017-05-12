#!perl -Tw

use Test::More tests => 1;

use Carp::Assert::More;

diag( "Testing Carp::Assert::More $Carp::Assert::More::VERSION, Test::More $Test::More::VERSION, Perl $], $^X" );

pass( 'Module loaded' );
