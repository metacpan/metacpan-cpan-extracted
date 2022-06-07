use strict;
use warnings;

use App::Toolforge::MixNMatch;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Toolforge::MixNMatch->new;
isa_ok($obj, 'App::Toolforge::MixNMatch');
