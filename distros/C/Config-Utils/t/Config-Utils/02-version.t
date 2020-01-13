use strict;
use warnings;

use Config::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Config::Utils::VERSION, 0.07, 'Version.');
