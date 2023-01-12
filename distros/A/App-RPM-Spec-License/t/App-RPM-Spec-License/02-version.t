use strict;
use warnings;

use App::RPM::Spec::License;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::RPM::Spec::License::VERSION, 0.01, 'Version.');
