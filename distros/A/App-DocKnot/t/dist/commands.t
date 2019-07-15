#!/usr/bin/perl
#
# Tests for App::DocKnot::Dist command selection to generate a distribution.
#
# Copyright 2019 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use File::Spec;

use Test::More tests => 7;

# Load the module.
BEGIN { use_ok('App::DocKnot::Dist') }

# Use the same test cases that we use for generate, since they represent the
# same variety of build systems.
my $dataroot = File::Spec->catfile('t', 'data', 'generate');

# Module::Build distribution (use App::DocKnot itself and default paths).
my $docknot = App::DocKnot::Dist->new({ distdir => q{.} });
#<<<
my @expected = (
    ['perl', 'Build.PL'],
    ['./Build', 'disttest'],
    ['./Build', 'dist'],
);
#>>>
my @seen = $docknot->commands();
is_deeply(\@seen, \@expected, 'Module::Build');

# Test configuring an alternate path to Perl.
$docknot = App::DocKnot::Dist->new({ distdir => q{.}, perl => '/a/perl' });
#<<<
@expected = (
    ['/a/perl', 'Build.PL'],
    ['./Build', 'disttest'],
    ['./Build', 'dist'],
);
#>>>
@seen = $docknot->commands();
is_deeply(\@seen, \@expected, 'Module::Build');

# ExtUtils::MakeMaker distribution.
my $metadata_path = File::Spec->catfile($dataroot, 'ansicolor', 'metadata');
$docknot
  = App::DocKnot::Dist->new({ distdir => q{.}, metadata => $metadata_path });
#<<<
@expected = (
    ['perl', 'Makefile.PL'],
    ['make', 'disttest'],
    ['make', 'dist'],
);
#>>>
@seen = $docknot->commands();
is_deeply(\@seen, \@expected, 'ExtUtils::MakeMaker');

# Autoconf distribution.
$metadata_path = File::Spec->catfile($dataroot, 'lbcd', 'metadata');
$docknot
  = App::DocKnot::Dist->new({ distdir => q{.}, metadata => $metadata_path });
#<<<
@expected = (
    ['./bootstrap'],
    ['./configure', 'CC=clang'],
    ['make', 'warnings'],
    ['make', 'check'],
    ['make', 'clean'],
    ['./configure', 'CC=gcc'],
    ['make', 'warnings'],
    ['make', 'check'],
    ['make', 'clean'],
    ['make', 'check-cppcheck'],
    ['make', 'distcheck'],
);
#>>>
@seen = $docknot->commands();
is_deeply(\@seen, \@expected, 'Autoconf');

# Autoconf distribution with C++ and valgrind.
$metadata_path = File::Spec->catfile($dataroot, 'c-tap-harness', 'metadata');
$docknot
  = App::DocKnot::Dist->new({ distdir => q{.}, metadata => $metadata_path });
#<<<
@expected = (
    ['./bootstrap'],
    ['./configure', 'CC=g++'],
    ['make', 'warnings'],
    ['make', 'check'],
    ['make', 'clean'],
    ['./configure', 'CC=clang'],
    ['make', 'warnings'],
    ['make', 'check'],
    ['make', 'clean'],
    ['./configure', 'CC=gcc'],
    ['make', 'warnings'],
    ['make', 'check'],
    ['make', 'check-valgrind'],
    ['make', 'clean'],
    ['make', 'check-cppcheck'],
    ['make', 'distcheck'],
);
#>>>
@seen = $docknot->commands();
is_deeply(\@seen, \@expected, 'Autoconf with C++');

# Makefile only distribution (make).
$metadata_path = File::Spec->catfile($dataroot, 'control-archive', 'metadata');
$docknot
  = App::DocKnot::Dist->new({ distdir => q{.}, metadata => $metadata_path });
@expected = (['make', 'dist']);
@seen     = $docknot->commands();
is_deeply(\@seen, \@expected, 'make');
