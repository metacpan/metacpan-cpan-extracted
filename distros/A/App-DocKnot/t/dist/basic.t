#!/usr/bin/perl
#
# Basic tests for App::DocKnot::Dist.
#
# Copyright 2019-2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Capture::Tiny qw(capture_stdout);
use Cwd qw(getcwd);
use File::Copy::Recursive qw(dircopy);
use File::Spec;
use File::Temp;
use IPC::Run qw(run);
use IPC::System::Simple qw(capturex systemx);

use Test::More;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Find the full path to the test data.
my $cwd      = getcwd() or die "$0: cannot get working directory: $!\n";
my $dataroot = File::Spec->catfile($cwd, 't', 'data', 'dist', 'package');
my $gpg_path = File::Spec->catfile($cwd, 't', 'data', 'dist', 'fake-gpg');

# Set up a temporary directory.
my $dir       = File::Temp->newdir();
my $sourcedir = File::Spec->catfile($dir, 'source');
my $distdir   = File::Spec->catfile($dir, 'dist');

# Check whether git is available and can be used to initialize a repository.
eval {
    systemx(
        'git', 'init', '-b', 'master', '-q',
        File::Spec->catfile($dir, 'source'),
    );
};
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
systemx(qw(git config --add user.name Test));
systemx(qw(git config --add user.email test@example.com));
systemx(qw(git add -A .));
systemx(qw(git commit -q -m Initial));

# Check whether we have all the necessary tools to run the test.
my $out;
my $result
  = eval { run(['git', 'archive', 'HEAD'], q{|}, ['tar', 'tf', q{-}], \$out) };
if ($@ || !$result) {
    chdir($cwd);
    plan skip_all => 'git and tar not available';
} else {
    plan tests => 20;
}

# Load the module.  Change back to the starting directory for this so that
# coverage analysis works.
chdir($cwd);
require_ok('App::DocKnot::Dist');

# Put some existing files in the directory that are marked read-only.  These
# should be cleaned up automatically.
mkdir($distdir);
mkdir(File::Spec->catfile($distdir, 'Empty'));
open(my $fh, '>', File::Spec->catfile($distdir, 'Empty', 'Build.PL'));
close($fh);
chmod(0000, File::Spec->catfile($distdir, 'Empty', 'Build.PL'));

# Setup finished.  Now we can create a distribution tarball.
chdir($sourcedir);
my $dist = App::DocKnot::Dist->new({ distdir => $distdir, perl => $^X });
capture_stdout {
    eval { $dist->make_distribution() };
};
ok(-e File::Spec->catfile($distdir,  'Empty-1.00.tar.gz'), 'dist exists');
ok(-e File::Spec->catfile($distdir,  'Empty-1.00.tar.xz'), 'xz dist exists');
ok(!-e File::Spec->catfile($distdir, 'Empty-1.00.tar'),    'tarball missing');
ok(!-e File::Spec->catfile($distdir, 'Empty-1.00.tar.gz.asc'), 'no signature');
ok(!-e File::Spec->catfile($distdir, 'Empty-1.00.tar.xz.asc'), 'no signature');
is($@, q{}, 'no errors');

# Switch to using a configuration file and enable signing.
unlink(File::Spec->catfile($distdir, 'Empty-1.00.tar.gz'));
unlink(File::Spec->catfile($distdir, 'Empty-1.00.tar.xz'));
mkdir(File::Spec->catfile($dir, 'docknot'));
open($fh, '>', File::Spec->catfile($dir, 'docknot', 'config.yaml'));
print {$fh} "distdir: $distdir\npgp_key: some-pgp-key\n"
  or die "cannot write to config.yaml: $!\n";
close($fh);
local $ENV{XDG_CONFIG_HOME} = $dir;
$dist = App::DocKnot::Dist->new({ gpg => $gpg_path, perl => $^X });

# If we add an ignored file to the source tree, this should not trigger any
# errors.
open($fh, '>', 'ignored-file');
print {$fh} "Some data\n" or die "cannot write to some-file: $!\n";
close($fh);
capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, q{}, 'no errors with ignored file');

# And now there should be signatures.
ok(-e File::Spec->catfile($distdir, 'Empty-1.00.tar.gz'), 'dist exists');
ok(-e File::Spec->catfile($distdir, 'Empty-1.00.tar.xz'), 'xz dist exists');
ok(-e File::Spec->catfile($distdir, 'Empty-1.00.tar.gz.asc'), 'gz signature');
ok(-e File::Spec->catfile($distdir, 'Empty-1.00.tar.xz.asc'), 'xz signature');
open($fh, '<', File::Spec->catfile($distdir, 'Empty-1.00.tar.gz.asc'));
is("some signature\n", <$fh>, 'fake-gpg was run');
close($fh);

# If we add a new file to the source tree and run make_distribution() again,
# it should fail, and the output should contain an error message about an
# unknown file.
open($fh, '>', 'some-file');
print {$fh} "Some data\n" or die "cannot write to some-file: $!\n";
close($fh);
my $stdout = capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, "1 file missing from distribution\n", 'correct error for extra file');
like($stdout, qr{ some-file }xms, 'output mentions the right file');

# Verify that check_dist produces the same output.
my $tarball = File::Spec->catfile($distdir, 'Empty-1.00.tar.gz');
my @missing = $dist->check_dist($sourcedir, $tarball);
is_deeply(['some-file'], \@missing, 'check_dist matches');

# Another missing file should produce different formatting.
open($fh, '>', 'another-file');
print {$fh} "Some data\n" or die "cannot write to some-file: $!\n";
close($fh);
$stdout = capture_stdout {
    eval { $dist->make_distribution() };
};
is($@, "2 files missing from distribution\n", 'correct error for two files');
like($stdout, qr{ some-file }xms,    'output mentions the first file');
like($stdout, qr{ another-file }xms, 'output mentions the other file');
@missing = $dist->check_dist($sourcedir, $tarball);
is_deeply(['another-file', 'some-file'], \@missing, 'check_dist matches');

# Be careful to change working directories before letting $dir go out of scope
# so that cleanup works properly.
chdir($cwd);
