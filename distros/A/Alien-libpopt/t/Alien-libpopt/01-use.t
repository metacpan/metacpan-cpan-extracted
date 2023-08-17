use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Alien::libpopt');
}

# Test.
require_ok('Alien::libpopt');
