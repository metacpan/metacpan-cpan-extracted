use strict;
use warnings;

use App::ISBN::Format;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::ISBN::Format->new;
isa_ok($obj, 'App::ISBN::Format');
