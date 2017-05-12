# Pragmas.
use strict;
use warnings;

# Modules.
use App::HL7::Dump;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::HL7::Dump::VERSION, 0.02, 'Version.');
