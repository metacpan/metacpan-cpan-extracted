use strict;
use warnings;

use App::CPAN::Get::MetaCPAN;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::CPAN::Get::MetaCPAN::VERSION, 0.13, 'Version.');
