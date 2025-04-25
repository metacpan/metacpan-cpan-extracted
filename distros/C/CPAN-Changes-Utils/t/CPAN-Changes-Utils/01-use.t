use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('CPAN::Changes::Utils');
}

# Test.
require_ok('CPAN::Changes::Utils');
