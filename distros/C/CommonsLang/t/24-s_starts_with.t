use strict;
use warnings;

use CommonsLang;
use Test::More;

# use Test::More 'tests' => 2;

##
is(s_starts_with("abc", "a"), 1, 's_start_with.');
is(s_starts_with("abc", "c"), 0, 's_start_with.');

##
is(s_ends_with("abc", "c"), 1, 's_ends_with.');
is(s_ends_with("abc", "a"), 0, 's_ends_with.');

############
done_testing();
