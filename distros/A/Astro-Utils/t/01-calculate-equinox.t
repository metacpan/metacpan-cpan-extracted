#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Astro::Utils;

is(calculate_equinox('mar', 'utc', 2000), '2000-03-20 07:35:24');
is(calculate_equinox('sep', 'utc', 2000), '2000-09-22 17:27:50');

is(calculate_equinox('mar', 'tdt', 2000), '2000-03-20 07:36:28');
is(calculate_equinox('sep', 'tdt', 2000), '2000-09-22 17:28:54');

done_testing();
