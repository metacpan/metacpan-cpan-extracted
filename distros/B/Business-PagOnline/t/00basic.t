use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Business::PagOnline' );
}

use Business::PagOnline;

diag( "Testing Business::PagOnline $Business::PagOnline::VERSION" );

done_testing();
