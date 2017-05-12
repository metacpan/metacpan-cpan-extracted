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

Crypt__PKCS11__CK_KIP_PARAMS* crypt_pkcs11_ck_kip_params_new(const char* class) {
    Crypt__PKCS11__CK_KIP_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_KIP_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pMechanism = &(object->pMechanism);
    }
    return object;
}

SV* crypt_pkcs11_ck_kip_params_toBytes(Crypt__PKCS11__CK_KIP_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_KIP_PARAMS));
}

CK_RV crypt_pkcs11_ck_kip_params_fromBytes(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_KIP_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->pMechanism.pParameter) {
        Safefree(object->pMechanism.pParameter);
    }
    Zero(&(object->pMechanism), 1, CK_MECHANISM);
    if (object->private.pSeed) {
        Safefree(object->private.pSeed);
    }
    Copy(p, &(object->private), l, char);

    /* uncoverable branch 1 */
    if (object->private.pMechanism) {
        Copy(object->private.pMechanism, &(object->pMechanism), 1, CK_MECHANISM);
        if (object->pMechanism.pParameter) {
            CK_VOID_PTR pParameter = 0;
            myNewxz(pParameter, object->pMechanism.ulParameterLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!pParameter) {
                /* uncoverable block 0 */
                __croak("memory allocation error");
            }
            Copy(object->pMechanism.pParameter, pParameter, object->pMechanism.ulParameterLen, CK_BYTE);
            object->pMechanism.pParameter = pParameter;
        }
    }
    object->private.pMechanism = &(object->pMechanism);

    if (object->private.pSeed) {
        CK_BYTE_PTR pSeed = 0;
        myNewxz(pSeed, object->private.ulSeedLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pSeed) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pSeed, pSeed, object->private.ulSeedLen, CK_BYTE);
        object->private.pSeed = pSeed;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_kip_params_DESTROY(Crypt__PKCS11__CK_KIP_PARAMS* object) {
    if (object) {
        if (object->pMechanism.pParameter) {
            Safefree(object->pMechanism.pParameter);
        }
        if (object->private.pSeed) {
            Safefree(object->private.pSeed);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_kip_params_get_pMechanism(Crypt__PKCS11__CK_KIP_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
    CK_VOID_PTR pParameter = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->pMechanism.ulParameterLen) {
        myNewxz(pParameter, object->pMechanism.ulParameterLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pParameter) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }

    if (pParameter) {
        Copy(object->pMechanism.pParameter, pParameter, object->pMechanism.ulParameterLen, CK_BYTE);
    }

    if (sv->private.pParameter) {
        Safefree(sv->private.pParameter);
    }
    sv->private.mechanism = object->pMechanism.mechanism;
    sv->private.pParameter = pParameter;
    sv->private.ulParameterLen = object->pMechanism.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kip_params_set_pMechanism(Crypt__PKCS11__CK_KIP_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
    CK_VOID_PTR pParameter = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (sv->private.ulParameterLen) {
        myNewxz(pParameter, sv->private.ulParameterLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pParameter) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }

    if (pParameter) {
        Copy(sv->private.pParameter, pParameter, sv->private.ulParameterLen, CK_BYTE);
    }

    if (object->pMechanism.pParameter) {
        Safefree(object->pMechanism.pParameter);
    }
    object->pMechanism.mechanism = sv->private.mechanism;
    object->pMechanism.pParameter = pParameter;
    object->pMechanism.ulParameterLen = sv->private.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kip_params_get_hKey(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hKey);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kip_params_set_hKey(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv) {
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

    object->private.hKey = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kip_params_get_pSeed(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pSeed, object->private.ulSeedLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_kip_params_set_pSeed(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv) {
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
        if (object->private.pSeed) {
            Safefree(object->private.pSeed);
            object->private.pSeed = 0;
            object->private.ulSeedLen = 0;
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
    if (object->private.pSeed) {
        Safefree(object->private.pSeed);
    }
    object->private.pSeed = n;
    object->private.ulSeedLen = l;

    return CKR_OK;
}

