use strict;
use warnings;
use Test::More tests => 5;
use Archive::Libarchive::Any qw( :all );
use File::Basename qw( dirname );
use File::Spec;

my $r;
my $a;
my %expected = (
  foo => "hi there\n",
  bar => "this is the content of bar.txt\n",
  baz => "and again.\n",
);

subtest ready => sub {
  plan tests => 3;
  my $filename = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), 'foo.tar'));

  $a = archive_read_new();
  $r = archive_read_support_format_all($a);
  is $r, ARCHIVE_OK, 'archive_read_support_format_all';

  $r = archive_read_support_filter_all($a);
  is $r, ARCHIVE_OK, 'archive_read_support_filter_all';

  $r = archive_read_open_filename($a, $filename, 10240);
  is $r, ARCHIVE_OK, 'archive_read_open_filename';
};

foreach my $name (qw( foo bar baz ))
{
  subtest $name => sub {
    $r = archive_read_next_header($a, my $entry);
    is $r, ARCHIVE_OK, 'archive_read_next_header';
    is archive_entry_pathname($entry), "foo/$name.txt", 'archive_entry_pathname';

    my $data = '';
    open my $fh, '>', \$data;

    $r = eval { archive_read_data_into_fh($a, $fh) };
    diag $@ if $@;
    is $r, ARCHIVE_OK, 'archive_read_data_into_fh';

    is $data, $expected{$name}, 'data matches';
  };
}

subtest cleanup => sub {
  plan tests => 2;

  $r = archive_read_close($a);
  is $r, ARCHIVE_OK, 'archive_read_close';

  $r = archive_read_free($a);
  is $r, ARCHIVE_OK, 'archive_read_free';

};
