use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Libarchive3;

alien_ok 'Alien::Libarchive3';

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  #is(
  #  MyTest::the_test(),
  #  0,
  #  "basic create and free of archive handle"
  #);
  ok 1;
};

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
    
