/*
 * $Id: GOST.xs,v 1.00 2001/05/13 14:11:35 ams Exp $
 * Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "gost.h"

typedef struct gost * Crypt__GOST;

MODULE = Crypt::GOST     PACKAGE = Crypt::GOST    PREFIX = gost_
PROTOTYPES: DISABLE

Crypt::GOST
gost_setup(key)
    char *  key    = NO_INIT
    STRLEN  keylen = NO_INIT
    CODE:
    {
        key = SvPV(ST(0), keylen);
        if (keylen != 32)
            croak("key must be 32 bytes long");

        RETVAL = gost_setup((unsigned char *)key);
    }
    OUTPUT:
        RETVAL

void
gost_DESTROY(self)
    Crypt::GOST self
    CODE:
        gost_free(self);

void
gost_crypt(self, input, output, decrypt)
    Crypt::GOST self
    char *  input  = NO_INIT
    SV *    output
    int     decrypt
    STRLEN  inlen  = NO_INIT
    STRLEN  outlen = NO_INIT
    CODE:
    {
        input = SvPV(ST(1), inlen);
        if (inlen != 8)
            croak("input must be 8 bytes long");

        if (output == &PL_sv_undef)
            output = sv_newmortal();
        outlen = 8;

        if (SvREADONLY(output) || !SvUPGRADE(output, SVt_PV))
            croak("cannot use output as lvalue");

        gost_crypt(self,
                   (unsigned char *)input,
                   (unsigned char *)SvGROW(output, outlen),
                   decrypt);

        SvCUR_set(output, outlen);
        *SvEND(output) = '\0';
        SvPOK_only(output);
        SvTAINT(output);
        ST(0) = output;
    }
