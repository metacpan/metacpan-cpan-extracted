use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib '.';
use t::Util;

is(run(qw(ansifold /dev/null))->result, "", "/dev/null");

done_testing;
