#!/usr/bin/perl
#
# Tests for the App::DocKnot command dispatch for generate.
#
# Copyright 2018 Russ Allbery <rra@cpan.org>
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
BEGIN { use_ok('App::DocKnot') }

# Create the command-line parser.
my $docknot = App::DocKnot->new();
isa_ok($docknot, 'App::DocKnot');

# Generate the package README file to a temporary file, read it into memory,
# and compare it to the actual README file.  This duplicates part of the
# generate/self.t test, but via the command-line parser.
my $tempdir     = File::Temp->newdir();
my $output_path = File::Temp->new(DIR => $tempdir);
$docknot->run('generate', 'readme', $output_path);
my $output = slurp($output_path);
is_file_contents($output, 'README', 'Generated README from argument list');
unlink($output_path);

# Do the same thing again, but using arguments from @ARGV.  Be sure to
# stringify $output_path, or slurp() will try to read from the file descriptor
# instead of the path and just get end of file.
local @ARGV = ('generate', 'readme-md', $output_path);
$docknot->run();
$output = slurp("$output_path");
is_file_contents($output, 'README.md', 'Generated README.md from ARGV');

# Save the paths to various files in the source directory.
my $readme_path    = File::Spec->catfile(getcwd(), 'README');
my $readme_md_path = File::Spec->catfile(getcwd(), 'README.md');
my $metadata_path  = File::Spec->catfile(getcwd(), 'docs', 'metadata');

# Generate all of the files using generate-all in a new temporary directory.
my $tmpdir = File::Temp->newdir();
chdir($tmpdir);
$docknot->run('generate-all', '-m', $metadata_path);
$output = slurp('README');
is_file_contents($output, $readme_path, 'README from generate_all');
$output = slurp('README.md');
is_file_contents($output, $readme_md_path, 'README.md from generate_all');

# Ensure that generate works with a default argument.
$docknot->run('generate', '-m', $metadata_path, 'readme');
$output = slurp('README');
is_file_contents($output, $readme_path, 'README from generate default args');

# Allow cleanup to delete our temporary directory.
chdir(File::Spec->rootdir());
