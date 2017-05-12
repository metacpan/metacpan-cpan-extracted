use strict;
use warnings;

use Test::More;

eval "use Config::Any::TT2";
BAIL_OUT('Config::Any::TT2 not successful loaded') if $@;

use_ok('Config::Any::TT2');
done_testing();
