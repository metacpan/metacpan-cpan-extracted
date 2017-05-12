#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Algorithm::IncludeExclude' );
}

diag( "Testing Algorithm::IncludeExclude $Algorithm::IncludeExclude::VERSION, Perl $], $^X" );
