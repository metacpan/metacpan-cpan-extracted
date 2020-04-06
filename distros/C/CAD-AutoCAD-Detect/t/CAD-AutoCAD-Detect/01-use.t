use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('CAD::AutoCAD::Detect');
}

# Test.
require_ok('CAD::AutoCAD::Detect');
