use strict;
use warnings;

use Test::More;

use Data::Compare;

# https://github.com/DrHyde/perl-modules-Data-Compare/issues/21
is(Compare({a=>{b=>undef}}, {a=>{c=>12}}), 0, "deal correctly with undef values in hashes");

done_testing;
