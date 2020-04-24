use strict;
use warnings;

use App::Video::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Video::Generator->new;
isa_ok($obj, 'App::Video::Generator');
