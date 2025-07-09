use strict;
use warnings;

use CEFACT::Unit;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CEFACT::Unit->new;
my $ret = $obj->check_common_code('KGM');
is($ret, 1, "Check common code for 'KGM' (1).");

# Test.
$ret = $obj->check_common_code('XXX');
is($ret, 0, "Check common code for 'XXX' (0).");
