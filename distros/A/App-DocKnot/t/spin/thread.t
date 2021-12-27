#!/usr/bin/perl
#
# Test running spin on a scalar containing thread source.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Cwd qw(getcwd);
use File::Spec;
use File::Temp;
use Perl6::Slurp qw(slurp);
use Test::DocKnot::Spin qw(is_spin_output);

use Test::More tests => 2;

require_ok('App::DocKnot::Spin::Thread');

# Test data file paths.
my $datadir = File::Spec->catfile('t', 'data', 'spin');
my $inputdir = File::Spec->catfile($datadir, 'input');
my $input = File::Spec->catfile($inputdir, 'index.th');
my $expected = File::Spec->catfile($datadir, 'output', 'index.html');

# The expected output is a bit different since we won't add timestamp
# information or the filename to the comment, so we have to generate our
# expected output file.
my $tempfile = File::Temp->new();
my $output = slurp($expected);
$output =~ s{ from [ ] index[.]th [ ] }{}xms;
$output =~ s{ <address> .* </address> \n }{}xms;
print {$tempfile} $output or die "Cannot write to $tempfile: $!\n";
$tempfile->flush();

# Spin the file using the spin_thread() API, using the right working directory
# to expand \image and the like.
my $spin
  = App::DocKnot::Spin::Thread->new({ 'style-url' => '/~eagle/styles/' });
my $thread = slurp($input);
my $cwd = getcwd();
chdir($inputdir);
my $html = $spin->spin_thread($thread);
chdir($cwd);
my $outfile = File::Temp->new();
print {$outfile} $html or die "Cannot write to $outfile: $!\n";
$outfile->flush();
is_spin_output($outfile->filename, $tempfile->filename, 'spin_thread');
