#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

ok (!eval { $reader->next() });

$reader->open_filename ('test_archive.tar.gz');
is $reader->file_count, 0;

ok (!eval { $reader->open_filename ('test_archive.tar.gz') });

if (Archive::Raw::libarchive_version > 3002000)
{
	is $reader->has_encrypted_entries, Archive::Raw->READ_FORMAT_ENCRYPTION_UNSUPPORTED;
	is $reader->format_capabilities, Archive::Raw->READ_FORMAT_CAPS_NONE;
}

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/';
is $entry->filetype, Archive::Raw->AE_IFDIR;
is $reader->file_count, 1;

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/file2.txt';
is $entry->filetype, Archive::Raw->AE_IFREG;
is $reader->file_count, 2;

$entry = $reader->next();
is $entry->pathname, 'dir/file3.txt';
is $entry->filetype, Archive::Raw->AE_IFLNK;
is $reader->file_count, 3;

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/file1.txt';
is $entry->filetype, Archive::Raw->AE_IFREG;
is $reader->file_count, 4;

is $reader->format_name, 'GNU tar format';
is $reader->format, Archive::Raw->FORMAT_TAR_GNUTAR;

# exhausted
$entry = $reader->next();
ok !$entry;

ok $reader->close;
ok !$reader->close;

done_testing;
