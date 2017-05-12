use Test2::Bundle::Extended;
use Test::Alien;
use Alien::LZO;

alien_ok 'Alien::LZO';

xs_ok do { local $/; <DATA> }, with_subtest {
  is LZO::test(), 1;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <lzo/lzoconf.h>
#include <lzo/lzo1x.h>

MODULE = LZO PACKAGE = LZO

int
test()
  CODE:
    if(lzo_init() == LZO_E_OK)
      RETVAL = 1;
    else
      RETVAL = 0;
  OUTPUT:
    RETVAL
    
