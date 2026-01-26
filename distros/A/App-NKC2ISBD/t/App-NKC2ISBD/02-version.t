use strict;
use warnings;

use App::NKC2ISBD;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::NKC2ISBD::VERSION, 0.01, 'Version.');
