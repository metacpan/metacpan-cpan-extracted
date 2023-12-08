use strict;
use warnings;

use Config::Dot;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Config::Dot::VERSION, 0.1, 'Version.');
