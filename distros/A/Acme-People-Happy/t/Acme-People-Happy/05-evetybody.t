use strict;
use warnings;

use Acme::People::Happy;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::People::Happy->new;
my $ret = $obj->everybody;
is($ret, 'Everybody can be happy.', 'Return string.');
