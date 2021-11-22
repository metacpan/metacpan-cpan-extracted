use strict;
use warnings;

use App::Kramerius::To::Images;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Kramerius::To::Images::VERSION, 0.03, 'Version.');
