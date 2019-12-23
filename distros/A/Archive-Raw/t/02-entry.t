#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

$reader->open_filename ('test_archive.tar.gz');
$entry = $reader->next();
$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';

is $entry->uname, 'jacquesg';
is $entry->gname, 'staff';
is $entry->uname ('user'), 'user';
is $entry->gname ('group'), 'group';

is $entry->uid, 501;
is $entry->gid, 20;
$entry->uid (0);
$entry->gid (1);
is $entry->uid, 0;
is $entry->gid, 1;

is $entry->mode, Archive::Raw->AE_IFREG|0644;
is $entry->strmode, '-rw-r--r-- ';
$entry->mode (Archive::Raw->AE_IFREG|0600);
is $entry->mode, Archive::Raw->AE_IFREG|0600;

is $entry->filetype, Archive::Raw->AE_IFREG;
$entry->filetype (Archive::Raw->AE_IFDIR);
is $entry->filetype, Archive::Raw->AE_IFDIR;

ok ($entry->size_is_set);
is $entry->size, 9;
$entry->size (100);
is $entry->size, 100;
$entry->size (undef);
ok (!$entry->size_is_set);

ok (!$entry->ctime_is_set);
is $entry->ctime, 0;
$entry->ctime (123);
is $entry->ctime, 123;
ok ($entry->ctime_is_set);
$entry->ctime (undef);
ok (!$entry->ctime_is_set);

ok ($entry->mtime_is_set);
is $entry->mtime, 1575482523;
$entry->mtime (321);
is $entry->mtime, 321;
$entry->mtime (undef);
ok (!$entry->mtime_is_set);

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/file3.txt';
is $entry->symlink, 'file1.txt';
is $entry->symlink_type, Archive::Raw->AE_SYMLINK_TYPE_UNDEFINED;

$entry->symlink_type (Archive::Raw->AE_SYMLINK_TYPE_FILE);
is $entry->symlink_type, Archive::Raw->AE_SYMLINK_TYPE_FILE;

$entry->symlink ('file2.txt');
is $entry->symlink, 'file2.txt';

done_testing;
