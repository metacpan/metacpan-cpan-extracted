use strict;
use warnings;

use Acme::People::Happy;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::People::Happy->new;
my $ret = $obj->are_you_happy;
is($ret, "Yes, i'm.", 'Return string.');
