#!/usr/bin/perl
#
# Tests for the App::DocKnot command dispatch for spin and spin-file.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture capture_stdout);
use Cwd qw(getcwd realpath);
use File::Copy::Recursive qw(dircopy);
use File::Spec ();
use File::Temp ();
use Test::RRA qw(is_file_contents);
use Test::DocKnot::Spin qw(is_spin_output is_spin_output_tree);

use Test::More;

# Load the module.
BEGIN { use_ok('App::DocKnot::Command') }

# Create the command-line parser.
my $docknot = App::DocKnot::Command->new();
isa_ok($docknot, 'App::DocKnot::Command');

# Create a temporary directory for test output.
my $tempdir = File::Temp->newdir();

# Spin a single file.
my $datadir  = File::Spec->catfile('t',      'data',   'spin');
my $input    = File::Spec->catfile($datadir, 'input',  'index.th');
my $expected = File::Spec->catfile($datadir, 'output', 'index.html');
my $output   = File::Spec->catfile($tempdir->dirname, 'index.html');
$docknot->run('spin-thread', '-s', '/~eagle/styles', $input, $output);
is_spin_output($output, $expected, 'spin-thread (output specified)');

# Spin a single file to standard output.
my $stdout = capture_stdout {
    $docknot->run('spin-thread', '-s', '/~eagle/styles', $input);
};
open(my $output_fh, '>', $output);
print {$output_fh} $stdout or BAIL_OUT("Cannot write to $output: $!");
close($output_fh);
is_spin_output($output, $expected, 'spin-thread (standard output)');

# Copy the input tree to a new temporary directory since .rss files generate
# additional thread files.  Replace the rpod pointer since it points to a
# relative path in the source tree.
my $indir = File::Temp->newdir();
$input = File::Spec->catfile($datadir, 'input');
dircopy($input, $indir->dirname)
  or die "Cannot copy $input to $indir: $!\n";
my $rpod_source = File::Spec->catfile(getcwd(), 'lib', 'App', 'DocKnot.pm');
my $rpod_path   = File::Spec->catfile(
    $indir->dirname, 'software', 'docknot', 'api',
    'app-docknot.rpod',
);
chmod(0644, $rpod_path);
open(my $fh, '>', $rpod_path);
print {$fh} "$rpod_source\n" or die "Cannot write to $rpod_path: $!\n";
close($fh);

# Spin a tree of files.
$expected = File::Spec->catfile($datadir, 'output');
capture_stdout {
    $docknot->run(
        'spin', '-s', '/~eagle/styles', $indir->dirname,
        $tempdir->dirname,
    );
};
my $count = is_spin_output_tree($tempdir->dirname, $expected, 'spin');

# Spin a file with warnings.  The specific warnings are checked in
# t/spin/errors.t; here, we just check the rewrite of the warning.
my $errors = realpath(File::Spec->catfile($datadir, 'errors', 'errors.th'));
my $stderr;
($stdout, $stderr) = capture {
    $docknot->run('spin-thread', $errors);
};
like(
    $stderr, qr{ \A \Q$0\E [ ] spin-thread : \Q$errors\E : 1 : }xms,
    'warnings are properly rewritten',
);

# Report the end of testing.
done_testing($count + 5);
