use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Alien::librpm');
}

# Test.
require_ok('Alien::librpm');
