use Test2::V0 -no_srand => 1;
use 5.020;
use Test2::API qw( context );
use Path::Tiny qw( path );
use Archive::Libarchive::ArchiveRead;
use Test::Archive::Libarchive;
use experimental qw( signatures );

use lib 't/lib';
use Test2::Tools::MemoryCycle qw( memory_cycle_ok );

subtest 'basic' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  isa_ok $r, 'Archive::Libarchive::ArchiveRead';

  memory_cycle_ok $r;

};

BEGIN {
  require Archive::Libarchive::Lib::Constants;
  foreach my $name (qw( ARCHIVE_OK ARCHIVE_EOF ))
  {
    no strict 'refs';
    *{$name} = \&{"Archive::Libarchive::$name"};
  }
}

subtest 'next_header' => sub {

  require Archive::Libarchive::Entry;

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_format_tar';

  my $e = Archive::Libarchive::Entry->new;
  la_ok $r, 'open_filename', ['examples/archive.tar', 10240];

  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/', '$entry->pathname');
  la_ok $r, 'read_data_skip';

  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/bar.txt', '$entry->pathname (2)');
  la_ok $r, 'read_data_skip';

  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/foo.txt', '$entry->pathname (2)');
  la_ok $r, 'read_data_skip';

  la_eof $r, 'next_header', [$e];

  memory_cycle_ok $r;
  memory_cycle_ok $e, 'no memory cycle for entry';

};

subtest 'open_memory' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_format_tar';
  la_ok $r, 'open_memory', [\path('examples/archive.tar')->slurp_raw];
  la_archive_ok($r);
};

subtest 'open_filename' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_format_tar';
  la_ok $r, 'open_filename', ['examples/archive.tar', 40];
  la_archive_ok($r);
};

subtest 'open_FILE' => sub {

  subtest 'object' => sub {
    skip_all 'test requires FFI::C::File'
      unless eval { require FFI::C::File; 1 };

    my $fp = FFI::C::File->fopen('examples/archive.tar', 'rb');

    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, 'support_format_tar';
    la_ok $r, 'open_FILE', [$fp];
    la_archive_ok($r);
  };

  subtest 'opaque pointer' => sub {

    my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );
    my $fp = $ffi->function( fopen => ['string','string'] => 'opaque' )->call('examples/archive.tar', 'rb');

    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, 'support_format_tar';
    la_ok $r, 'open_FILE', [$fp];
    la_archive_ok($r);
  };


};

subtest 'open_perlfile' => sub {

  open my $fh, '<', 'examples/archive.tar';

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_format_tar';
  la_ok $r, 'open_perlfile', [$fh];
  la_archive_ok($r);
};


subtest 'read_data' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_raw';
  la_ok $r, 'open_filename' => ['examples/hello.txt.uu', 10240];
  la_ok $r, 'next_header' => [Archive::Libarchive::Entry->new];

  my $image;

  while(1)
  {
    my $buffer;
    my $size = $r->read_data(\$buffer);
    if($size > 0)
    {
      $image .= $buffer;
    }
    elsif($size == 0)
    {
      last;
    }
    else
    {
      fail "error!";
    }
  }

  is $image, "Hello World!\n", 'content matches!';

  memory_cycle_ok $r;
};

subtest 'filter' => sub {

  subtest 'string' => sub {
    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, append_filter => ['uu'];
    is( $r->filter_count, 1 );
    is( $r->filter_code(0), 'uu');
    is( $r->filter_code(0), number Archive::Libarchive::ARCHIVE_FILTER_UU() );
    memory_cycle_ok $r;
  };

  subtest 'int' => sub {
    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, append_filter => [Archive::Libarchive::ARCHIVE_FILTER_UU()];
    is( $r->filter_count, 1 );
    is( $r->filter_code(0), 'uu');
    is( $r->filter_code(0), number Archive::Libarchive::ARCHIVE_FILTER_UU() );
    memory_cycle_ok $r;
  };

};

subtest 'format' => sub {

  subtest 'string' => sub {
    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, set_format => ['tar_gnutar'];
    la_ok $r, open_filename => ['examples/archive.tar', 10240];
    la_ok $r, next_header => [Archive::Libarchive::Entry->new];
    is $r->format, 'tar_gnutar';
    is $r->format, number(Archive::Libarchive::ARCHIVE_FORMAT_TAR_GNUTAR());
    memory_cycle_ok $r;
  };

  subtest 'int' => sub {
    my $r = Archive::Libarchive::ArchiveRead->new;
    la_ok $r, set_format => [Archive::Libarchive::ARCHIVE_FORMAT_TAR_GNUTAR()];
    la_ok $r, open_filename => ['examples/archive.tar', 10240];
    la_ok $r, next_header => [Archive::Libarchive::Entry->new];
    is $r->format, 'tar_gnutar';
    is $r->format, number(Archive::Libarchive::ARCHIVE_FORMAT_TAR_GNUTAR());
    memory_cycle_ok $r;
  };

};

# this is really an entry test, but we need to read a mtree file for it.
subtest '$e->digest' => sub {

  skip_all 'test requires digest method'
    unless Archive::Libarchive::Entry->can('digest');

  my $r = Archive::Libarchive::ArchiveRead->new;
  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_all';
  la_ok $r, open_filename => ['corpus/test_read_format_mtree.mtree.uu', 512];

  my $e = Archive::Libarchive::Entry->new;

  for(1..100)
  {
    la_ok $r, next_header => [$e];
    last if $e->pathname eq 'dir2/md5file';
  }

  is($e->pathname, 'dir2/md5file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_MD5()), "\xd4\x1d\x8c\xd9\x8f\x00\xb2\x04\xe9\x80\x09\x98\xec\xf8\x42\x7e");
  is($e->digest('md5'),                                           "\xd4\x1d\x8c\xd9\x8f\x00\xb2\x04\xe9\x80\x09\x98\xec\xf8\x42\x7e");

  la_ok $r, next_header => [$e];
  is($e->pathname, 'dir2/rmd160file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_RMD160()), "\xda\x39\xa3\xee\x5e\x6b\x4b\x0d\x32\x55\xbf\xef\x95\x60\x18\x90"
                                                                   . "\xaf\xd8\x07\x09");
  is($e->digest('rmd160'),                                           "\xda\x39\xa3\xee\x5e\x6b\x4b\x0d\x32\x55\xbf\xef\x95\x60\x18\x90"
                                                                   . "\xaf\xd8\x07\x09");

  la_ok $r, next_header => [$e];
  is($e->pathname, 'dir2/sha1file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_SHA1()), "\xda\x39\xa3\xee\x5e\x6b\x4b\x0d\x32\x55\xbf\xef\x95\x60\x18\x90"
                                                                 . "\xaf\xd8\x07\x09");
  is($e->digest('sha1'),                                           "\xda\x39\xa3\xee\x5e\x6b\x4b\x0d\x32\x55\xbf\xef\x95\x60\x18\x90"
                                                                 . "\xaf\xd8\x07\x09");

  la_ok $r, next_header => [$e];
  is($e->pathname, 'dir2/sha256file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_SHA256()), "\xe3\xb0\xc4\x42\x98\xfc\x1c\x14\x9a\xfb\xf4\xc8\x99\x6f\xb9\x24"
                                                                   . "\x27\xae\x41\xe4\x64\x9b\x93\x4c\xa4\x95\x99\x1b\x78\x52\xb8\x55");
  is($e->digest('sha256'),                                           "\xe3\xb0\xc4\x42\x98\xfc\x1c\x14\x9a\xfb\xf4\xc8\x99\x6f\xb9\x24"
                                                                   . "\x27\xae\x41\xe4\x64\x9b\x93\x4c\xa4\x95\x99\x1b\x78\x52\xb8\x55");

  la_ok $r, next_header => [$e];
  is($e->pathname, 'dir2/sha384file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_SHA384()), "\x38\xb0\x60\xa7\x51\xac\x96\x38\x4c\xd9\x32\x7e\xb1\xb1\xe3\x6a"
                                                                   . "\x21\xfd\xb7\x11\x14\xbe\x07\x43\x4c\x0c\xc7\xbf\x63\xf6\xe1\xda"
                                                                   . "\x27\x4e\xde\xbf\xe7\x6f\x65\xfb\xd5\x1a\xd2\xf1\x48\x98\xb9\x5b");
  is($e->digest('sha384'),                                           "\x38\xb0\x60\xa7\x51\xac\x96\x38\x4c\xd9\x32\x7e\xb1\xb1\xe3\x6a"
                                                                   . "\x21\xfd\xb7\x11\x14\xbe\x07\x43\x4c\x0c\xc7\xbf\x63\xf6\xe1\xda"
                                                                   . "\x27\x4e\xde\xbf\xe7\x6f\x65\xfb\xd5\x1a\xd2\xf1\x48\x98\xb9\x5b");

  la_ok $r, next_header => [$e];
  is($e->pathname, 'dir2/sha512file');
  is($e->digest(Archive::Libarchive::ARCHIVE_ENTRY_DIGEST_SHA512()), "\xcf\x83\xe1\x35\x7e\xef\xb8\xbd\xf1\x54\x28\x50\xd6\x6d\x80\x07"
                                                                   . "\xd6\x20\xe4\x05\x0b\x57\x15\xdc\x83\xf4\xa9\x21\xd3\x6c\xe9\xce"
                                                                   . "\x47\xd0\xd1\x3c\x5d\x85\xf2\xb0\xff\x83\x18\xd2\x87\x7e\xec\x2f"
                                                                   . "\x63\xb9\x31\xbd\x47\x41\x7a\x81\xa5\x38\x32\x7a\xf9\x27\xda\x3e");
  is($e->digest('sha512'),                                           "\xcf\x83\xe1\x35\x7e\xef\xb8\xbd\xf1\x54\x28\x50\xd6\x6d\x80\x07"
                                                                   . "\xd6\x20\xe4\x05\x0b\x57\x15\xdc\x83\xf4\xa9\x21\xd3\x6c\xe9\xce"
                                                                   . "\x47\xd0\xd1\x3c\x5d\x85\xf2\xb0\xff\x83\x18\xd2\x87\x7e\xec\x2f"
                                                                   . "\x63\xb9\x31\xbd\x47\x41\x7a\x81\xa5\x38\x32\x7a\xf9\x27\xda\x3e");

  la_warn $r, next_header => [$e];
  note $r->error_string;
  is($e->pathname, 'dir2/md5tooshort');
  is($e->digest('md5'), "\0" x 16);

  la_warn $r, next_header => [$e];
  note $r->error_string;
  is($e->pathname, 'dir2/md5toolong');
  is($e->digest('md5'), "\0" x 16);

  la_warn $r, next_header => [$e];
  note $r->error_string;
  is($e->pathname, 'dir2/md5caphex');
  is($e->digest('md5'), "\0" x 16);

  la_warn $r, next_header => [$e];
  note $r->error_string;
  is($e->pathname, 'dir2/md5nothex');
  is($e->digest('md5'), "\0" x 16);

  la_eof $r, next_header => [$e];
  is($r->file_count, 30);

  memory_cycle_ok $r;
  memory_cycle_ok $e, 'no memory cycle on entry';

  la_ok $r, 'close';

};

subtest 'open_filenames' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  my $e = Archive::Libarchive::Entry->new;

  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_all';
  la_ok $r, open_filenames => [["corpus/test_read_splitted_rar_aa",
                                "corpus/test_read_splitted_rar_ab",
                                "corpus/test_read_splitted_rar_ac",
                                "corpus/test_read_splitted_rar_ad"],
                               512];

  la_ok $r, next_header => [$e];
  is($e->pathname, "test.txt");

  la_ok $r, next_header => [$e];
  is($e->pathname, "testlink");

  la_ok $r, next_header => [$e];
  is($e->pathname, "testdir/test.txt");

  la_ok $r, next_header => [$e];
  is($e->pathname, "testdir");

  la_ok $r, next_header => [$e];
  is($e->pathname, "testemptydir");

  la_eof $r, next_header => [$e];

  memory_cycle_ok $r;
  memory_cycle_ok $e, 'no memory cycle on entry';

};

subtest 'add_passphrase' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;

  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_all';
  la_ok $r, add_passphrase => ['password'];
  la_ok $r, open_filename => ['corpus/archive.zip',512];

  la_archive_ok($r);
};

subtest 'set_passphrase_callback' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;

  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_all';
  la_ok $r, set_passphrase_callback => [sub {
    note 'called passphrase callback';
    return 'password';
  }];
  la_ok $r, open_filename => ['corpus/archive.zip',512];

  la_archive_ok($r);
};

subtest 'read_data_block' => sub {

  my $r = Archive::Libarchive::ArchiveRead->new;
  my $e = Archive::Libarchive::Entry->new;

  la_ok $r, 'support_filter_all';
  la_ok $r, 'support_format_all';
  la_ok $r, open_filename => ['examples/archive.tar',512];

  la_ok $r, 'next_header', [$e];
  la_ok $r, 'next_header', [$e];

  my $total = 0;

  while(1)
  {
    my($buff, $offset);
    my $ret = $r->read_data_block(\$buff, \$offset);
    ok $ret >= 0;
    note "ret    = $ret";
    note "buff   = @{[ $buff // 'undef' ]}";
    note "offset = $offset";
    last if $ret == 1;
    $total += length $buff;
  }

  is $total, 6;

  memory_cycle_ok $r;
  memory_cycle_ok $e, 'no memory cycle in entry';

  la_ok $r, 'close';
};

sub la_archive_ok ($r)
{
  my $context = context ();

  my $e = Archive::Libarchive::Entry->new;
  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/', '$entry->pathname');

  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/bar.txt', '$entry->pathname');
  my $content = la_read_data_ok $r
    or diag $r->error_string;
  is $content, "there\n", 'content matches';

  la_ok $r, 'next_header', [$e];
  is($e->pathname, 'archive/foo.txt', '$entry->pathname');
  $content = la_read_data_ok $r
    or diag $r->error_string;
  is $content, "hello\n", 'content matches';

  memory_cycle_ok $r;
  memory_cycle_ok $e, 'no memory cycle in entry';

  la_ok $r, 'close';

  $context->release;
}

done_testing;
