/*
 * Copyright (c) 2015 Jerry Lundström <lundstrom.jerry@gmail.com>
 * Copyright (c) 2015 .SE (The Internet Infrastructure Foundation)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "crypt_pkcs11_struct.h"

#include <stdlib.h>
#include <string.h>

#ifdef TEST_DEVEL_COVER
extern int __test_devel_cover_calloc_always_fail;
#define myNewxz(a,b,c) if (__test_devel_cover_calloc_always_fail) { a = 0; } else { Newxz(a, b, c); }
#define __croak(x) return 0
#else
#define myNewxz Newxz
#define __croak(x) croak(x)
#endif

extern int crypt_pkcs11_xs_SvUOK(SV* sv);

Crypt__PKCS11__CK_PBE_PARAMS* crypt_pkcs11_ck_pbe_params_new(const char* class) {
    Crypt__PKCS11__CK_PBE_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_PBE_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pInitVector = 0;
        myNewxz(object->private.pInitVector, 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!object->private.pInitVector) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
    }
    return object;
}

SV* crypt_pkcs11_ck_pbe_params_toBytes(Crypt__PKCS11__CK_PBE_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_PBE_PARAMS));
}

CK_RV crypt_pkcs11_ck_pbe_params_fromBytes(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    CK_BYTE_PTR p;
    STRLEN l;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);

    if (!SvPOK(sv)
        || !(p = SvPVbyte(sv, l))
        || l != sizeof(CK_PBE_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    /* uncoverable branch 1 */
    if (object->private.pInitVector) {
        Safefree(object->private.pInitVector);
    }
    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }
    if (object->private.pSalt) {
        Safefree(object->private.pSalt);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pInitVector) {
        CK_BYTE_PTR pInitVector = 0;
        myNewxz(pInitVector, 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pInitVector) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pInitVector, pInitVector, 8, CK_BYTE);
        object->private.pInitVector = pInitVector;
    }
    else {
        myNewxz(object->private.pInitVector, 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!object->private.pInitVector) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
    }
    if (object->private.pPassword) {
        CK_CHAR_PTR pPassword = 0;
        myNewxz(pPassword, object->private.ulPasswordLen, CK_CHAR);
        /* uncoverable branch 0 */
        if (!pPassword) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPassword, pPassword, object->private.ulPasswordLen, CK_CHAR);
        object->private.pPassword = pPassword;
    }
    if (object->private.pSalt) {
        CK_BYTE_PTR pSalt = 0;
        myNewxz(pSalt, object->private.ulSaltLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pSalt) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pSalt, pSalt, object->private.ulSaltLen, CK_BYTE);
        object->private.pSalt = pSalt;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_pbe_params_DESTROY(Crypt__PKCS11__CK_PBE_PARAMS* object) {
    if (object) {
        /* uncoverable branch 1 */
        if (object->private.pInitVector) {
            Safefree(object->private.pInitVector);
        }
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
        }
        if (object->private.pSalt) {
            Safefree(object->private.pSalt);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_pbe_params_get_pInitVector(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pInitVector, 8 * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_set_pInitVector(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    char* p;
    STRLEN l;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);

    /* uncoverable branch 0 */
    if (!SvOK(sv)) {
        Zero(object->private.pInitVector, 8, CK_BYTE);
        return CKR_OK;
    }

    if (!SvPOK(sv)) {
        return CKR_ARGUMENTS_BAD;
    }

    if (!(p = SvPVbyte(sv, l))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (l != 8) {
        return CKR_ARGUMENTS_BAD;
    }

    Copy(p, object->private.pInitVector, 8, CK_BYTE);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_get_pPassword(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pPassword, object->private.ulPasswordLen * sizeof(CK_CHAR));
    sv_utf8_upgrade_nomg(sv);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_set_pPassword(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    CK_CHAR_PTR n = 0;
    CK_CHAR_PTR p;
    STRLEN l;
    SV* _sv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);

    /* uncoverable branch 0 */
    if (!SvOK(sv)) {
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
            object->private.pPassword = 0;
            object->private.ulPasswordLen = 0;
        }
        return CKR_OK;
    }

    if (!SvPOK(sv)) {
        return CKR_ARGUMENTS_BAD;
    }

    if (!(_sv = newSVsv(sv))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    sv_2mortal(_sv);

    sv_utf8_downgrade(_sv, 0);
    if (!(p = SvPV(_sv, l))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }

    myNewxz(n, l, CK_CHAR);
    /* uncoverable branch 0 */
    if (!n) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    Copy(p, n, l, CK_CHAR);
    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }
    object->private.pPassword = n;
    object->private.ulPasswordLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_get_pSalt(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pSalt, object->private.ulSaltLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_set_pSalt(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    CK_BYTE_PTR n = 0;
    CK_BYTE_PTR p;
    STRLEN l;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);

    /* uncoverable branch 0 */
    if (!SvOK(sv)) {
        if (object->private.pSalt) {
            Safefree(object->private.pSalt);
            object->private.pSalt = 0;
            object->private.ulSaltLen = 0;
        }
        return CKR_OK;
    }

    if (!SvPOK(sv)
        || !(p = SvPVbyte(sv, l))
        || l < 0)
    {
        return CKR_ARGUMENTS_BAD;
    }

    myNewxz(n, l, CK_BYTE);
    /* uncoverable branch 0 */
    if (!n) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    Copy(p, n, l, CK_BYTE);
    if (object->private.pSalt) {
        Safefree(object->private.pSalt);
    }
    object->private.pSalt = n;
    object->private.ulSaltLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_get_ulIteration(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulIteration);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pbe_params_set_ulIteration(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    if (!crypt_pkcs11_xs_SvUOK(sv)) {
        return CKR_ARGUMENTS_BAD;
    }

    object->private.ulIteration = SvUV(sv);

    return CKR_OK;
}

