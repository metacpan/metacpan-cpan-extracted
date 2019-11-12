#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

eval 'use Test::File::Codeowners';
warn $@ if $@;
plan skip_all => 'Test::File::Codeowners required for testing CODEOWNERS' if $@;

codeowners_syntax_ok();
codeowners_git_files_ok();
done_testing;
