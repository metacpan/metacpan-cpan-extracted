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
use POSIX qw(LC_ALL setlocale);
use Test::RRA qw(is_file_contents);
use Test::DocKnot::Spin qw(is_spin_output is_spin_output_tree);

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
my $tempdir = File::Temp->newdir();

# Spin a single file.
my $datadir = File::Spec->catfile('t', 'data', 'spin');
my $input = File::Spec->catfile($datadir, 'input', 'index.th');
my $expected = File::Spec->catfile($datadir, 'output', 'index.html');
my $output = File::Spec->catfile($tempdir->dirname, 'index.html');
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
# additional thread files.  Replace the .spin pointer since it points to a
# relative path in the source tree.
my $indir = File::Temp->newdir();
$input = File::Spec->catfile($datadir, 'input');
dircopy($input, $indir->dirname)
  or die "Cannot copy $input to $indir: $!\n";
my $pod_source = File::Spec->catfile(getcwd(), 'lib', 'App', 'DocKnot.pm');
my $pointer_path = File::Spec->catfile(
    $indir->dirname, 'software', 'docknot', 'api',
    'app-docknot.spin',
);
chmod(0644, $pointer_path);
open(my $fh, '>', $pointer_path);
print_fh($fh, $pointer_path, "format: pod\n");
print_fh($fh, $pointer_path, "path: $pod_source\n");
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
done_testing($count + 6);
