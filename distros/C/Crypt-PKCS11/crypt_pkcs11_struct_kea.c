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

Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* crypt_pkcs11_ck_kea_derive_params_new(const char* class) {
    Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_KEA_DERIVE_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_kea_derive_params_toBytes(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_KEA_DERIVE_PARAMS));
}

CK_RV crypt_pkcs11_ck_kea_derive_params_fromBytes(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_KEA_DERIVE_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pRandomA) {
        Safefree(object->private.pRandomA);
    }
    if (object->private.pRandomB) {
        Safefree(object->private.pRandomB);
    }
    if (object->private.pPublicData) {
        Safefree(object->private.pPublicData);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pRandomA) {
        CK_BYTE_PTR pRandomA = 0;
        myNewxz(pRandomA, object->private.ulRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pRandomA) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pRandomA, pRandomA, object->private.ulRandomLen, CK_BYTE);
        object->private.pRandomA = pRandomA;
    }
    if (object->private.pRandomB) {
        CK_BYTE_PTR pRandomB = 0;
        myNewxz(pRandomB, object->private.ulRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pRandomB) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pRandomB, pRandomB, object->private.ulRandomLen, CK_BYTE);
        object->private.pRandomB = pRandomB;
    }
    if (object->private.pPublicData) {
        CK_BYTE_PTR pPublicData = 0;
        myNewxz(pPublicData, object->private.ulPublicDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pPublicData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPublicData, pPublicData, object->private.ulPublicDataLen, CK_BYTE);
        object->private.pPublicData = pPublicData;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_kea_derive_params_DESTROY(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object) {
    if (object) {
        if (object->private.pRandomA) {
            Safefree(object->private.pRandomA);
        }
        if (object->private.pRandomB) {
            Safefree(object->private.pRandomB);
        }
        if (object->private.pPublicData) {
            Safefree(object->private.pPublicData);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_kea_derive_params_get_isSender(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.isSender);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_set_isSender(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
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

    if (SvUV(sv)) {
        object->private.isSender = CK_TRUE;
    }
    else {
        object->private.isSender = CK_FALSE;
    }

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_get_pRandomA(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pRandomA, object->private.ulRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_set_pRandomA(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
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
        if (object->private.pRandomA) {
            Safefree(object->private.pRandomA);
            object->private.pRandomA = 0;
            object->private.ulRandomLen = 0;
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
    if (object->private.pRandomA) {
        Safefree(object->private.pRandomA);
    }
    object->private.pRandomA = n;
    object->private.ulRandomLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_get_pRandomB(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pRandomB, object->private.ulRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_set_pRandomB(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
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
        if (object->private.pRandomB) {
            Safefree(object->private.pRandomB);
            object->private.pRandomB = 0;
            object->private.ulRandomLen = 0;
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
    if (object->private.pRandomB) {
        Safefree(object->private.pRandomB);
    }
    object->private.pRandomB = n;
    object->private.ulRandomLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_get_pPublicData(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pPublicData, object->private.ulPublicDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kea_derive_params_set_pPublicData(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv) {
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
        if (object->private.pPublicData) {
            Safefree(object->private.pPublicData);
            object->private.pPublicData = 0;
            object->private.ulPublicDataLen = 0;
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
    if (object->private.pPublicData) {
        Safefree(object->private.pPublicData);
    }
    object->private.pPublicData = n;
    object->private.ulPublicDataLen = l;

    return CKR_OK;
}

