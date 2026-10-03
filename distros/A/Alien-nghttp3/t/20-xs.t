use strict;
use warnings;

use Test2::V0;
use Test::Alien;
use Alien::nghttp3;

alien_ok 'Alien::nghttp3';

xs_ok do { local $/; <DATA> }, with_subtest {
    my ($module) = @_;

    like(
        $module->nghttp3_version,
        qr/^\d+\.\d+(?:\.\d+)?/,
        'compiled and linked against libnghttp3',
    );
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <nghttp3/nghttp3.h>

const char *
alien_nghttp3_version(void)
{
    const nghttp3_info *info = nghttp3_version(0);

    if (info == NULL) {
        return "";
    }

    return info->version_str;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
nghttp3_version(class)
    const char *class
    CODE:
        RETVAL = alien_nghttp3_version();
    OUTPUT:
        RETVAL
