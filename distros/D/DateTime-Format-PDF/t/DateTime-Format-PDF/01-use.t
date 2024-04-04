use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('DateTime::Format::PDF');
}

# Test.
require_ok('DateTime::Format::PDF');
