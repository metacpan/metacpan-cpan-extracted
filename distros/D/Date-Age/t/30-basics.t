use strict;
use warnings;
use Test::More tests => 3;

use_ok('Date::Age', qw(describe details));

is(describe('1943-05-01', '2016-01-01'), '72', 'Exact date gives exact age');
is(describe('1943', '2016'), '72-73', 'Year-only gives age range');
