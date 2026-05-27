#!/usr/bin/env perl
# Verifies the SYNOPSIS POD section actually compiles. Runs only with
# RELEASE_TESTING=1 and Test::Synopsis installed; protects against POD
# code-rot when method signatures change.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run synopsis tests'
    unless $ENV{RELEASE_TESTING};

eval { require Test::Synopsis; Test::Synopsis->import };
plan skip_all => 'Test::Synopsis not installed' if $@;

Test::Synopsis::all_synopsis_ok('lib');
