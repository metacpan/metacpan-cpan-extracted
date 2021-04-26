use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';
use Text::ParseWords;

use lib '.';
use t::Util;

is(run(qw'ansifold /dev/null')->status, 0, "/dev/null");
is(run(qw'ansifold --invalid')->status, 2, "invalid option");

done_testing;
