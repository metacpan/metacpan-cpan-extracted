use strict;
use warnings;

use Digest::MD5;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Digest::MD5::VERSION, 0.04, 'Version.');
