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

Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* crypt_pkcs11_ck_des_cbc_encrypt_data_params_new(const char* class) {
    Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_des_cbc_encrypt_data_params_toBytes(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_DES_CBC_ENCRYPT_DATA_PARAMS));
}

CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_fromBytes(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_DES_CBC_ENCRYPT_DATA_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pData) {
        Safefree(object->private.pData);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pData) {
        CK_BYTE_PTR pData = 0;
        myNewxz(pData, object->private.length, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pData, pData, object->private.length, CK_BYTE);
        object->private.pData = pData;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_des_cbc_encrypt_data_params_DESTROY(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object) {
    if (object) {
        if (object->private.pData) {
            Safefree(object->private.pData);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_iv(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.iv, 8 * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_iv(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv) {
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
        Zero(object->private.iv, 8, CK_BYTE);
        return CKR_OK;
    }

    if (!SvPOK(sv)) {
        return CKR_ARGUMENTS_BAD;
    }

    if (!(p = SvPVbyte(sv, l))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (l != (8 * sizeof(CK_BYTE))) {
        return CKR_ARGUMENTS_BAD;
    }

    Copy(p, object->private.iv, 8, CK_BYTE);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_pData(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pData, object->private.length * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_pData(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv) {
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
        if (object->private.pData) {
            Safefree(object->private.pData);
            object->private.pData = 0;
            object->private.length = 0;
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
    if (object->private.pData) {
        Safefree(object->private.pData);
    }
    object->private.pData = n;
    object->private.length = l;

    return CKR_OK;
}

