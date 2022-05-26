use strict;
use warnings;

use App::Stow::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Stow::Check->new;
isa_ok($obj, 'App::Stow::Check');
