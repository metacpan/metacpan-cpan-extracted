#!/usr/bin/perl
#
# Tests for the App::DocKnot command dispatch for spin and spin-file.
#
# Copyright 2021-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture capture_stdout);
use File::Copy::Recursive qw(dircopy);
use Path::Tiny qw(path);
use POSIX qw(LC_ALL setlocale);
use Test::DocKnot::Spin qw(fix_pointers is_spin_output is_spin_output_tree);

use Test::More;

# Load the modules.
BEGIN {
    use_ok('App::DocKnot::Command');
    use_ok('App::DocKnot::Util', qw(print_fh));
}

# Force the C locale because some of the output intentionally uses localized
# month names and we have to force those to English for comparison of test
# results.
setlocale(LC_ALL, 'C');

# Create the command-line parser.
my $docknot = App::DocKnot::Command->new();
isa_ok($docknot, 'App::DocKnot::Command');

# Create a temporary directory for test output.
my $tempdir = Path::Tiny->tempdir();

# Spin a single file.
my $datadir = path('t', 'data', 'spin');
my $input = $datadir->child('input', 'index.th');
my $expected = $datadir->child('output', 'index.html');
my $output = $tempdir->child('index.html');
$docknot->run('spin-thread', '-s', '/~eagle/styles', "$input", "$output");
is_spin_output($output, $expected, 'spin-thread (output specified)');

# Spin a single file to standard output.
my $stdout = capture_stdout {
    $docknot->run('spin-thread', '-s', '/~eagle/styles', "$input");
};
$output->spew($stdout);
is_spin_output($output, $expected, 'spin-thread (standard output)');

# Copy the input tree to a new temporary directory since .rss files generate
# additional thread files.
my $indir = Path::Tiny->tempdir();
$input = $datadir->child('input');
dircopy($input, $indir)
  or die "Cannot copy $input to $indir: $!\n";
fix_pointers($indir, $input);

# Spin a tree of files.
$expected = $datadir->child('output');
capture_stdout {
    $docknot->run('spin', '-s', '/~eagle/styles', "$indir", "$tempdir");
};
my $count = is_spin_output_tree($tempdir, $expected, 'spin');

# Spin a file with warnings.  The specific warnings are checked in
# t/spin/errors.t; here, we just check the rewrite of the warning.
my $errors = $datadir->child('errors', 'errors.th')->realpath();
my $stderr;
($stdout, $stderr) = capture {
    $docknot->run('spin-thread', "$errors");
};
like(
    $stderr, qr{ \A \Q$0\E [ ] spin-thread : \Q$errors\E : 1 : }xms,
    'warnings are properly rewritten',
);

# Report the end of testing.
done_testing($count + 6);
