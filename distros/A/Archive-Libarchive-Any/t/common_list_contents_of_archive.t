use strict;
use warnings;
use Archive::Libarchive::Any qw( :all );
use Test::More;
use FindBin ();
use File::Spec;

plan skip_all => 'requires archive_read_open'
  unless Archive::Libarchive::Any->can('archive_read_open');
plan tests => 4 * 6;

my %failures;

foreach my $mode (qw( memory filename callback fh ))
{
  # TODO: add xar back in if we can figure it out.
  foreach my $format (qw( tar tar.gz tar.Z tar.bz2 zip xar ))
  {
    my $testname = "$format $mode";
    my $ok = subtest $testname=> sub {
      plan skip_all => "$format not supported" if $format =~ /(\.gz|\.bz2|xar)$/;
      plan tests => 17;
    
      my $filename = File::Spec->catfile($FindBin::Bin, "foo.$format");
      my $r;
      my $entry;
    
      note "filename = $filename";

      my $a = archive_read_new();

      $r = archive_read_support_filter_all($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_support_filter_all)";

      $r = archive_read_support_format_all($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_support_format_all)";

      if($mode eq 'memory')
      {
        open my $fh, '<', $filename;
        my $buffer = do { local $/; <$fh> };
        close $fh;
        $r = archive_read_open_memory($a, $buffer);
      }
      elsif($mode eq 'callback')
      {
        my %data = ( filename => $filename );
        archive_read_open($a, \%data, \&myopen, \&myread, \&myclose);
      }
      elsif($mode eq 'fh')
      {
        open my $fh, '<', $filename;
        archive_read_open_fh($a, $fh);
      }
      else
      {
        $r = archive_read_open_filename($a, $filename, 10240);
      }
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_open_$mode)";

      $r = archive_read_next_header($a, $entry);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_next_header 1)";

      SKIP: {
        skip 'requires archive_file_count', 1
          unless Archive::Libarchive::Any->can('archive_file_count');
        is archive_file_count($a), 1, "archive_file_count = 1";
      };

      is archive_entry_pathname($entry), "foo/foo.txt", 'archive_entry_pathname($entry) = foo/foo.txt';

      if(Archive::Libarchive::Any->can('archive_filter_count'))
      {
        note 'archive_filter_count     = ' . archive_filter_count($a);
        for(0..(archive_filter_count($a)-1)) {
          note "archive_filter_code($_)  = " . archive_filter_code($a,$_);
          note "archive_filter_name($_)  = " . archive_filter_name($a,$_);
        }
        note "archive_format           = " . archive_format($a);
        note "archive_format_name      = " . archive_format_name($a);
      }

      $r = archive_read_data_skip($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_data_skip 1)";

      $r = archive_read_next_header($a, $entry);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_next_header 2)";

      if(Archive::Libarchive::Any->can('archive_entry_atime_is_set'))
      {
        if(archive_entry_atime_is_set($entry))
        {
          note '+ atime      = ', archive_entry_atime($entry);
          note '+ atime_nsec = ', archive_entry_atime($entry);
        }
        else
        {
          note '+ no atime';
        }
      }

      SKIP: {
        skip 'requires archive_file_count', 1
          unless Archive::Libarchive::Any->can('archive_file_count');
        is archive_file_count($a), 2, "archive_file_count = 2";
      };

      is archive_entry_pathname($entry), "foo/bar.txt", 'archive_entry_pathname($entry) = foo/bar.txt';

      $r = archive_read_data_skip($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_data_skip 2)";

      $r = archive_read_next_header($a, $entry);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_next_header 3)";

      SKIP: {
        skip 'requires archive_file_count', 1
          unless Archive::Libarchive::Any->can('archive_file_count');
        is archive_file_count($a), 3, "archive_file_count = 3";
      };

      is archive_entry_pathname($entry), "foo/baz.txt", 'archive_entry_pathname($entry) = foo/baz.txt';

      $r = archive_read_data_skip($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_data_skip 3)";

      $r = archive_read_next_header($a, $entry);
      is $r, ARCHIVE_EOF, "r = ARCHIVE_EOF (archive_read_next_header 4)";
 
      $r = archive_read_free($a);
      is $r, ARCHIVE_OK, "r = ARCHIVE_OK (archive_read_free)";
    };
    $failures{$testname} = 1 unless $ok;
  }
}

if(%failures)
{
  diag "failure summary:";
  diag "  $_" for keys %failures;
}

sub myopen
{
  my($a, $d) = @_;
  open my $fh, '<', $d->{filename};
  $d->{fh} = $fh;
  note "callback: open ", $d->{filename};
  ARCHIVE_OK;
}

sub myread
{
  my($a, $d) = @_;
  my $br = read $d->{fh}, my $buffer, 100;
  note "callback: read ", $br;
  (ARCHIVE_OK, $buffer);
}

sub myclose
{
  my($a, $d) = @_;
  my $fh = $d->{fh};
  close $fh;
  note "callback: close";
  ARCHIVE_OK;
}
