use strict;
use warnings;
use Test::More tests => 9;
use File::Temp qw( tempdir );
use File::Spec;
use Archive::Libarchive::Any qw( :all );

my %data = (
  foo => 'one',
  bar => 'two',
  baz => 'three',
);

my $expected = '';

my $r;
my $dir = tempdir( CLEANUP => 1 );
my $fn  = File::Spec->catfile($dir, "foo.tar.gz");

my $a = eval { archive_write_new() };
ok $a, 'archive_write_new';

$r = eval { archive_write_set_format_pax_restricted($a) };
is $r, ARCHIVE_OK, 'archive_write_set_format_pax_restricted';

my $memory;
$r = eval { archive_write_open_memory($a, \$memory) };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_write_open_memory';

foreach my $name (qw( foo bar baz ))
{
  $expected .= "$name=$data{$name}\n";

  subtest $name => sub {
    plan tests => 8;
  
    my $entry = eval { archive_entry_new() };
    ok $entry, 'archive_entry_new';
  
    $r = archive_entry_set_pathname($entry, $name);
    is $r, ARCHIVE_OK, 'archive_entry_set_pathname';

    $r = archive_entry_set_size($entry, length($data{$name}));
    is $r, ARCHIVE_OK, 'archive_entry_set_size';

    $r = archive_entry_set_filetype($entry, AE_IFREG);
    is $r, ARCHIVE_OK, 'archive_entry_set_filetype';

    $r = archive_entry_set_perm($entry, 0644);
    is $r, ARCHIVE_OK, 'archive_entry_set_perm';

    $r = eval { archive_write_header($a, $entry) };
    is $r, ARCHIVE_OK, 'archive_write_header';

    my $len = eval { archive_write_data($a, $data{$name}) };
    is $len, length($data{$name}), 'archive_write_data';;
  
    $r = archive_entry_free($entry);
    is $r, ARCHIVE_OK, 'archive_entry_free';
  };
}

$r = eval { archive_write_close($a) };
is $r, ARCHIVE_OK, 'archive_write_close';

$r = eval { archive_write_free($a) };
is $r, ARCHIVE_OK, 'archive_write_free';

do {
  my $actual = '';
  my $a = archive_read_new();
  archive_read_support_filter_all($a);
  archive_read_support_format_all($a);
  archive_read_open_memory($a, $memory);
  while(archive_read_next_header($a, my $entry) == ARCHIVE_OK)
  {
    my $name = archive_entry_pathname($entry);
    archive_read_data($a, my $buff, 32);
    $actual .= "$name=$buff\n";
  }

  is $actual, $expected, "output matches";
};

