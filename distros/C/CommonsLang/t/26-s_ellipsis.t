use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_ellipsis("123456789012345", 10, "l"), "1234567...", 's_ellipsis.');
is(s_ellipsis("123456789012345", 10, "r"), "...9012345", 's_ellipsis.');
is(s_ellipsis("123456789012345", 10, "c"), "1234...345", 's_ellipsis.');

##
is(s_ellipsis("12345", 10, "l", "a"), "12345aaaaa", 's_ellipsis.');
is(s_ellipsis("12345", 10), "12345     ", 's_ellipsis.');

############
done_testing();
