use strict;
use warnings;

use App::Kramerius::URI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Kramerius::URI->new;
isa_ok($obj, 'App::Kramerius::URI');
