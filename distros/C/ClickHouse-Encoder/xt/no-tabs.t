#!/usr/bin/env perl
# All Perl sources are space-indented; this catches accidental tabs that
# would render inconsistently in different editors / docs renderers.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run no-tabs tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::NoTabs; Test::NoTabs->import };
plan skip_all => 'Test::NoTabs not installed' if $@;

all_perl_files_ok('lib', 't', 'xt', 'eg');
