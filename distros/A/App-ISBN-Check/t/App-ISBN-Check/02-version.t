use strict;
use warnings;

use App::ISBN::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::ISBN::Check::VERSION, 0.01, 'Version.');
