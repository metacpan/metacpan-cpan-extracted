#!/usr/bin/perl
#
# Tests for the App::DocKnot command dispatch for generate.
#
# Copyright 2018-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Cwd qw(getcwd);
use Path::Tiny qw(path);
use Test::RRA qw(is_file_contents);

use Test::More tests => 7;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the module.
BEGIN { use_ok('App::DocKnot::Command') }

# Create the command-line parser.
my $docknot = App::DocKnot::Command->new();
isa_ok($docknot, 'App::DocKnot::Command');

# Generate the package README file to a temporary file, read it into memory,
# and compare it to the actual README file.  This duplicates part of the
# generate/self.t test, but via the command-line parser.  Do this in a
# separate block so that $tempfile goes out of scope and will be cleaned up.
{
    my $tempfile = Path::Tiny->tempfile();
    $docknot->run('generate', 'readme', "$tempfile");
    my $output = $tempfile->slurp_utf8();
    is_file_contents($output, 'README', 'Generated README from argument list');
}

# Do the same thing again, but using arguments from @ARGV.
{
    my $tempfile = Path::Tiny->tempfile();
    local @ARGV = ('generate', 'readme-md', "$tempfile");
    $docknot->run();
    my $output = $tempfile->slurp_utf8();
    is_file_contents($output, 'README.md', 'Generated README.md from ARGV');
}

# Save the paths to various files in the source directory.
my $readme_path = path('README')->realpath();
my $readme_md_path = path('README.md')->realpath();
my $metadata_path = path('docs', 'docknot.yaml')->realpath();

# Generate all of the files using generate-all in a new temporary directory.
my $cwd = getcwd();
my $tempdir = Path::Tiny->tempdir();
chdir($tempdir);
$docknot->run('generate-all', '-m', "$metadata_path");
my $output = path('README')->slurp_utf8();
is_file_contents($output, $readme_path, 'README from generate_all');
$output = path('README.md')->slurp_utf8();
is_file_contents($output, $readme_md_path, 'README.md from generate_all');

# Ensure that generate works with a default argument.
$docknot->run('generate', '-m', "$metadata_path", 'readme');
$output = path('README')->slurp_utf8();
is_file_contents($output, $readme_path, 'README from generate default args');

# Allow cleanup to delete our temporary directory.
chdir($cwd);
