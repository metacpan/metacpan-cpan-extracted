#!/usr/bin/perl
#
# Test Markdown conversion.
#
# Copyright 2021-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Carp qw(croak);
use IPC::Cmd qw(can_run);
use Path::Tiny qw(path);
use Test::DocKnot::Spin qw(is_spin_output_tree);
use Template ();

use Test::More;

# This test can only be run if pandoc is available.
if (!can_run('pandoc')) {
    plan(skip_all => 'pandoc required for test');
}

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

require_ok('App::DocKnot::Spin');
require_ok('App::DocKnot::Spin::Pointer');

# Spin the tree of files and check the result.
my $datadir = path('t', 'data', 'spin', 'markdown');
my $input = $datadir->child('input');
my $output = Path::Tiny->tempdir();
my $expected = $datadir->child('output');
my $spin = App::DocKnot::Spin->new({ 'style-url' => '/~eagle/styles/' });
my $stdout = capture_stdout { $spin->spin($input, $output) };
my $count = is_spin_output_tree($output, $expected, 'spin');

# Report the end of testing.
done_testing($count + 2);
