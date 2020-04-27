use strict;
use warnings;

use App::PYX2XML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::PYX2XML->new;
isa_ok($obj, 'App::PYX2XML');
