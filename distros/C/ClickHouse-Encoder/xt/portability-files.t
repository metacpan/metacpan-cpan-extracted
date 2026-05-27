#!/usr/bin/env perl
# Test::Portability::Files: catches case-collisions on case-insensitive
# filesystems (macOS / Windows), filenames with reserved characters,
# overlong paths, and other gotchas downstream packagers hit. Cheap
# author-only test; runs only with RELEASE_TESTING=1.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run portability-files tests'
    unless $ENV{RELEASE_TESTING};

eval {
    require Test::Portability::Files;
    Test::Portability::Files->import;
};
plan skip_all => 'Test::Portability::Files not installed' if $@;

run_tests();
