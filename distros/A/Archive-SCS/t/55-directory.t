#!perl
use lib 'lib';
use blib;

use Test2::V0 -target => 'Archive::SCS::Directory';

use Archive::SCS;
use Archive::SCS::CityHash 'cityhash64';
use Feature::Compat::Defer;
use List::Util 1.33 'any';
use Path::Tiny 0.125;

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

$tempdir->child('dir/.DS_Store')->touchpath;
$tempdir->child('dir/foo/sub/.DS_Store')->touchpath;
$tempdir->child('dir/foo/sub/baz')->touchpath->spew_raw('baz');
$tempdir->child('dir/bar')->touchpath->spew_raw('bar');
$tempdir->child('dir/empty')->mkdir;
$tempdir->child('dir/.git/index')->touchpath;
$tempdir->child('file')->touchpath;
$tempdir->child('emptydir')->mkdir;
my $symlinks = eval {
  symlink $tempdir->child('dir'), $tempdir->child('dirlink') and
  symlink $tempdir->child('file'), $tempdir->child('filelink') and
  symlink $tempdir->child('dir/foo'), $tempdir->child('dir/foolink') and
  symlink $tempdir->child('dir/bar'), $tempdir->child('dir/barlink')
};

# handles_path()

is CLASS->handles_path( $tempdir->child('dir'),  '' ), T(), 'handles dir';
is CLASS->handles_path( $tempdir->child('file'), '' ), F(), 'does not handle file';

SKIP: {
  $symlinks or skip "symlinks: $^O", 2;
  is CLASS->handles_path( $tempdir->child('dirlink'),  '' ), T(), 'handles dir symlink';
  is CLASS->handles_path( $tempdir->child('filelink'), '' ), F(), 'does not handle file symlink';
}

# Mount, dir tree, @skip

my $mount = CLASS->new( path => $tempdir->child('dir') );
is $mount->is_mounted, F(), 'no auto mount';
is $mount->mount, $mount, 'mount() yields self';
is $mount->is_mounted, T(), 'mount() mounts';
is $mount->path, $tempdir->child('dir')->stringify, 'dir path';

$mount->read_dir_tree;
my $the_dirs  = ['', qw( empty foo foo/sub foolink foolink/sub )];
my $the_files = [qw( bar barlink foo/sub/baz foolink/sub/baz )];
$symlinks or ($the_dirs, $the_files) = map {[ grep !/link/, @$_ ]} ($the_dirs, $the_files);

is [sort $mount->list_dirs], $the_dirs, 'dirs (no .git)';
is [sort $mount->list_files], $the_files, 'files (no .DS_Store)';

# Read entries

is $mount->read_entry(cityhash64 'bar'), 'bar', 'read entry bar';
is $mount->read_entry(cityhash64 'foo/sub/baz'), 'baz', 'read entry baz';
isa_ok $mount->read_entry(cityhash64 'foo'), 'Archive::SCS::DirIndex';

SKIP: {
  $symlinks or skip "symlinks: $^O", 3;
  is $mount->read_entry(cityhash64 'barlink'), 'bar', 'read entry bar link';
  is $mount->read_entry(cityhash64 'foolink/sub/baz'), 'baz', 'read entry baz link';
  isa_ok $mount->read_entry(cityhash64 'foolink'), 'Archive::SCS::DirIndex';
}

ok dies { $mount->read_entry(cityhash64 '.git/index') }, 'skipped entry unreadable';

# Unmount

ok dies { $mount->mount }, 'no double mount';

$mount->unmount;
is $mount->is_mounted, F(), 'unmount() unmounts';

# ignore()

$mount->ignore(qr/y/);
$mount->ignore(qr/z/);
$mount->ignore(qr/link/);

$mount->mount;
is [sort $mount->list_dirs], ['', qw( foo foo/sub )], 'dirs ignored qr';
is [sort $mount->list_files], [qw( bar )], 'files ignored qr';
$mount->unmount;

$mount = CLASS->new( path => $tempdir->child('dir'), ignore => qr/./ );

$mount->mount;
is [$mount->list_dirs, $mount->list_files], [''], 'ignored everything';
my $index = $mount->read_entry(cityhash64 '');
is [$index->dirs, $index->files], [], 'ignored everything dir index';
$mount->unmount;

# Empty dir

$mount = CLASS->new( path => $tempdir->child('emptydir') );
$mount->mount;
is $mount->is_mounted, T(), 'empty dir mounted';
$mount->read_dir_tree;
is [$mount->list_dirs, $mount->list_files], [''], 'empty dir is empty';
is [$mount->entries], [cityhash64 ''], 'empty dir entries';
isa_ok $mount->read_entry(cityhash64 ''), 'Archive::SCS::DirIndex';
$mount->unmount;
is $mount->is_mounted, F(), 'empty dir unmounted';

# Use symlink as directory

SKIP: {
  $symlinks or skip "symlinks: $^O", 1;
  $mount = CLASS->new( path => $tempdir->child('dirlink') );
  $mount->mount;
  is $mount->read_entry(cityhash64 'foo/sub/baz'), 'baz', 'read entry in dirlink';
  $mount->unmount;
}

# Archive::SCS integration

my $scs = Archive::SCS->new;
$scs->mount( my $dir = $tempdir->child('dir')->stringify );

is ['', $scs->list_dirs], $the_dirs, 'via SCS: dirs';
is [$scs->list_files], $the_files, 'via SCS: files';
is $scs->read_entry('bar'), 'bar', 'via SCS: read entry bar';
isa_ok $scs->read_entry(''), 'Archive::SCS::DirIndex';

$scs->unmount($dir);

done_testing;
