use strict;
use Acme::Test::VW;
use Test::More;

ok 1 == 2;
cmp_ok 1, '>', 2;

done_testing;
