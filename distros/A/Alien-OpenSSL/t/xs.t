use Test2::V0;
use Test::Alien;
use Alien::OpenSSL;

alien_ok 'Alien::OpenSSL';

my $xs = do { local $/; <DATA> };

xs_ok $xs, with_subtest {
  my($module) = @_;
  my $version = $module->version;
  ok $version;
  note "version = $version";
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <openssl/crypto.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
version(klass)
    const char *klass;
  CODE:
#ifdef SSLEAY_VERSION
    RETVAL = SSLeay_version(SSLEAY_VERSION);
#else
    RETVAL = OpenSSL_version(OPENSSL_VERSION);
#endif
  OUTPUT:
    RETVAL
