#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

#include "ppport.h"

#include "openssl/opensslconf.h"

MODULE = Crypt::OpenSSL::ConfiguredAPI    PACKAGE = Crypt::OpenSSL::ConfiguredAPI

PROTOTYPES: DISABLE

IV get_configured_api()

    CODE:
#ifdef OPENSSL_CONFIGURED_API
        RETVAL = OPENSSL_CONFIGURED_API;
#else
        RETVAL = 0;
#endif
    OUTPUT:

        RETVAL


