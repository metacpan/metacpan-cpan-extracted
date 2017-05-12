use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );

# this is a translation to perl for this:
#  https://github.com/libarchive/libarchive/wiki/Examples#wiki-Constructing_Objects_On_Disk

my $a = archive_write_disk_new();
archive_write_disk_set_options($a, ARCHIVE_EXTRACT_TIME);

my $entry = archive_entry_new();
archive_entry_set_pathname($entry, "my_file.txt");
archive_entry_set_filetype($entry, AE_IFREG);
archive_entry_set_size($entry, 5);
archive_entry_set_mtime($entry, 123456789, 0);
archive_entry_set_perm($entry, 0644);
archive_write_header($a, $entry);
archive_write_data($a, "abcde");
archive_write_finish_entry($a);
archive_write_free($a);
archive_entry_free($entry);

