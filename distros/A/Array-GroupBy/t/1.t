#!perl -w

use strict;

use Array::GroupBy;

use Test::More tests => 1;

can_ok('Array::GroupBy', qw(igroup_by str_row_equal num_row_equal));
