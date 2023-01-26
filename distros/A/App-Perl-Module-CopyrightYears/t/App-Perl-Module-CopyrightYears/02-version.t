use strict;
use warnings;

use App::Perl::Module::CopyrightYears;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Perl::Module::CopyrightYears::VERSION, 0.03, 'Version.');
