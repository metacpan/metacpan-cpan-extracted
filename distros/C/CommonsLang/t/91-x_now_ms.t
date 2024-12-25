use strict;
use warnings;

use CommonsLang;
use Test::More;

########################################
is(v_type_of(x_now_ms()), "NUMBER", 'x_now_ms.');
is(v_type_of(x_now_ts()), "STRING", 'x_now_ts.');
is(length(x_now_ts()),    23,       'x_now_ts.');

########################################
done_testing();
