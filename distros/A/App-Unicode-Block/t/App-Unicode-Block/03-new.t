use strict;
use warnings;

use App::Unicode::Block;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Unicode::Block->new;
isa_ok($obj, 'App::Unicode::Block');
