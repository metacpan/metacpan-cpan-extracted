use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_trim("a "),    "a", 's_trim.');
is(s_trim("a  "),   "a", 's_trim.');
is(s_trim(" a"),    "a", 's_trim.');
is(s_trim("  a"),   "a", 's_trim.');
is(s_trim(" a "),   "a", 's_trim.');
is(s_trim("  a  "), "a", 's_trim.');

############
done_testing();
