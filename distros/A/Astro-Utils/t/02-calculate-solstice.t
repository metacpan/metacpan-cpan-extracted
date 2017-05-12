#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Astro::Utils;

is(calculate_solstice('jun', 'utc', 2000), '2000-06-21 01:47:43');
is(calculate_solstice('dec', 'utc', 2000), '2000-12-21 13:37:40');

is(calculate_solstice('jun', 'tdt', 2000), '2000-06-21 01:48:47');
is(calculate_solstice('dec', 'tdt', 2000), '2000-12-21 13:38:44');

done_testing();
