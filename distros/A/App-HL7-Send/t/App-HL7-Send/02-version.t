# Pragmas.
use strict;
use warnings;

# Modules.
use App::HL7::Send;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::HL7::Send::VERSION, 0.01, 'Version.');
