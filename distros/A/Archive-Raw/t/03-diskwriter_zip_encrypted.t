#!perl

use strict;
use warnings;
use Test::More;
use File::Path qw/remove_tree/;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

if (Archive::Raw::libarchive_version() < 3002000)
{
	diag ("Not supported");
	done_testing();
	exit;
}

$reader->add_passphrase ('test');
$reader->open_filename ('test_archive_encrypted.zip');

my $writer = Archive::Raw::DiskWriter->new
(
	Archive::Raw->EXTRACT_TIME |
	Archive::Raw->EXTRACT_PERM |
	Archive::Raw->EXTRACT_ACL |
	Archive::Raw->EXTRACT_FFLAGS
);
isa_ok $writer, 'Archive::Raw::DiskWriter';

my $output = 't/testextract_zip_encrypted/';
remove_tree ($output);

while (my $entry = $reader->next())
{
	is $reader->has_encrypted_entries, 1;

	my $filename = $output.$entry->pathname;
	$entry->pathname ($filename);
	ok ($entry->ctime_is_set);

	if ($entry->filetype == Archive::Raw->AE_IFREG)
	{
		ok ($entry->is_encrypted());
		ok ($entry->is_data_encrypted());
		ok (!$entry->is_metadata_encrypted());
	}

	ok (!-e $filename);
	$writer->write ($entry);
	ok (-e $filename);
}

$reader->close();
$writer->close();

done_testing;

