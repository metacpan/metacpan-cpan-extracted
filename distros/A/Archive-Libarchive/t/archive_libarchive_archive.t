use Test2::V0 -no_srand => 1;
use Archive::Libarchive::ArchiveRead;
use Archive::Libarchive::ArchiveWrite;
use Archive::Libarchive::DiskRead;
use Archive::Libarchive::DiskWrite;
use Test::Archive::Libarchive;
use 5.020;

foreach my $class (map { "Archive::Libarchive::$_" } qw( ArchiveRead ArchiveWrite DiskRead DiskWrite ))
{

  subtest $class => sub {

    subtest 'entry method' => sub {

      is(
        $class->new,
        object {
          call [isa => $class] => T();
          call entry => object {
            call [isa => 'Archive::Libarchive::Entry'] => T();
          };
        },
      );
    };

    subtest 'set_error' => sub {

      is(
        $class->new,
        object {
          call_list [ set_error => 2, 'frooble % bits' ] => [];
          call errno => 2;
          call error_string => 'frooble % bits';
        },
      );

    };

  };
}

done_testing;


