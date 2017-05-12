use strict;
use Test::More;

use_ok('UnsafeInc');

is($ENV{PERL_USE_UNSAFE_INC}, 1, 'PERL_USE_UNSAFE_INC set');

done_testing;
