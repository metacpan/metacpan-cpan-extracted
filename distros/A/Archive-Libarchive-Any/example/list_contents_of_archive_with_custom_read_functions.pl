use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );

list_archive(shift @ARGV);

sub list_archive
{
  my $name = shift;
  my %mydata;
  my $a = archive_read_new();
  $mydata{name} = $name;
  open $mydata{fh}, '<', $name;
  archive_read_support_filter_all($a);
  archive_read_support_format_all($a);
  archive_read_open($a, \%mydata, undef, \&myread, \&myclose);
  while(archive_read_next_header($a, my $entry) == ARCHIVE_OK)
  {
    print archive_entry_pathname($entry), "\n";
  }
  archive_read_free($a);
}

sub myread
{
  my($archive, $mydata) = @_;
  my $br = read $mydata->{fh}, my $buffer, 10240;
  return (ARCHIVE_OK, $buffer);
}

sub myclose
{
  my($archive, $mydata) = @_;
  close $mydata->{fh};
  %$mydata = ();
  return ARCHIVE_OK;
}
