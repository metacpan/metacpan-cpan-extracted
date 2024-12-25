use strict;
use warnings;

use CommonsLang;
use Test::More;

##
is(a_join(s_split("1.2.3", "\\."), ", "), "1, 2, 3", 's_split.');

############
done_testing();
