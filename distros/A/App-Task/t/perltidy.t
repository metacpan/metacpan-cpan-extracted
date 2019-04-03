#!perl

use Test::More;
plan skip_all => 'PerlTidy tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::PerlTidy';
plan skip_all => 'Test::PerlTidy required for testing PerlTidy-ness' if $@;
Test::PerlTidy::run_tests();
