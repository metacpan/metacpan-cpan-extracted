use strict;
use warnings;

use App::Test::DWG::LibreDWG::DwgRead;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Test::DWG::LibreDWG::DwgRead->new;
isa_ok($obj, 'App::Test::DWG::LibreDWG::DwgRead');
