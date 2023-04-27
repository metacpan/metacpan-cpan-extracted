use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Test::DWG::LibreDWG::DwgRead');
}

# Test.
require_ok('App::Test::DWG::LibreDWG::DwgRead');
