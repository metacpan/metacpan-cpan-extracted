#!/usr/bin/perl
#
# Tests for the App::DocKnot command dispatch for generate.
#
# Copyright 2018-2020 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Cwd qw(getcwd);
use File::Temp;
use File::Spec;
use Perl6::Slurp;
use Test::RRA qw(is_file_contents);

use Test::More tests => 7;

# Load the module.
BEGIN { use_ok('App::DocKnot::Command') }

# Create the command-line parser.
my $docknot = App::DocKnot::Command->new();
isa_ok($docknot, 'App::DocKnot::Command');

# Create a temporary directory for test output.
my $tempdir = File::Temp->newdir();

# Generate the package README file to a temporary file, read it into memory,
# and compare it to the actual README file.  This duplicates part of the
# generate/self.t test, but via the command-line parser.  Do this in a
# separate block so that $tempfile goes out of scope and will be cleaned up.
{
    my $tempfile    = File::Temp->new(DIR => $tempdir);
    my $output_path = $tempfile->filename;
    $docknot->run('generate', 'readme', $output_path);
    my $output = slurp($output_path);
    is_file_contents($output, 'README', 'Generated README from argument list');
}

# Do the same thing again, but using arguments from @ARGV.
{
    my $tempfile    = File::Temp->new(DIR => $tempdir);
    my $output_path = $tempfile->filename;
    local @ARGV = ('generate', 'readme-md', "$output_path");
    $docknot->run();
    my $output = slurp($output_path);
    is_file_contents($output, 'README.md', 'Generated README.md from ARGV');
}

# Save the paths to various files in the source directory.
my $readme_path    = File::Spec->catfile(getcwd(), 'README');
my $readme_md_path = File::Spec->catfile(getcwd(), 'README.md');
my $metadata_path  = File::Spec->catfile(getcwd(), 'docs', 'docknot.yaml');

# Generate all of the files using generate-all in a new temporary directory.
my $tmpdir = File::Temp->newdir();
chdir($tmpdir);
$docknot->run('generate-all', '-m', $metadata_path);
my $output = slurp('README');
is_file_contents($output, $readme_path, 'README from generate_all');
$output = slurp('README.md');
is_file_contents($output, $readme_md_path, 'README.md from generate_all');

# Ensure that generate works with a default argument.
$docknot->run('generate', '-m', $metadata_path, 'readme');
$output = slurp('README');
is_file_contents($output, $readme_path, 'README from generate default args');

# Allow cleanup to delete our temporary directory.
chdir(File::Spec->rootdir());
