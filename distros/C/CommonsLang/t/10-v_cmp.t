use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(v_cmp("a", "b"), -1, 'v_cmp.');
##
is(v_cmp("b", "a"), 1, 'v_cmp.');
##
is(v_cmp("a", "a"), 0, 'v_cmp.');
##
is(v_cmp(1, 2), -1, 'v_cmp.');
##
is(v_cmp(2, 1), 1, 'v_cmp.');
##
is(v_cmp(1, 1), 0, 'v_cmp.');
##
my $xxx = [ 1, 2 ];
is(v_cmp($xxx, $xxx), 0, 'v_cmp.');
##
eval { v_cmp([ 1, 2 ], [ 1, 2 ]) };
like($@, qr/Not able to compare./, 'v_cmp.');
##
eval { v_cmp([ 1, 2 ], [ 1, 2, 3 ]) };
like($@, qr/Not able to compare./, 'v_cmp.');
##
my $hhh = { k => 1 };
is(v_cmp($hhh, $hhh), 0, 'v_cmp.');
##
eval { v_cmp({ k => 1 }, { k => 1 }) };
like($@, qr/Not able to compare./, 'v_cmp.');
##
eval { v_cmp({ k => 1 }, { n => 1 }) };
like($@, qr/Not able to compare./, 'v_cmp.');
##
is(v_cmp(undef, ""), -1, 'v_cmp.');
##
is(v_cmp(1, undef), 1, 'v_cmp.');
##
is(v_cmp(undef, undef), 0, 'v_cmp.');
############
##
eval { v_cmp(1, { n => 1 }) };
like($@, qr/Not able to compare./, 'v_cmp.');
# ##
############
done_testing();
