use strict;
use Test::Most;

eval 'use Test::Portability::Files';
plan skip_all => "Test::Portability::Files required for testing filenames portability" if $@;
run_tests();
