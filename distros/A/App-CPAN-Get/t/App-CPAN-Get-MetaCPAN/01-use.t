use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::CPAN::Get::MetaCPAN');
}

# Test.
require_ok('App::CPAN::Get::MetaCPAN');
