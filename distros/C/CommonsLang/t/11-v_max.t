use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(v_max(),              undef, 'v_max.');
is(v_max("a"),           "a",   'v_max.');
is(v_max("a", "b"),      "b",   'v_max.');
is(v_max("a", "b", "c"), "c",   'v_max.');
is(v_max("b", "a"),      "b",   'v_max.');
is(v_max("a", "c", "b"), "c",   'v_max.');
is(v_max(1),             1,     'v_max.');
is(v_max(1, 2),          2,     'v_max.');
is(v_max(1, 2, 3),       3,     'v_max.');
is(v_max(2, 1),          2,     'v_max.');
is(v_max(3, 2, 1),       3,     'v_max.');

##
is(v_min(),              undef, 'v_min.');
is(v_min("a"),           "a",   'v_min.');
is(v_min("a", "b"),      "a",   'v_min.');
is(v_min("a", "b", "c"), "a",   'v_min.');
is(v_min("b", "a"),      "a",   'v_min.');
is(v_min("a", "c", "b"), "a",   'v_min.');
is(v_min(1),             1,     'v_min.');
is(v_min(1, 2),          1,     'v_min.');
is(v_min(1, 2, 3),       1,     'v_min.');
is(v_min(2, 1),          1,     'v_min.');
is(v_min(3, 2, 1),       1,     'v_min.');

############
done_testing();
