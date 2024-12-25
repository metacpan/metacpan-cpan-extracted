use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_pad("a", 5), "a    ", 's_pad.');
is(s_pad("a", 5, "r", "0"), "a0000",   's_pad.');
is(s_pad("a", 5, "l", "0"), "0000a",   's_pad.');
is(s_pad("a", 5, "c", "0"), "00a00",   's_pad.');
is(s_pad("a", 6, "c", "0"), "00a000",  's_pad.');
is(s_pad("a", 7, "c", "0"), "000a000", 's_pad.');

##
is(s_pad("abcdef", 5), "abcdef", 's_pad.');
## truncated when over width
is(s_pad("abcdef", 5, "c", "0", 1), "abcde", 's_pad.');

##
is(s_pad("", 5), "     ", 's_pad.');

# is(s_pad(0,  5), "0    ", 's_pad.');
is(s_pad("a",  2), "a ", 's_pad.');
is(s_pad("a",  1), "a",  's_pad.');
is(s_pad("a",  0), "a",  's_pad.');
is(s_pad("a", -1), "a",  's_pad.');
is(s_pad("a", -2), "a",  's_pad.');
is(s_pad("a", -3), "a",  's_pad.');
##
is_deeply(s_pad([ "a", "b" ], 5, "r", "0"), [ 'a0000', 'b0000' ], 's_pad.');

############
done_testing();
