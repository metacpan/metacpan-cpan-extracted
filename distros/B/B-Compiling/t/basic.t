use strict;
use warnings;
use Test::More tests => 4;

use B::Compiling;

BEGIN {
    ok(defined &PL_compiling, 'PL_compiling gets exported');

    my $cop = PL_compiling;
    ok($cop = PL_compiling, 'returns the same reference every time');

    isa_ok($cop, 'B::COP');
    like($cop->file, qr{t/basic.t$}, 'basic sanity');
}
