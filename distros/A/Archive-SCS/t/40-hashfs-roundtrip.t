#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use feature 'defer';
no warnings 'experimental::defer';

use Path::Tiny 0.119;
use Test::More;

my $f1 = Path::Tiny->tempfile('Archive-SCS-test-XXXXXX');
defer { $f1->remove; }

use Archive::SCS;
use TestArchiveSCS;

# Roundtrip: Create new HashFS file of sample1 test data and read it back

create_hashfs1 $f1, sample1;

my $scs = Archive::SCS->new;
$scs->mount($f1);

# Compare HashFS contents with test data

is_deeply [$scs->list_dirs], [qw(
  dir
  dir/subdir
  emptydir
)], 'dirs';

is_deeply [$scs->list_files], [qw(
  dir/subdir/SubDirFile
  empty
  ones
)], 'files';

is_deeply [$scs->list_orphans], ['4063fbd34a25e9f0'], 'orphans';

is $scs->read_entry('ones'), '1' x 100, 'ones';
is $scs->read_entry('empty'), '', 'empty';
like $scs->read_entry('dir/subdir/SubDirFile'), qr/in a subdir/, 'SubDirFile';
like $scs->read_entry('orphan'), qr/whats my name/, 'orphan';
like $scs->read_entry('4063fbd34a25e9f0'), qr/whats my name/, 'hash';

done_testing;
