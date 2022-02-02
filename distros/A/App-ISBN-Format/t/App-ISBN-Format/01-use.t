use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::ISBN::Format');
}

# Test.
require_ok('App::ISBN::Format');
