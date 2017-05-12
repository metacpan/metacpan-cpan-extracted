/*
 * Copyright (C) 2017 by Tomasz Konojacki
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.24.0 or,
 * at your option, any later version of Perl 5 you may have available.
 *
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Bytes::Random::XS      PACKAGE = Bytes::Random::XS        

PROTOTYPES: DISABLE

SV *
random_bytes(count)
    IV count

    CODE:
        IV i = 0;
        char *str;

        count = count > 0 ? count : 0; 

        RETVAL = newSV(count ? count : 1);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, count);

        str = SvPVX(RETVAL);

        if (count) {
            if (!PL_srand_called) {
                seedDrand01((Rand_seed_t)seed());
                PL_srand_called = TRUE;
            }

            for (; count > i; ++i)
                str[i] = (char)(256 * Drand01());
        }

        /* no point in doing that, but it doesn't hurt */
        str[i] = 0;

    OUTPUT:
        RETVAL
