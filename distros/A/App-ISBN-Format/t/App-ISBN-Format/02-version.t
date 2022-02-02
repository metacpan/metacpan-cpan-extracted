use strict;
use warnings;

use App::ISBN::Format;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::ISBN::Format::VERSION, 0.01, 'Version.');
