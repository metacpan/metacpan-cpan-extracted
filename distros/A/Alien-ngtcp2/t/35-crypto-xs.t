use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use Alien::ngtcp2;

my $crypto = synthetic {
    cflags => Alien::ngtcp2->crypto_cflags,
    libs   => Alien::ngtcp2->crypto_libs,
};

alien_ok $crypto, 'selected ngtcp2 crypto helper';

xs_ok do { local $/; <DATA> }, with_subtest {
    my ($module) = @_;

    ok(
        $module->crypto_helper_linked,
        'compiled and linked against selected ngtcp2 crypto helper',
    );
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ngtcp2/ngtcp2_crypto.h>

int
alien_ngtcp2_crypto_helper_linked(void)
{
    return ngtcp2_crypto_encrypt_cb != NULL;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
crypto_helper_linked(class)
    const char *class
    CODE:
        RETVAL = alien_ngtcp2_crypto_helper_linked();
    OUTPUT:
        RETVAL
