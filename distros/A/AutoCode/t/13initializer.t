use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests => 7}

use InitializerTest;
ok 1;

my $obj = InitializerTest->new(
    -aa => 'xx',
    -bb => 'yy',
    -ccs => [qw(xy yx zz)]
);

ok $obj->aa, 'xx';
ok $obj->bb, 'yy';
my @ccs=$obj->get_ccs;
ok scalar(@ccs), 3;
ok $ccs[0], 'xy';
ok $ccs[1], 'yx';
ok $ccs[2], 'zz';

