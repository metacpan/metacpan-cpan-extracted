use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('CGI::Pure::Save');
}

# Test.
require_ok('CGI::Pure::Save');
