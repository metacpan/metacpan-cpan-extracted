#!/usr/bin/perl
#
# Test running spin on a single file.
#
# Copyright 2021-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Fcntl qw(SEEK_SET);
use Path::Tiny qw(path);
use Test::DocKnot::Spin qw(is_spin_output);

use Test::More tests => 3;

require_ok('App::DocKnot::Spin::Thread');

# Spin a single file.
my $tempfile = Path::Tiny->tempfile();
my $datadir = path('t', 'data', 'spin');
my $inputdir = $datadir->child('input');
my $input = $inputdir->child('index.th');
my $expected = $datadir->child('output', 'index.html');
my $spin
  = App::DocKnot::Spin::Thread->new({ 'style-url' => '/~eagle/styles/' });
$spin->spin_thread_file($input, $tempfile);
is_spin_output($tempfile, $expected, 'spin_thread_file with output path');

# The same but spin to standard output.
my $html = capture_stdout {
    $spin->spin_thread_file($input);
};
$tempfile->spew($html);
is_spin_output($tempfile, $expected, 'spin_thread_file to stdout');
