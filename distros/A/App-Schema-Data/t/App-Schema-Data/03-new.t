use strict;
use warnings;

use App::Schema::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Schema::Data->new;
isa_ok($obj, 'App::Schema::Data');
