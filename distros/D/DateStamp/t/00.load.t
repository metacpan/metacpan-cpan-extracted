use Test::More tests => 1;

use lib "lib";  # REMOVE THIS LATER!!!!

BEGIN {
use_ok( 'DateStamp' );
}

diag( "Testing DateStamp $DateStamp::VERSION" );
