# Pragmas.
use strict;
use warnings;

# Modules.
use App::Translit::String;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Translit::String->new;
isa_ok($obj, 'App::Translit::String');
