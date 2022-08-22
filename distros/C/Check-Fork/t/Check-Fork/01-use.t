use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Check::Fork');
}

# Test.
require_ok('Check::Fork');
