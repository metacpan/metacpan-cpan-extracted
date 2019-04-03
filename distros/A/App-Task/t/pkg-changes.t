#!perl

use Test::More;
plan skip_all => 'pkg/Changes tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::CPAN::Changes 0.23';
plan skip_all => 'Test::CPAN::Changes 0.23 required for testing the pkg/Changes file' if $@;

changes_ok();    # this does the plan
