use strict;
use warnings;

use App::HL7::Dump;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::HL7::Dump::VERSION, 0.03, 'Version.');
