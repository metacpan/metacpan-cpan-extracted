use strict;
use warnings;

use App::DWG::Sort;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::DWG::Sort->new;
isa_ok($obj, 'App::DWG::Sort');
