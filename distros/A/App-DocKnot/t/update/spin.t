#!/usr/bin/perl
#
# Tests for the spin part of the App::DocKnot::Update module API.
#
# Copyright 2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use File::Copy::Recursive qw(dircopy);
use Git::Repository ();
use Path::Tiny qw(path);
use Test::DocKnot::Spin qw(is_spin_output_tree);

use Test::More;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the module.
require_ok('App::DocKnot::Update');

# Construct the source tree.  Copy t/data/spin/update/input into a fresh Git
# repository and commit it so that we can test the Git interaction.
my $input = path('t', 'data', 'spin', 'update', 'input');
my $tempdir = Path::Tiny->tempdir();
Git::Repository->run('init', { cwd => "$tempdir", quiet => 1 });
dircopy($input, "$tempdir")
  or die "$0: cannot copy $input to $tempdir: $!\n";
my $repo = Git::Repository->new(work_tree => "$tempdir");
$repo->run(config => '--add', 'user.name', 'Test');
$repo->run(config => '--add', 'user.email', 'test@example.com');
$repo->run(add => '-A', q{.});
$repo->run(commit => '-q', '-m', 'Initial commit');

# Update the tree.
my $update = App::DocKnot::Update->new();
$update->update_spin($tempdir);

# Check the resulting output.
my $expected = path('t', 'data', 'spin', 'update', 'output');
my $count = is_spin_output_tree("$tempdir", "$expected", 'Tree updated');
my @status = sort $repo->run('status', '-s');
my @changes = (
    'A  module.spin',
    'A  readme.spin',
    'A  script.spin',
    'D  module.rpod',
    'D  readme.rpod',
    'D  script.rpod',
);
is_deeply(\@status, \@changes, 'Git operations');

# Report the end of testing.
done_testing($count + 2);
