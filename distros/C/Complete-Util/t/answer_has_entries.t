#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Util qw(answer_has_entries);

ok( answer_has_entries([0]));
ok( answer_has_entries({words=>[0]}));
ok(!answer_has_entries([]));
ok(!answer_has_entries({words=>[]}));
ok(!answer_has_entries({}));

done_testing;
