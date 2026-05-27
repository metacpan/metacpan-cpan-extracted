#!/usr/bin/env perl
# Confirms the MIN_PERL_VERSION declared in Makefile.PL is actually
# achievable: scans the Perl sources for syntax/builtins that require
# something newer than the declared minimum, and fails if any are
# found. Catches accidental drift when new code uses 5.20+ features
# without bumping the declared minimum.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run perl-version tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::MinimumVersion; Test::MinimumVersion->import };
plan skip_all => 'Test::MinimumVersion not installed' if $@;

# Match Makefile.PL's MIN_PERL_VERSION.
all_minimum_version_ok('5.010');
