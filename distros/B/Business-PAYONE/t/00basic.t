use Test::More (tests => 1);
use Test::Exception;

BEGIN {
  use_ok( 'Business::PAYONE' );
}

use Business::PAYONE;

diag( "Testing Business::PAYONE $Business::PAYONE::VERSION" );

done_testing();
