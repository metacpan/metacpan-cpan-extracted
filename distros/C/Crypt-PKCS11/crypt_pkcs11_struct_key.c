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

Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* crypt_pkcs11_ck_key_wrap_set_oaep_params_new(const char* class) {
    Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_key_wrap_set_oaep_params_toBytes(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_KEY_WRAP_SET_OAEP_PARAMS));
}

CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_KEY_WRAP_SET_OAEP_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pX) {
        Safefree(object->private.pX);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pX) {
        CK_BYTE_PTR pX = 0;
        myNewxz(pX, object->private.ulXLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pX) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pX, pX, object->private.ulXLen, CK_BYTE);
        object->private.pX = pX;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_key_wrap_set_oaep_params_DESTROY(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object) {
    if (object) {
        if (object->private.pX) {
            Safefree(object->private.pX);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.bBC);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_set_bBC(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv) {
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

    object->private.bBC = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pX, object->private.ulXLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_set_pX(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv) {
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
        if (object->private.pX) {
            Safefree(object->private.pX);
            object->private.pX = 0;
            object->private.ulXLen = 0;
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
    if (object->private.pX) {
        Safefree(object->private.pX);
    }
    object->private.pX = n;
    object->private.ulXLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* crypt_pkcs11_ck_key_derivation_string_data_new(const char* class) {
    Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_key_derivation_string_data_toBytes(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_KEY_DERIVATION_STRING_DATA));
}

CK_RV crypt_pkcs11_ck_key_derivation_string_data_fromBytes(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv) {
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
        || l != sizeof(CK_KEY_DERIVATION_STRING_DATA))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pData) {
        Safefree(object->private.pData);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pData) {
        CK_BYTE_PTR pData = 0;
        myNewxz(pData, object->private.ulLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pData, pData, object->private.ulLen, CK_BYTE);
        object->private.pData = pData;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_key_derivation_string_data_DESTROY(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object) {
    if (object) {
        if (object->private.pData) {
            Safefree(object->private.pData);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_key_derivation_string_data_get_pData(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pData, object->private.ulLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_key_derivation_string_data_set_pData(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv) {
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
            object->private.ulLen = 0;
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
    object->private.ulLen = l;

    return CKR_OK;
}

