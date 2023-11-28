use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Bin::Search');
}

# Test.
require_ok('App::Bin::Search');
