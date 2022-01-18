#!/usr/bin/perl
#
# Test the generate_output method.  This doubles as a test for whether the
# package metadata is consistent with the files currently in the distribution.
#
# Copyright 2016, 2018-2022 Russ Allbery <rra@cpan.org>
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
BEGIN { use_ok('App::DocKnot::Generate') }

# Initialize the App::DocKnot object using the default metadata path.
my $metadata_path = path('docs', 'docknot.yaml')->realpath();
my $docknot = App::DocKnot::Generate->new({ metadata => $metadata_path });
isa_ok($docknot, 'App::DocKnot::Generate');

# Save the paths to the real README and README.md files.
my $readme_path = Path::Tiny->cwd()->child('README');
my $readme_md_path = Path::Tiny->cwd()->child('README.md');

# Write the README output for the DocKnot package to a temporary file.
my $tmp = Path::Tiny->tempfile();
$docknot->generate_output('readme', "$tmp");
my $output = $tmp->slurp();
is_file_contents($output, 'README', 'README in package');
$docknot->generate_output('readme-md', "$tmp");
$output = $tmp->slurp();
is_file_contents($output, 'README.md', 'README.md in package');

# Test default output destinations by creating a temporary directory and then
# generating the README file without an explicit output location.
my $tmpdir = Path::Tiny->tempdir();
my $cwd = getcwd();
chdir($tmpdir);
$docknot->generate_output('readme');
$output = path('README')->slurp();
is_file_contents($output, "$readme_path", 'README using default filename');

# Use generate_all to generate all the metadata with default output paths.
unlink('README');
$docknot->generate_all();
$output = path('README')->slurp();
is_file_contents($output, "$readme_path", 'README from generate_all');
$output = path('README.md')->slurp();
is_file_contents($output, "$readme_md_path", 'README.md from generate_all');

# Allow cleanup to delete our temporary directory.
chdir($cwd);
