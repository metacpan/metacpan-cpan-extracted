use strict;
use warnings;

use App::Perl::Module::Examples;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Perl::Module::Examples::VERSION, 0.04, 'Version.');
