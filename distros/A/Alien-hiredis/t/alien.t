use Test::More;
use Test::Alien;
use Alien::hiredis;

alien_ok 'Alien::hiredis';
ffi_ok { symbols => ['redisReaderCreate','redisReaderFree','redisReaderFeed','redisReaderGetReply'] };
xs_ok <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <hiredis.h>

MODULE = Alien::hiredis::Test  PACKAGE = Alien::hiredis::Test
PROTOTYPES: ENABLE

void
test_redisReader(void)
  PREINIT:
    redisReader *r;
  CODE:
    r = redisReaderCreate();
    redisReaderFree(r);

EOF

done_testing;
