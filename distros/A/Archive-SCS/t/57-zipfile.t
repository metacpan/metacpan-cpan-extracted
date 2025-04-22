#!perl
use lib 'lib', 't/lib';
use blib;

use Test2::V0 -target => 'Archive::SCS::Zip';

use Archive::SCS;
use Archive::SCS::CityHash 'cityhash64';
use Archive::SCS::InMemory;
use TestArchiveSCS;

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');

# Create new ZIP file of sample1 test data

sub create_zipfile :prototype($$;$) {
  my ($file, $mount, $file_opts) = @_;
  my $scs = Archive::SCS->new;
  $scs->mount($mount);
  Archive::SCS::Zip::create_file($file, $scs, $file_opts // {});
  $scs->unmount($mount);
}

my $sample1 = $tempdir->child('sample1');
create_zipfile $sample1, sample1;

# handles_path()

is CLASS->handles_path( $sample1, "PK\x03\x04" ), T(), 'handles_path: zipfile';
{ my $todo = todo 'handles_path currently only accepts the typical value as magic';
is CLASS->handles_path( $sample1, "PK\x05\x06" ), T(), 'handles_path: empty magic';
is CLASS->handles_path( $sample1, "MZ" x 4 ), T(), 'handles_path: no magic';
}

is CLASS->handles_path( $tempdir, '' ), F(), 'handles_path: dir';
is CLASS->handles_path( $tempdir->child('empty')->touchpath, '' ), F(), 'handles_path: empty file';

# Mount, dir tree

my $mount = CLASS->new( path => $tempdir->child('sample1') );
is $mount->is_mounted, F(), 'no auto mount';
is $mount->mount, $mount, 'mount() yields self';
is $mount->is_mounted, T(), 'mount() mounts';
is $mount->path, $tempdir->child('sample1')->stringify, 'path';

$mount->read_dir_tree;

is [ my @the_dirs = sort $mount->list_dirs ], [qw(
  dir
  dir/subdir
  emptydir
)], 'dirs';

is [ my @the_files = sort $mount->list_files ], [qw(
  dir/subdir/SubDirFile
  empty
  ones
)], 'files';

$mount->read_dir_tree('');
is [ sort $mount->list_dirs ], [ @the_dirs ], 'read dir tree twice';

# Read entries

is $mount->read_entry(cityhash64 'ones'), '1' x 100, 'read entry ones';
is $mount->read_entry(cityhash64 'dir/subdir/SubDirFile'),
  'I am in a subdirectory', 'read entry SubDirFile';
isa_ok $mount->read_entry(cityhash64 'dir'), 'Archive::SCS::DirIndex';

like dies {
  $mount->read_entry(cityhash64 'nope');
}, qr/no entry for hash value/, 'non-existent entry unreadable';

# Entry meta

like $mount->entry_meta(cityhash64 'empty'), { is_dir => FDNE() }, 'meta empty';
like $mount->entry_meta(cityhash64 'emptydir'), { is_dir => T() }, 'meta emptydir';
like $mount->entry_meta(cityhash64 'dir/subdir'), { is_dir => T() }, 'meta subdir';

# Unmount

like dies { $mount->mount }, qr/Already mounted/, 'no double mount';

$mount->unmount;
is $mount->is_mounted, F(), 'unmount() unmounts';

# Create: abuse / unimplemented

like dies {
  Archive::SCS::Zip::create_file($tempdir->child('mtb.zip'), Archive::SCS::InMemory->new);
}, qr/Archive::SCS instance required/, 'create from mountable';
like dies {
  create_zipfile $tempdir->child('empty.zip'), Archive::SCS::InMemory->new;
}, qr/Creating empty ZIP files unimplemented/, 'create empty archive';

# Archive::SCS integration

my $scs = Archive::SCS->new;
$scs->mount("$sample1");

is [$scs->list_dirs], \@the_dirs, 'via SCS: dirs';
is [$scs->list_files], \@the_files, 'via SCS: files';
is $scs->read_entry('ones'), '1' x 100, 'via SCS: read entry ones';
isa_ok $scs->read_entry(''), 'Archive::SCS::DirIndex';

$scs->unmount("$sample1");

done_testing;
