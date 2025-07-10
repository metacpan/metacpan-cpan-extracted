use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Data::OFN::Common::TimeMoment');
}

# Test.
require_ok('Data::OFN::Common::TimeMoment');
