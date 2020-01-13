#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Util qw(answer_num_entries);

is(answer_num_entries([0]), 1);
is(answer_num_entries({words=>[0]}), 1);
is(answer_num_entries([0, 1]), 2);
is(answer_num_entries({words=>[0, 1]}), 2);
is(answer_num_entries([]), 0);
is(answer_num_entries({words=>[]}), 0);
is(answer_num_entries({}), 0);

done_testing;
