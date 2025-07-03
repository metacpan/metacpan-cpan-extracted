use strict;
use warnings;

use App::MARC::Validator::Report;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Validator::Report->new;
isa_ok($obj, 'App::MARC::Validator::Report');
