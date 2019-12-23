#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

$reader->open_filename ('test_archive.zip');
is $reader->file_count, 0;

if (Archive::Raw::libarchive_version > 3002000)
{
	is $reader->has_encrypted_entries, Archive::Raw->READ_FORMAT_ENCRYPTION_DONT_KNOW;
	is $reader->format_capabilities,
		Archive::Raw->READ_FORMAT_CAPS_ENCRYPT_DATA |
		Archive::Raw->READ_FORMAT_CAPS_ENCRYPT_METADATA;
}

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/';
is $entry->filetype, Archive::Raw->AE_IFDIR;
is $reader->file_count, 1;
is $reader->has_encrypted_entries, 0 if (Archive::Raw::libarchive_version > 3002000);

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/file2.txt';
is $entry->filetype, Archive::Raw->AE_IFREG;
is $reader->file_count, 2;

$entry = $reader->next();
isa_ok $entry, 'Archive::Raw::Entry';
is $entry->pathname, 'dir/file1.txt';
is $entry->filetype, Archive::Raw->AE_IFREG;
is $reader->file_count, 3;

is $reader->format_name, 'ZIP 1.0 (uncompressed)';
is $reader->format, Archive::Raw->FORMAT_ZIP;

# exhausted
$entry = $reader->next();
ok !$entry;


ok $reader->close;
ok !$reader->close;

done_testing;
