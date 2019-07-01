#!/usr/bin/perl
#
# Basic tests for App::DocKnot::Dist.
#
# Copyright 2019 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Test::RRA qw(use_prereq);

use Capture::Tiny qw(capture_stdout);
use Cwd qw(getcwd);
use File::Copy::Recursive qw(dircopy);
use File::Spec;
use File::Temp;
use IPC::Run qw(run);
use IPC::System::Simple qw(systemx);

use Test::More;

# Find the full path to the test data.
my $cwd      = getcwd() or die "$0: cannot get working directory: $!\n";
my $dataroot = File::Spec->catfile($cwd, 't', 'data', 'dist');

# Set up a temporary directory.
my $dir       = File::Temp->newdir();
my $sourcedir = File::Spec->catfile($dir, 'source');
my $distdir   = File::Spec->catfile($dir, 'dist');

# Check whether git is available and can be used to initialize a repository.
eval { systemx('git', 'init', '-q', File::Spec->catfile($dir, 'source')) };
if ($@) {
    plan skip_all => 'git init failed (possibly no git binary)';
}

# Copy all files from the data directory, and commit them.  We have to rename
# the test while we copy it to avoid having it picked up by the main package
# test suite.
dircopy($dataroot, $sourcedir)
  or die "$0: cannot copy $dataroot to $sourcedir: $!\n";
my $testpath = File::Spec->catfile($sourcedir, 't', 'api', 'empty.t');
rename($testpath . '.in', $testpath);
chdir($sourcedir);
systemx(qw(git add -A .));
systemx(qw(git commit -q -m Initial));

# Check whether we have all the necessary tools to run the test.
my $out;
if (!run(['git', 'archive', 'HEAD'], q{|}, ['tar', 'tf', q{-}], \$out)) {
    chdir($cwd);
    plan skip_all => 'git and tar not available';
} else {
    plan tests => 3;
}

# Load the module.  Change back to the starting directory for this so that
# coverage analysis works.
chdir($cwd);
require_ok('App::DocKnot::Dist');

# Setup finished.  Now we can create a distribution tarball.  Be careful to
# change working directories before letting $dir go out of scope so that
# cleanup works properly.
mkdir($distdir);
chdir($sourcedir);
eval {
    my $dist = App::DocKnot::Dist->new({ distdir => $distdir });
    capture_stdout { $dist->make_distribution() };
};
ok(-f File::Spec->catfile($distdir, 'Empty-1.00.tar.gz'), 'dist exists');
chdir($cwd);
is($@, q{}, 'no errors');
