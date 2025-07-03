use strict;
use warnings;

use App::MARC::Validator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Validator->new;
isa_ok($obj, 'App::MARC::Validator');
