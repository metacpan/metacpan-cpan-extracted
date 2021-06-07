use Test2::V0 -no_srand => 1;
use Archive::Libarchive::Unwrap;
use Path::Tiny qw( path );

is(
  dies { Archive::Libarchive::Unwrap->new },
  match qr/^Required option: One of filename or memory at t\/archive_libarchiv/,
  'undef filename',
);

is(
  dies { Archive::Libarchive::Unwrap->new( filename => 'bogus.tar' ) },
  match qr/^Missing or unreadable: bogus.tar at t\/archive_li/,
  'bad filename',
);

is(
  dies { Archive::Libarchive::Unwrap->new( filename => 'corpus/hello.txt.uu', foo => 1, bar => 2 ) },
  match qr/^Illegal options: bar foo/,
  'bad filename',
);

is(
  Archive::Libarchive::Unwrap->new( filename => 'corpus/hello.txt.uu' ),
  object {
    call [ isa => 'Archive::Libarchive::Unwrap' ] => T();
    call unwrap => "Hello World!\n";
  },
  'unwrap from filename',
);

is(
  Archive::Libarchive::Unwrap->new( memory => path('corpus/hello.txt.uu')->slurp_raw ),
  object {
    call [ isa => 'Archive::Libarchive::Unwrap' ] => T();
    call unwrap => "Hello World!\n";
  },
  'unwrap from memory',
);

is(
  Archive::Libarchive::Unwrap->new( memory => \path('corpus/hello.txt.uu')->slurp_raw ),
  object {
    call [ isa => 'Archive::Libarchive::Unwrap' ] => T();
    call unwrap => "Hello World!\n";
  },
  'unwrap from memory reference',
);

done_testing;
