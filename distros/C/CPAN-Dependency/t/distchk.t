use strict;
use Test::More;
eval "use Test::Distribution not => 'prereq'";
plan skip_all => "Test::Distribution required for checking distribution" if $@;
