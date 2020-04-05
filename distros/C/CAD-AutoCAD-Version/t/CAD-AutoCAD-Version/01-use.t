use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('CAD::AutoCAD::Version');
}

# Test.
require_ok('CAD::AutoCAD::Version');
