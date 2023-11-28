use strict;
use warnings;

use App::Bin::Search;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Bin::Search->new;
isa_ok($obj, 'App::Bin::Search');
