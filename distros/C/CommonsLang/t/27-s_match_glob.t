use strict;
use warnings;

use CommonsLang;
use Test::More;

##
is(s_match_glob("foo.*",  "foo.bar"), 1, 's_match_glob.');
is(s_match_glob("fo2o.*", "foo.bar"), 0, 's_match_glob.');

############
done_testing();
