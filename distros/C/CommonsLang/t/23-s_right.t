use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_right("abc", -1), "",    's_right.');
is(s_right("abc",  0), "",    's_right.');
is(s_right("abc",  1), "c",   's_right.');
is(s_right("abc",  2), "bc",  's_right.');
is(s_right("abc",  3), "abc", 's_right.');
is(s_right("abc",  4), "abc", 's_right.');

############
done_testing();
