use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
use_ok( 'Algorithm::HyperLogLog' );
}

diag( "Testing Algorithm::HyperLogLog $Algorithm::HyperLogLog::VERSION" );
