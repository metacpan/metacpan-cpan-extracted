# Pragmas.
use strict;
use warnings;

# Modules.
use App::Video::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Video::Generator::VERSION, 0.07, 'Version.');
