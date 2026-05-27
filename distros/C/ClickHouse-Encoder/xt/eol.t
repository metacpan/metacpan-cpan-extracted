#!/usr/bin/env perl
# Catches accidental CRLF line endings (Windows checkout pollution) and
# missing trailing newlines.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run eol tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::EOL; Test::EOL->import };
plan skip_all => 'Test::EOL not installed' if $@;

all_perl_files_ok({ trailing_whitespace => 1 }, 'lib', 't', 'xt', 'eg');
