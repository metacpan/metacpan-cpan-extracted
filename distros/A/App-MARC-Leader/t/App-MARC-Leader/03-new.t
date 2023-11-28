use strict;
use warnings;

use App::MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Leader->new;
isa_ok($obj, 'App::MARC::Leader');
