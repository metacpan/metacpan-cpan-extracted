#!perl

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/rel2abs/;
use File::Path qw/remove_tree/;
use File::Basename qw/dirname/;
use Archive::Raw;

my $entry;
my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

$reader->open_filename ('test_archive.tar.gz');

my $writer = Archive::Raw::DiskWriter->new
(
	Archive::Raw->EXTRACT_TIME |
	Archive::Raw->EXTRACT_PERM |
	Archive::Raw->EXTRACT_ACL |
	Archive::Raw->EXTRACT_FFLAGS
);
isa_ok $writer, 'Archive::Raw::DiskWriter';

ok (!eval { $writer->write (bless {}, 'SomeObject') });

my $output = 't/testextract/';
remove_tree ($output);

while (my $entry = $reader->next())
{
	my $filename = $output.$entry->pathname;
	$entry->pathname ($filename);

	if (Archive::Raw::libarchive_version > 3002000)
	{
		ok (!$entry->is_encrypted());
		ok (!$entry->is_data_encrypted());
		ok (!$entry->is_metadata_encrypted());
	}

	if ($entry->filetype == Archive::Raw->AE_IFREG)
	{
		ok ($entry->size > 0);
	}
	else
	{
		is $entry->size, 0;
	}

	ok (!-e $filename);
	$writer->write ($entry);

	if ($entry->filetype == Archive::Raw->AE_IFLNK)
	{
		# what the link points to may not be available yet,
		# so just make sure its a link
		ok (-l $filename) if ($^O ne 'MSWin32');
	}
	else
	{
		ok (-e $filename);
	}
}

done_testing;
