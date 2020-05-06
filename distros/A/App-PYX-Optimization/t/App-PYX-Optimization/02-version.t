use strict;
use warnings;

use App::PYX::Optimization;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::PYX::Optimization::VERSION, 0.01, 'Version.');
