use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Alt::Digest::MD5::OpenSSL');
}

# Test.
require_ok('Alt::Digest::MD5::OpenSSL');
