use strict;
use warnings;

use App::CPAN::Get::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::CPAN::Get::Utils::VERSION, 0.08, 'Version.');
