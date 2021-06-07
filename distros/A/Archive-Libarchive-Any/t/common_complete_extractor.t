use strict;
use warnings;
use Test::More tests => 15;
use Archive::Libarchive::Any qw( :all );
use File::Basename qw( dirname );
use File::Spec;
use File::Temp qw( tempdir );

my $filename = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), 'foo.tar'));
note "filename = $filename";
my $dir = tempdir( CLEANUP => 1 );
chdir $dir;
note "dir = $dir";

my $flags = ARCHIVE_EXTRACT_TIME
          | ARCHIVE_EXTRACT_PERM
          | ARCHIVE_EXTRACT_ACL
          | ARCHIVE_EXTRACT_FFLAGS;

my $r;

my $a = archive_read_new();
ok $a, 'archive_read_new';

$r = archive_read_support_format_all($a);
is $r, ARCHIVE_OK, 'archive_read_support_format_all';

$r = archive_read_support_filter_all($a);
is $r, ARCHIVE_OK, 'archive_read_support_filter_all';

my $ext = archive_write_disk_new();
ok $ext, 'archive_write_disk_new';

$r = archive_write_disk_set_options($ext, $flags);
is $r, ARCHIVE_OK, 'archive_write_disk_set_options';

$r = archive_write_disk_set_standard_lookup($ext);
is $r, ARCHIVE_OK, 'archive_write_disk_set_standard_lookup';

$r = archive_read_open_filename($a, $filename, 10240);
is $r, ARCHIVE_OK, 'archive_read_open_filename';

foreach my $name (qw( foo bar baz ))
{
  subtest $name => sub {
    plan tests => 4;
    $r = archive_read_next_header($a, my $entry);
    is $r, ARCHIVE_OK, 'archive_read_next_header';

    is archive_entry_pathname($entry), "foo/$name.txt", 'archive_entry_pathname';

    $r = archive_write_header($ext, $entry);
    is $r, ARCHIVE_OK, 'archive_write_header';

    while(1)
    {
      $r = archive_read_data_block($a, my $buff, my $offset);
      last if $r == ARCHIVE_EOF;
      if($r != ARCHIVE_OK)
      {
        diag archive_error_string($a);
        last;
      }
      $r = archive_write_data_block($ext, $buff, $offset);
      if($r != ARCHIVE_OK)
      {
        diag archive_error_string($ext);
        last;
      }
    }

    is $r, ARCHIVE_EOF, 'archive_read_data_block, archive_write_data_block';
  };
}

$r = archive_read_close($a);
is $r, ARCHIVE_OK, 'archive_read_close';

$r = archive_read_free($a);
is $r, ARCHIVE_OK, 'archive_read_free';

$r = archive_write_close($ext);
is $r, ARCHIVE_OK, 'archive_write_close';

$r = archive_write_free($ext);
is $r, ARCHIVE_OK, 'archive_write_free';

open my $fh, '<', 'foo/bar.txt';
my $data = do { local $/; <$fh> };
close $fh;

like $data, qr{^this is the content of bar\.txt$}, "data = $data";

chdir(File::Spec->rootdir);
