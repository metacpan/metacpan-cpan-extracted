use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Test::Shared::Fixture::Data::InfoBox::Street');
}

# Test.
require_ok('Test::Shared::Fixture::Data::InfoBox::Street');
