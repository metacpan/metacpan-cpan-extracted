#!perl

use strict;
use warnings;
use Test::More 0.98;

use Business::ID::NOPPBB qw(validate_nop_pbb);

my $res;
$res = validate_nop_pbb(str => '31.71.060.001.007.0003-0');
is($res->[0], 200, "d1 success") or diag explain $res;

$res = validate_nop_pbb(str => 'NOP PBB: 31710600010070003 0');
is($res->[0], 200, "d2 success") or diag explain $res;

$res = validate_nop_pbb(str => '3171060001007000300');
is($res->[0], 400, "d2 fail: length") or diag explain $res;

$res = validate_nop_pbb(str => '007106000100700030');
is($res->[0], 400, "d2 fail: prov code") or diag explain $res;

done_testing();
