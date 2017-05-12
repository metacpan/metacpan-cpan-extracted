use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );

# this is a translation to perl for this:
#  https://github.com/libarchive/libarchive/wiki/Examples#wiki-A_Complete_Extractor

my $filename = shift @ARGV;

unless(defined $filename)
{
  warn "reading archive from standard in";
}

my $r;

my $flags = ARCHIVE_EXTRACT_TIME
          | ARCHIVE_EXTRACT_PERM
          | ARCHIVE_EXTRACT_ACL
          | ARCHIVE_EXTRACT_FFLAGS;

my $a = archive_read_new();
archive_read_support_filter_all($a);
archive_read_support_format_all($a);
my $ext = archive_write_disk_new();
archive_write_disk_set_options($ext, $flags);
archive_write_disk_set_standard_lookup($ext);

$r = archive_read_open_filename($a, $filename, 10240);
if($r != ARCHIVE_OK)
{
  die "error opening $filename: ", archive_error_string($a);
}

while(1)
{
  $r = archive_read_next_header($a, my $entry);
  if($r == ARCHIVE_EOF)
  {
    last;
  }
  if($r != ARCHIVE_OK)
  {
    print archive_error_string($a), "\n";
  }
  if($r < ARCHIVE_WARN)
  {
    exit 1;
  }
  $r = archive_write_header($ext, $entry);
  if($r != ARCHIVE_OK)
  {
    print archive_error_string($ext), "\n";
  }
  elsif(archive_entry_size($entry) > 0)
  {
    copy_data($a, $ext);
  }
}

archive_read_close($a);
archive_read_free($a);
archive_write_close($ext);
archive_write_free($ext);

sub copy_data
{
  my($ar, $aw) = @_;
  my $r;
  while(1)
  {
    $r = archive_read_data_block($ar, my $buff, my $offset);
    if($r == ARCHIVE_EOF)
    {
      return;
    }
    if($r != ARCHIVE_OK)
    {
      die archive_error_string($ar), "\n";
    }
    $r = archive_write_data_block($aw, $buff, $offset);
    if($r != ARCHIVE_OK)
    {
      die archive_error_string($aw), "\n";
    }
  }
}
