#!perl -T

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Required modules for this test
test_requires 'Test::EOL' => '0.6';

# Test for Windows EOL and trailing whitespace
all_perl_files_ok({
	trailing_whitespace => 1,
});
