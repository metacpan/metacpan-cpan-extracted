use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Libarchive3;

alien_ok 'Alien::Libarchive3';

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  is(
    MyTest::the_test(),
    0,
    "basic create and free of archive handle"
  );
};

ffi_ok { symbols => ['archive_read_new','archive_read_free'] }, with_subtest {
  my($ffi) = @_;
  my $ptr = $ffi->function( archive_read_new => [] => 'opaque' )->call;
  ok $ptr, 'archive_read_new returned non-null pointer';
  is($ffi->function( archive_read_free => ['opaque'] => 'int' )->call($ptr), 0, 'archive_read_free returned ARCHIVE_OK');
};

if(Alien::Libarchive3->install_type eq 'share')
{
  run_ok(['bsdtar', '--version'])
    ->success
    ->note;
}

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <archive.h>

MODULE = MyTest PACKAGE = MyTest

int the_test()
  INIT:
    int r;
    struct archive *a;
  CODE:
    a = archive_read_new();
    if(a != NULL)
    {
      r = archive_read_free(a);
      if(r == ARCHIVE_OK)
        RETVAL = 0;
      else
        RETVAL = 2;
    }
    else
    {
      RETVAL = 2;
    }
  OUTPUT:
    RETVAL

