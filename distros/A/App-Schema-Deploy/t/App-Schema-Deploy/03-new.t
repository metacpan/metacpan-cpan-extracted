use strict;
use warnings;

use App::Schema::Deploy;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Schema::Deploy->new;
isa_ok($obj, 'App::Schema::Deploy');
