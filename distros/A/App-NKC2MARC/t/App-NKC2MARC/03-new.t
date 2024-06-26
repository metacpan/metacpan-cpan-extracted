use strict;
use warnings;

use App::NKC2MARC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::NKC2MARC->new;
isa_ok($obj, 'App::NKC2MARC');
