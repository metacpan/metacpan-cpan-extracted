use strict;
use warnings;

use App::Kramerius::V4;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Kramerius::V4::VERSION, 0.02, 'Version.');
