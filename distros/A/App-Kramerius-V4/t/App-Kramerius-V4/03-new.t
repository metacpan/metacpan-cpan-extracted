use strict;
use warnings;

use App::Kramerius::V4;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Kramerius::V4->new;
isa_ok($obj, 'App::Kramerius::V4');
