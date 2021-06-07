use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );

# this is a translation to perl for this:
#  https://github.com/libarchive/libarchive/wiki/Examples#wiki-List_contents_of_Archive_stored_in_File

my $a = archive_read_new();
archive_read_support_filter_all($a);
archive_read_support_format_all($a);

my $r = archive_read_open_filename($a, "archive.tar", 10240);
if($r != ARCHIVE_OK)
{
  die "error opening archive.tar: ", archive_error_string($a);
}

while (archive_read_next_header($a, my $entry) == ARCHIVE_OK)
{
  print archive_entry_pathname($entry), "\n";
  archive_read_data_skip($a);
}

$r = archive_read_free($a);
if($r != ARCHIVE_OK)
{
  die "error freeing archive";
}

