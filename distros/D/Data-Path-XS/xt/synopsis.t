use strict;
use warnings;
use Test::More;

eval { require Test::Synopsis; 1 }
    or plan skip_all => 'Test::Synopsis required to compile-test SYNOPSIS';

Test::Synopsis::all_synopsis_ok();
