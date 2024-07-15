#!/usr/bin/perl
#
# Test converting a single text file.
#
# Copyright 2022, 2024 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Path::Tiny qw(path);
use Test::DocKnot::Spin qw(is_spin_output);

use Test::More tests => 5;

require_ok('App::DocKnot::Spin::Text');

# Paths to input and output.
my $tempfile = Path::Tiny->tempfile();
my $datadir = path('t', 'data', 'spin', 'text');
my $inputdir = $datadir->child('input');
my $outputdir = $datadir->child('output');

# Spin a simple file.
my $spin = App::DocKnot::Spin::Text->new(
    { modified => 1, style => '/~eagle/styles/faq-short.css' },
);
my $input = $inputdir->child('rgra');
$spin->spin_text_file($input, $tempfile);
is_spin_output(
    $tempfile, $outputdir->child('rgra.html'), "spin_text_file of $input",
);

# Spin a more complex file.
$spin = App::DocKnot::Spin::Text->new(
    { modified => 1, style => '/~eagle/styles/faq.css' },
);
$input = $inputdir->child('mjqmail');
$spin->spin_text_file($input, $tempfile);
is_spin_output(
    $tempfile, $outputdir->child('mjqmail.html'), "spin_text_file of $input",
);

# Spin a file that tests value settings in numbered lists and has an Id
# string.
$spin = App::DocKnot::Spin::Text->new({ style => '/~eagle/styles/faq.css' });
$input = $inputdir->child('big-eight');
my $html = capture_stdout {
    $spin->spin_text_file($input);
};
$tempfile->spew($html);
is_spin_output(
    $tempfile, $outputdir->child('big-eight.html'),
    "spin_text_file of $input to stdout",
);

# Spin a Perl package changes file.
$spin = App::DocKnot::Spin::Text->new({ style => '/~eagle/styles/news.css' });
$input = $inputdir->child('docknot-changes');
$spin->spin_text_file($input, $tempfile);
is_spin_output(
    $tempfile, $outputdir->child('docknot-changes.html'),
    "spin_text_file of $input",
);
