#!/usr/bin/perl
#
# Basic tests for App::DocKnot::Dist.
#
# Copyright 2019-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use File::Copy::Recursive qw(dircopy);
use Git::Repository;
use IPC::Run qw(run);
use IPC::System::Simple qw(capturex systemx);
use List::Util qw(first);
use Path::Tiny qw(path);

use Test::More;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Find the full path to the test data.
my $cwd = Path::Tiny->cwd();
my $dataroot = $cwd->child('t', 'data', 'dist', 'package');
my $gpg_path = $cwd->child('t', 'data', 'dist', 'fake-gpg');

# Set up a temporary directory.
my $dir = Path::Tiny->tempdir();
my $sourcedir = $dir->child('source');
my $distdir = $dir->child('dist');

# Create a new repository, copy all files from the data directory, and commit
# them.  We have to rename the test while we copy it to avoid having it picked
# up by the main package test suite.
dircopy($dataroot, $sourcedir)
  or die "$0: cannot copy $dataroot to $sourcedir: $!\n";
my $testpath = $sourcedir->child('t', 'api', 'empty.t');
$testpath->sibling('empty.t.in')->move($testpath);
Git::Repository->run('init', { cwd => "$sourcedir", quiet => 1 });
my $repo = Git::Repository->new(work_tree => "$sourcedir");
$repo->run(config => '--add', 'user.name', 'Test');
$repo->run(config => '--add', 'user.email', 'test@example.com');
$repo->run(add => '-A', q{.});
$repo->run(commit => '-q', '-m', 'Initial commit');

# Check whether we have all the necessary tools to run the test.
my @branches = $repo->run(
    'for-each-ref' => '--format=%(refname:short)', 'refs/heads/',
);
my $head = first { $_ eq 'main' || $_ eq 'master' } @branches;
my $result;
eval {
    my $archive = $repo->command(archive => '--prefix=foo/', $head);
    my $out;
    $result = run([qw(tar tf -)], '<', $archive->stdout, '>', \$out);
    $archive->close();
    $result &&= $archive->exit == 0;
};
if ($@ || !$result) {
    plan skip_all => 'git and tar not available';
} else {
    plan tests => 20;
}

# Load the module now that we're sure we can run tests.
require_ok('App::DocKnot::Dist');

# Put some existing files in the directory that are marked read-only.  These
# should be cleaned up automatically.
$distdir->child('Empty')->mkpath();
$distdir->child('Empty', 'Build.PL')->touch()->chmod(0000);

# Setup finished.  Now we can create a distribution tarball.
chdir($sourcedir);
my $dist = App::DocKnot::Dist->new({ distdir => $distdir, perl => $^X });
capture_stdout {
    eval { $dist->make_distribution() };
};
ok($distdir->child('Empty-1.00.tar.gz')->exists(), 'dist exists');
ok($distdir->child('Empty-1.00.tar.xz')->exists(), 'xz dist exists');
ok(!$distdir->child('Empty-1.00.tar')->exists(), 'tarball missing');
ok(!$distdir->child('Empty-1.00.tar.gz.asc')->exists(), 'no signature');
ok(!$distdir->child('Empty-1.00.tar.xz.asc')->exists(), 'no signature');
is($@, q{}, 'no errors');

# Switch to using a configuration file and enable signing.
$distdir->child('Empty-1.00.tar.gz')->remove();
$distdir->child('Empty-1.00.tar.xz')->remove();
$dir->child('docknot')->mkpath();
$dir->child('docknot', 'config.yaml')->spew_utf8(
    "distdir: $distdir\n",
    "pgp_key: some-pgp-key\n",
);
local $ENV{XDG_CONFIG_HOME} = "$dir";
$dist = App::DocKnot::Dist->new({ gpg => $gpg_path, perl => $^X });

# Create a dummy signature, which should be overwritten.
$distdir->child('Empty-1.00.tar.gz.asc')->spew_utf8("bogus signature\n");

# If we add an ignored file to the source tree, this should not trigger any
# errors.
$sourcedir->child('ignored-file')->spew_utf8("Some data\n");
capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, q{}, 'no errors with ignored file');

# And now there should be signatures.
ok($distdir->child('Empty-1.00.tar.gz')->exists(), 'dist exists');
ok($distdir->child('Empty-1.00.tar.xz')->exists(), 'xz dist exists');
ok($distdir->child('Empty-1.00.tar.gz.asc')->exists(), 'gz signature');
ok($distdir->child('Empty-1.00.tar.xz.asc')->exists(), 'xz signature');
is(
    "some signature\n",
    $distdir->child('Empty-1.00.tar.gz.asc')->slurp_utf8(),
    'fake-gpg was run',
);

# If we add a new file to the source tree and run make_distribution() again,
# it should fail, and the output should contain an error message about an
# unknown file.
$sourcedir->child('some-file')->spew_utf8("Some data\n");
my $stdout = capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, "1 file missing from distribution\n", 'correct error for extra file');
like($stdout, qr{ some-file }xms, 'output mentions the right file');

# Verify that check_dist produces the same output.
my $tarball = $distdir->child('Empty-1.00.tar.gz');
my @missing = $dist->check_dist($sourcedir, $tarball);
is_deeply(['some-file'], \@missing, 'check_dist matches');

# Another missing file should produce different formatting.
$sourcedir->child('another-file')->spew_utf8("Some data\n");
$stdout = capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, "2 files missing from distribution\n", 'correct error for two files');
like($stdout, qr{ some-file }xms, 'output mentions the first file');
like($stdout, qr{ another-file }xms, 'output mentions the other file');
@missing = $dist->check_dist($sourcedir, $tarball);
is_deeply(['another-file', 'some-file'], \@missing, 'check_dist matches');

# Be careful to change working directories before letting $dir go out of scope
# so that cleanup works properly.
chdir($cwd);
