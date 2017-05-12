/*-
 * Copyright (c) 2011 cPanel, Inc.
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.10.1 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "md5crypt.h"
#include "des.h"
#include "sha256crypt.h"
#include "sha512crypt.h"


typedef char *(*crypt_function_t)(const char*, const char*);

/* The enum and map are in the same order for easy lookup */
typedef enum { MD5 = 0, APR1, DES, SHA256, SHA512 } crypt_scheme_t;

crypt_function_t crypt_function_map[] = {
    cpx_crypt_md5,
    cpx_crypt_apr1,
    cpx_crypt_des,
    cpx_sha256_crypt,
    cpx_sha512_crypt
};

/* This function performs all cleanup of input and calls the correct C crypt function */
SV* _multi_crypt(crypt_scheme_t scheme, SV *pw, SV *salt) {
    char *cryptpw_cstr = NULL;
    char *pw_cstr = NULL;
    char *salt_cstr = NULL;
    SV* RETVAL = &PL_sv_undef;
    if (SvPOK(pw)) {
        pw_cstr = SvPVX(pw);
    } else {
        pw_cstr = "";
    }
    if (SvPOK(salt)) {
        salt_cstr = SvPVX(salt);
    } else {
        salt_cstr = "";
    }
    cryptpw_cstr = crypt_function_map[scheme]( pw_cstr, salt_cstr );
    if (cryptpw_cstr != NULL) {
        RETVAL = newSVpv(cryptpw_cstr,0);
    }
    return RETVAL;
}

MODULE = Crypt::Passwd::XS PACKAGE = Crypt::Passwd::XS

PROTOTYPES: ENABLE

SV*
unix_md5_crypt(pw,salt)
    SV *pw;
    SV *salt;

    CODE:
        RETVAL = _multi_crypt(MD5, pw, salt);

    OUTPUT:
        RETVAL

SV*
apache_md5_crypt(pw,salt)
    SV *pw;
    SV *salt;

    CODE:
        RETVAL = _multi_crypt(APR1, pw, salt);

    OUTPUT:
        RETVAL

SV*
unix_des_crypt(pw,salt)
    SV *pw;
    SV *salt;

    CODE:
        RETVAL = _multi_crypt(DES, pw, salt);

    OUTPUT:
        RETVAL

SV*
unix_sha256_crypt(pw,salt)
    SV *pw;
    SV *salt; 

    CODE:
        RETVAL = _multi_crypt(SHA256, pw, salt);

    OUTPUT:
        RETVAL

SV*
unix_sha512_crypt(pw,salt)
    SV *pw;
    SV *salt; 

    CODE:
        RETVAL = _multi_crypt(SHA512, pw, salt);

    OUTPUT:
        RETVAL
