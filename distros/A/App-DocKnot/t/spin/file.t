#!/usr/bin/perl
#
# Test running spin on a single file.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Cwd qw(getcwd);
use Fcntl qw(SEEK_SET);
use File::Spec;
use File::Temp;
use Perl6::Slurp qw(slurp);
use Test::DocKnot::Spin qw(is_spin_output);

use Test::More tests => 3;

require_ok('App::DocKnot::Spin::Thread');

# Spin a single file.
my $tempfile = File::Temp->new();
my $datadir  = File::Spec->catfile('t',       'data', 'spin');
my $inputdir = File::Spec->catfile($datadir,  'input');
my $input    = File::Spec->catfile($inputdir, 'index.th');
my $expected = File::Spec->catfile($datadir,  'output', 'index.html');
my $spin
  = App::DocKnot::Spin::Thread->new({ 'style-url' => '/~eagle/styles/' });
$spin->spin_thread_file($input, $tempfile->filename);
is_spin_output($tempfile, $expected, 'spin_thread_file with output path');

# The same but spin to standard output.
my $html = capture_stdout {
    $spin->spin_thread_file($input);
};
$tempfile->seek(0, SEEK_SET);
$tempfile->truncate(0);
print {$tempfile} $html or die "Cannot write to $tempfile: $!\n";
$tempfile->flush();
is_spin_output($tempfile->filename, $expected, 'spin_thread_file to stdout');
