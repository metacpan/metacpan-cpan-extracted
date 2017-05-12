#!/usr/bin/perl

# Test that the build completed successfully

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings; # 1 test

use Module::Build;
my $builder = Module::Build->current;

use File::Spec;

SKIP: {
  skip('tests if libjio is built', 3) unless $builder->notes('build_libjio');

  is($builder->notes('build_result'), 0, 'Return code from make is zero ' .
    '(ie, build completed successfully)');
  ok(-e File::Spec->catfile('libjio', 'libjio', 'build', 'libjio.so'),
    'Compiled libjio.so file exists on disk');
  ok(-e File::Spec->catfile('libjio', 'libjio', 'build', 'libjio.a'),
    'Compiled libjio.a file exists on disk');
}
