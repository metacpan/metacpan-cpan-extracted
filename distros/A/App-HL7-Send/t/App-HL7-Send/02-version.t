use strict;
use warnings;

use App::HL7::Send;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::HL7::Send::VERSION, 0.04, 'Version.');
