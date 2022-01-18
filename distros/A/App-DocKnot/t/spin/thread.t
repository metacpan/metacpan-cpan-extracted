#!/usr/bin/perl
#
# Test running spin on a scalar containing thread source.
#
# Copyright 2021-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Cwd qw(getcwd);
use Path::Tiny qw(path);
use Test::DocKnot::Spin qw(is_spin_output);

use Test::More tests => 2;

require_ok('App::DocKnot::Spin::Thread');

# Test data file paths.
my $datadir = path('t', 'data', 'spin');
my $inputdir = $datadir->child('input');
my $input = $inputdir->child('index.th');
my $expected = $datadir->child('output', 'index.html');

# The expected output is a bit different since we won't add timestamp
# information or the filename to the comment, so we have to generate our
# expected output file.
my $tempfile = Path::Tiny->tempfile();
my $output = $expected->slurp_utf8();
$output =~ s{ from [ ] index[.]th [ ] }{}xms;
$output =~ s{ <address> .* </address> \n }{}xms;
$tempfile->spew_utf8($output);

# Spin the file using the spin_thread() API, using the right working directory
# to expand \image and the like.
my $spin
  = App::DocKnot::Spin::Thread->new({ 'style-url' => '/~eagle/styles/' });
my $thread = $input->slurp_utf8();
my $cwd = getcwd();
chdir($inputdir);
my $html = $spin->spin_thread($thread);
chdir($cwd);
my $outfile = Path::Tiny->tempfile();
$outfile->spew_utf8($html);
is_spin_output($outfile, $tempfile, 'spin_thread');
