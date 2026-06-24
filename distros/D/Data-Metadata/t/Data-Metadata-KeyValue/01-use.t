use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Data::Metadata::KeyValue');
}

# Test.
require_ok('Data::Metadata::KeyValue');
