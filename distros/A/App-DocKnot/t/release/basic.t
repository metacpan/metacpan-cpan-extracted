#!/usr/bin/perl
#
# Tests for the App::DocKnot::Release module API.
#
# Copyright 2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Git::Repository ();
use Path::Tiny qw(path);

use Test::More tests => 34;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the module.
require_ok('App::DocKnot::Release');

# Construct a working area.
my $tempdir = Path::Tiny->tempdir();
my $archive_path = $tempdir->child('archive');
$archive_path->mkpath();
my $old_path = $archive_path->child('ARCHIVE');
my $dist_path = $tempdir->child('dist');
$dist_path->mkpath();

# Make a release when there are no existing files.
my @extensions = qw(tar.gz tar.gz.asc tar.xz tar.xz.asc);
for my $ext (@extensions) {
    my $path = $dist_path->child('Empty-1.9.' . $ext);
    $path->touch();
    utime(time() - 5, time() - 5, $path)
      or die "Cannot reset timestamps for $path: $!\n";
}
my $metadata = path('t', 'data', 'dist', 'package', 'docs', 'docknot.yaml');
my %options = (
    archivedir => $archive_path,
    distdir => $dist_path,
    metadata => $metadata,
);
my $release = App::DocKnot::Release->new(\%options);
$release->release();

# Check that the files were copied correctly and the symlinks were created.
for my $ext (@extensions) {
    my $file = 'Empty-1.9.' . $ext;
    my $file_path = $archive_path->child('devel', $file);
    ok($file_path->is_file(), "Copied $file");
    is(
        $dist_path->child($file)->stat()->[9],
        $file_path->stat()->[9],
        "Timestamp set on $file",
    );
    my $link = 'Empty.' . $ext;
    is(readlink($archive_path->child('devel', $link)), $file, "Linked $link");
}

# Build a Git repository and a .versions file.
my $spin_path = $tempdir->child('spin');
$spin_path->mkpath();
my $versions_path = $spin_path->child('.versions');
$versions_path->spew_utf8(
    "foo    1.0  2021-12-14 17:31:32  software/foo/index.th\n",
    "empty  1.9  2022-01-01 16:00:00  software/empty/index.th\n",
);
Git::Repository->run('init', { cwd => "$spin_path", quiet => 1 });
my $repo = Git::Repository->new(work_tree => "$spin_path");
$repo->run(config => '--add', 'user.name', 'Test');
$repo->run(config => '--add', 'user.email', 'test@example.com');
$repo->run(add => '-A', q{.});
$repo->run(commit => '-q', '-m', 'Initial commit');

# Construct a configuration file.
my $config_path = $tempdir->child('docknot', 'config.yaml');
$config_path->parent()->mkpath();
my @config = (
    "archivedir: $archive_path",
    "distdir: $dist_path",
    "versions: $versions_path",
);
$config_path->spew_utf8(join("\n", @config), "\n");
local $ENV{XDG_CONFIG_HOME} = "$tempdir";

# Make another release, now relying on the global configuration.  Add some
# other files to distdir to ensure they're ignored.
for my $ext (@extensions) {
    $dist_path->child('Empty-1.10.' . $ext)->touch();
    $dist_path->child('foo-1.0.' . $ext)->touch();
}
$release = App::DocKnot::Release->new({ metadata => $metadata });
$release->release();

# Check that the files were copied correctly, the symlinks were created, and
# the old files were moved.  Check that the old files were copied to the
# archive directory.
for my $ext (@extensions) {
    my $file = 'Empty-1.10.' . $ext;
    ok($archive_path->child('devel', $file)->is_file(), "Copied $file");
    my $old = 'Empty-1.9.' . $ext;
    ok(!$archive_path->child('devel', $old)->is_file(), "Removed $old");
    ok(
        $archive_path->child('ARCHIVE', 'Empty', $old)->is_file(),
        "Archived $old",
    );
    my $link = 'Empty.' . $ext;
    is(readlink($archive_path->child('devel', $link)), $file, "Updated $link");
}

# Check that the version file was updated.
my $versions_line;
(undef, $versions_line) = $versions_path->lines_utf8();
my @versions = split(q{ }, $versions_line);
is($versions[0], 'empty', '.versions line');
is($versions[1], '1.10', '...version updated');
isnt(join(q{ }, @versions[2, 3]), '2022-01-01 16:00:00', '...date updated');
is($versions[4], 'software/empty/index.th', '...dependency unchanged');

# Check that the change was staged.
my $status = $repo->run('status', '-s');
is($status, ' M .versions', '.versions change was staged');
