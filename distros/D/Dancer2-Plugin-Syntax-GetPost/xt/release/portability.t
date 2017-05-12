#!perl

use Test::More;

eval 'use Test::Portability::Files';
plan skip_all => 'Test::Portability::Files required for testing portability'
    if $@;
options(test_one_dot => 0);
run_tests();
