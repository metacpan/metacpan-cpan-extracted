use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use Alien::ngtcp2;

alien_ok 'Alien::ngtcp2';

xs_ok do { local $/; <DATA> }, with_subtest {
    my ($module) = @_;

    like(
        $module->ngtcp2_version,
        qr/^\d+\.\d+(?:\.\d+)?/,
        'compiled and linked against libngtcp2',
    );
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ngtcp2/ngtcp2.h>

const char *
alien_ngtcp2_version(void)
{
    const ngtcp2_info *info = ngtcp2_version(0);

    if (info == NULL) {
        return "";
    }

    return info->version_str;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
ngtcp2_version(class)
    const char *class
    CODE:
        RETVAL = alien_ngtcp2_version();
    OUTPUT:
        RETVAL
