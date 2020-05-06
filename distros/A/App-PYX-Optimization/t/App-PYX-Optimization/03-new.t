use strict;
use warnings;

use App::PYX::Optimization;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::PYX::Optimization->new;
isa_ok($obj, 'App::PYX::Optimization');
