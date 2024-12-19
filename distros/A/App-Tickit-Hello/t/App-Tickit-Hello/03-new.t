use strict;
use warnings;

use App::Tickit::Hello;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Tickit::Hello->new;
isa_ok($obj, 'App::Tickit::Hello');
