use strict;
use warnings;

use App::Lorem::Tickit;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Lorem::Tickit->new;
isa_ok($obj, 'App::Lorem::Tickit');
