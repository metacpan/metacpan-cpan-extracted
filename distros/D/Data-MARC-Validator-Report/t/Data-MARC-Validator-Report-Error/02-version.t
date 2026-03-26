use strict;
use warnings;

use Data::MARC::Validator::Report::Error;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Validator::Report::Error::VERSION, 0.03, 'Version.');
