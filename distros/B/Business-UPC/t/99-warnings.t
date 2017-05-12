
use strict;
use Test;

BEGIN { plan tests => 3, todo => [] }

use Business::UPC;

# an object to test with:
my $upc;

# Test for warnings...

{
    my $err;
    local $^W = 1;
    local $SIG{ __WARN__ } = sub { $err = "@_" };
    $upc = new Business::UPC('512345678900');
    ok($upc);
    ok($upc->fix_check_digit);
    ok(! $err);
}

