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

Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* crypt_pkcs11_ck_pkcs5_pbkd2_params_new(const char* class) {
    Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_pkcs5_pbkd2_params_toBytes(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_PKCS5_PBKD2_PARAMS));
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_fromBytes(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_PKCS5_PBKD2_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pSaltSourceData) {
        Safefree(object->private.pSaltSourceData);
    }
    if (object->private.pPrfData) {
        Safefree(object->private.pPrfData);
    }
    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pSaltSourceData) {
        CK_BYTE_PTR pSaltSourceData = 0;
        myNewxz(pSaltSourceData, object->private.ulSaltSourceDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pSaltSourceData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pSaltSourceData, pSaltSourceData, object->private.ulSaltSourceDataLen, CK_BYTE);
        object->private.pSaltSourceData = pSaltSourceData;
    }
    if (object->private.pPrfData) {
        CK_BYTE_PTR pPrfData = 0;
        myNewxz(pPrfData, object->private.ulPrfDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pPrfData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPrfData, pPrfData, object->private.ulPrfDataLen, CK_BYTE);
        object->private.pPrfData = pPrfData;
    }
    if (object->private.ulPasswordLen) {
        object->ulPasswordLen = *(object->private.ulPasswordLen);
    }
    object->private.ulPasswordLen = &(object->ulPasswordLen);
    if (object->private.pPassword) {
        CK_CHAR_PTR pPassword = 0;
        myNewxz(pPassword, object->ulPasswordLen, CK_CHAR);
        /* uncoverable branch 0 */
        if (!pPassword) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPassword, pPassword, object->ulPasswordLen, CK_CHAR);
        object->private.pPassword = pPassword;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_pkcs5_pbkd2_params_DESTROY(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object) {
    if (object) {
        if (object->private.pSaltSourceData) {
            Safefree(object->private.pSaltSourceData);
        }
        if (object->private.pPrfData) {
            Safefree(object->private.pPrfData);
        }
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_saltSource(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.saltSource);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_saltSource(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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

    object->private.saltSource = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pSaltSourceData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pSaltSourceData, object->private.ulSaltSourceDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pSaltSourceData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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
        if (object->private.pSaltSourceData) {
            Safefree(object->private.pSaltSourceData);
            object->private.pSaltSourceData = 0;
            object->private.ulSaltSourceDataLen = 0;
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
    if (object->private.pSaltSourceData) {
        Safefree(object->private.pSaltSourceData);
    }
    object->private.pSaltSourceData = n;
    object->private.ulSaltSourceDataLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_iterations(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.iterations);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_iterations(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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

    object->private.iterations = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_prf(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.prf);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_prf(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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

    object->private.prf = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPrfData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pPrfData, object->private.ulPrfDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPrfData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
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
        if (object->private.pPrfData) {
            Safefree(object->private.pPrfData);
            object->private.pPrfData = 0;
            object->private.ulPrfDataLen = 0;
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
    if (object->private.pPrfData) {
        Safefree(object->private.pPrfData);
    }
    object->private.pPrfData = n;
    object->private.ulPrfDataLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPassword(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    /* uncoverable branch 0 */
    if (!SvOK(sv)) {
        if (!object->ulPasswordLen) {
            return CKR_FUNCTION_FAILED;
        }

        /* uncoverable branch 1 */
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
        }

        object->private.pPassword = 0;
        myNewxz(object->private.pPassword, object->ulPasswordLen, CK_CHAR);
        /* uncoverable branch 0 */
        if (!object->private.pPassword) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
        return CKR_OK;
    }

    /* uncoverable branch 3 */
    if (object->private.pPassword && object->ulPasswordLen) {
        sv_setpvn(sv, object->private.pPassword, object->ulPasswordLen * sizeof(CK_CHAR));
        sv_utf8_upgrade(sv);
    }
    else {
        sv_setsv(sv, &PL_sv_undef);
    }
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPassword(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv) {
    UV l;

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
        }
        object->private.ulPasswordLen = &(object->ulPasswordLen);
        object->ulPasswordLen = 0;
        return CKR_OK;
    }

    if (!crypt_pkcs11_xs_SvUOK(sv)
        || !(l = SvUV(sv)))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }

    object->private.pPassword = 0;
    myNewxz(object->private.pPassword, l, CK_CHAR);
    /* uncoverable branch 0 */
    if (!object->private.pPassword) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }
    object->private.ulPasswordLen = &(object->ulPasswordLen);
    object->ulPasswordLen = l;

    return CKR_OK;
}

