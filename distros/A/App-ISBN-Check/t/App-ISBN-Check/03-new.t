use strict;
use warnings;

use App::ISBN::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::ISBN::Check->new;
isa_ok($obj, 'App::ISBN::Check');
