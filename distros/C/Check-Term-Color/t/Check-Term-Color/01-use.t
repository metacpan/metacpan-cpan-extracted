use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Check::Term::Color');
}

# Test.
require_ok('Check::Term::Color');
