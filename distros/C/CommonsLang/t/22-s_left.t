use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_left("abc", -1), "",    's_left.');
is(s_left("abc",  0), "",    's_left.');
is(s_left("abc",  1), "a",   's_left.');
is(s_left("abc",  2), "ab",  's_left.');
is(s_left("abc",  3), "abc", 's_left.');
is(s_left("abc",  4), "abc", 's_left.');

############
done_testing();
