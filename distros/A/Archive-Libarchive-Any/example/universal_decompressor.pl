use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );

# this is a translation to perl for this:
#  https://github.com/libarchive/libarchive/wiki/Examples#a-universal-decompressor

my $r;

my $a = archive_read_new();
archive_read_support_filter_all($a);
archive_read_support_format_raw($a);
$r = archive_read_open_filename($a, "hello.txt.gz.uu", 16384);
if($r != ARCHIVE_OK)
{
  die archive_error_string($a);
}

$r = archive_read_next_header($a, my $ae);
if($r != ARCHIVE_OK)
{
  die archive_error_string($a);
}

while(1)
{
  my $size = archive_read_data($a, my $buff, 1024);
  if($size < 0)
  {
    die archive_error_string($a);
  }
  if($size == 0)
  {
    last;
  }
  print $buff;
}

archive_read_free($a);
