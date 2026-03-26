use strict;
use warnings;

use Data::MARC::Validator::Report::Plugin::Errors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Validator::Report::Plugin::Errors::VERSION, 0.03, 'Version.');
