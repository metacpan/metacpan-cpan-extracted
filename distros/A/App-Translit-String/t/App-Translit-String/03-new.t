use strict;
use warnings;

use App::Translit::String;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Translit::String->new;
isa_ok($obj, 'App::Translit::String');
