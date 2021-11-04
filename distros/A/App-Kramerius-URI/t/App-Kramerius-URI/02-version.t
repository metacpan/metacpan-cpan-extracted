use strict;
use warnings;

use App::Kramerius::URI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Kramerius::URI::VERSION, 0.03, 'Version.');
