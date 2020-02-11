use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::LibreSSL;

alien_ok 'Alien::LibreSSL';

my $xs = do { local $/; <DATA> };

xs_ok $xs, with_subtest {
  my($module) = @_;
  my $version = $module->version;
  ok $version;
  note "version = $version";
};

done_testing

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
#ifdef OPENSSL_VERSION
    RETVAL = OpenSSL_version(OPENSSL_VERSION);
#else
    RETVAL = SSLeay_version(SSLEAY_VERSION);
#endif
  OUTPUT:
    RETVAL
