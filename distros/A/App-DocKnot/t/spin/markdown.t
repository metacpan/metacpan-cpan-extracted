#!/usr/bin/perl
#
# Test Markdown conversion.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Carp qw(croak);
use Cwd qw(getcwd);
use File::Copy::Recursive qw(dircopy);
use File::Temp ();
use IPC::Cmd qw(can_run);
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

# Ensure Devel::Cover has loaded the HTML template before we start changing
# the working directory with File::Find.  (This is a dumb workaround, but I
# can't find a better one; +ignore doesn't work.)
my $pointer = App::DocKnot::Spin::Pointer->new();
my $template = $pointer->appdata_path('templates', 'html.tmpl');
my $tt = Template->new({ ABSOLUTE => 1 }) or croak(Template->error());
$tt->process($template, {}, \my $result);

# Spin the tree of files and check the result.
my $datadir = File::Spec->catfile('t', 'data', 'spin', 'markdown');
my $input = File::Spec->catfile($datadir, 'input');
my $output = File::Temp->newdir();
my $expected = File::Spec->catfile($datadir, 'output');
my $spin = App::DocKnot::Spin->new({ 'style-url' => '/~eagle/styles/' });
my $stdout = capture_stdout { $spin->spin($input, $output->dirname) };
my $count = is_spin_output_tree($output, $expected, 'spin');

# Report the end of testing.
done_testing($count + 2);
