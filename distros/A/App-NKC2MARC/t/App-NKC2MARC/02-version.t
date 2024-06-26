use strict;
use warnings;

use App::NKC2MARC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::NKC2MARC::VERSION, 0.01, 'Version.');
