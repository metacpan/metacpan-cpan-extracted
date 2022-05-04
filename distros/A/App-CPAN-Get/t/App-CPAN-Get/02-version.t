use strict;
use warnings;

use App::CPAN::Get;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::CPAN::Get::VERSION, 0.07, 'Version.');
