use Test2::V0 -no_srand => 1;
use Archive::Libarchive::Extract;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
use Ref::Util qw( is_plain_coderef );
use File::chdir;
use experimental qw( signatures );

is(
  dies { Archive::Libarchive::Extract->new },
  match qr/^Required option: filename at t\/archive_libarchiv/,
  'undef filename',
);

is(
  dies { Archive::Libarchive::Extract->new( filename => 'bogus.tar' ) },
  match qr/^Missing or unreadable: bogus.tar at t\/archive_li/,
  'bad filename',
);

is(
  dies { Archive::Libarchive::Extract->new( filename => 'corpus/archive.tar', foo => 1, bar => 2 ) },
  match qr/^Illegal options: bar foo/,
  'bad filename',
);

subtest 'extract' => sub {

  foreach my $to (undef, tempdir( CLEANUP => 1 ))
  {

    subtest "to => @{[ $to // 'undef' ]}" => sub {

      my $tarball;

      local $CWD = $CWD;

      if(defined $to)
      {
        $tarball = path('corpus/archive.tar');
        note "extracting to non-cwd $to";
        note "archive: $tarball";
      }
      else
      {
        $tarball = path('corpus/archive.tar')->absolute;
        $CWD = tempdir( CLEANUP => 1 );
        note "extracting to cwd $CWD";
        note "archive: $tarball";
      }

      my $extract = Archive::Libarchive::Extract->new( filename => "$tarball" );
      isa_ok $extract, 'Archive::Libarchive::Extract';

      ok(! do { no warnings; -d $extract->to } );

      try_ok { $extract->extract( to => $to ) };

      is(
        path($to // $CWD),
        object {
          call [child => 'archive/foo.txt'] => object {
            call slurp_utf8 => "hello\n";
          };
          call [child => 'archive/bar.txt'] => object {
            call slurp_utf8 => "there\n";
          };
        },
        'files',
      );

      is(
        [$extract->entry_list],
        ['archive/','archive/bar.txt','archive/foo.txt'],
        'entry_list'
      );

      ok(-d $extract->to);

    };

  }

  foreach my $passphrase ('password', sub { 'password' })
  {
    subtest "passphrase @{[ is_plain_coderef($passphrase) ? 'code' : 'string' ]}" => sub {

      my $to = tempdir(CLEANUP => 1);

      my $extract = Archive::Libarchive::Extract->new( filename => 'corpus/archive.zip', passphrase => $passphrase );

      try_ok { $extract->extract( to => $to ) };

      is(
        path($to),
        object {
          call [child => 'archive/foo.txt'] => object {
            call slurp_utf8 => "hello\n";
          };
          call [child => 'archive/bar.txt'] => object {
            call slurp_utf8 => "there\n";
          };
        },
        'files',
      );

    };
  }

  subtest 'entry callback' => sub {

    my $to = tempdir(CLEANUP => 1);

    my $extract = Archive::Libarchive::Extract->new( filename => 'corpus/archive.tar', entry => sub ($e) {
      note $e->pathname;
      return $e->pathname eq 'archive/foo.txt' ? 1 : 0;
    });

    try_ok { $extract->extract( to => $to ) };

    is(
      path($to),
      object {
        call [child => 'archive/foo.txt'] => object {
          call slurp_utf8 => "hello\n";
        };
        call [child => 'archive/bar.txt'] => object {
          call sub { -f $_[0] } => F();
        };
      },
      'files',
    );

    is(
      [$extract->entry_list],
      ['archive/foo.txt'],
      'entry_list'
    );

  };

  subtest 'multi-file RAR archive' => sub {

    my $to = tempdir(CLEANUP => 1);

    my @filenames = qw(
      corpus/test_read_splitted_rar_aa
      corpus/test_read_splitted_rar_ab
      corpus/test_read_splitted_rar_ac
      corpus/test_read_splitted_rar_ad
    );

    my $extract = Archive::Libarchive::Extract->new( filename => \@filenames, entry => sub ($e) {
      note $e->pathname;
      # lets not muck with the thorny subject of symlinks on windows
      return 0 if $^O =~ /^(MSWin32|msys|cygwin)$/
               && $e->filetype !~ /^(reg|dir)$/;
      return 1;
    });

    try_ok { $extract->extract( to => $to ) };

    is(
      path($to),
      object {
        call [child => 'test.txt' ] => object {
          call slurp_utf8 => match qr/^test text docume/;
        };
        call [child => 'testdir/test.txt' ] => object {
          call slurp_utf8 => match qr/^test text docume/;
        };
      },
      'files',
    );


  };

};

done_testing;
