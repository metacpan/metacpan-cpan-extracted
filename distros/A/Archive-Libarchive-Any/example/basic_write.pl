use strict;
use warnings;
use autodie;
use File::stat;
use Archive::Libarchive::Any qw( :all );

# this is a translation to perl for this:
#  https://github.com/libarchive/libarchive/wiki/Examples#wiki-A_Basic_Write_Example

sub write_archive
{
  my($outname, @filenames) = @_;
  
  my $a = archive_write_new();
  
  archive_write_add_filter_gzip($a);
  archive_write_set_format_pax_restricted($a);
  archive_write_open_filename($a, $outname);
  
  foreach my $filename (@filenames)
  {
    my $st = stat $filename;
    my $entry = archive_entry_new();
    archive_entry_set_pathname($entry, $filename);
    archive_entry_set_size($entry, $st->size);
    archive_entry_set_filetype($entry, AE_IFREG);
    archive_entry_set_perm($entry, 0644);
    archive_write_header($a, $entry);
    open my $fh, '<', $filename;
    my $len = read $fh, my $buff, 8192;
    while($len > 0)
    {
      archive_write_data($a, $buff);
      $len = read $fh, $buff, 8192;
    }
    close $fh;
    
    archive_entry_free($entry);
  }
  archive_write_close($a);
  archive_write_free($a);
}

unless(@ARGV > 0)
{
  print "usage: perl basic_write.pl archive.tar.gz file1 [ file2 [ ... ] ]\n";
  exit 2;
}

unless(@ARGV > 1)
{
  print "Cowardly refusing to create an empty archive\n";
  exit 2;
}

write_archive(@ARGV);
