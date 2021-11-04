use strict;
use warnings;

use App::Image::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Image::Generator->new;
isa_ok($obj, 'App::Image::Generator');
