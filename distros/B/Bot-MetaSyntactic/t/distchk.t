use strict;
use Test::More;
eval "use Test::Distribution";
plan skip_all => "Test::Distribution required for checking distribution" if $@;
