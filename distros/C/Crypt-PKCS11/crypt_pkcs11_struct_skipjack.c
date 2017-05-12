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

Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* crypt_pkcs11_ck_skipjack_private_wrap_params_new(const char* class) {
    Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_skipjack_private_wrap_params_toBytes(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SKIPJACK_PRIVATE_WRAP_PARAMS));
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_fromBytes(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_SKIPJACK_PRIVATE_WRAP_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }
    if (object->private.pPublicData) {
        Safefree(object->private.pPublicData);
    }
    if (object->private.pRandomA) {
        Safefree(object->private.pRandomA);
    }
    if (object->private.pPrimeP) {
        Safefree(object->private.pPrimeP);
    }
    if (object->private.pBaseG) {
        Safefree(object->private.pBaseG);
    }
    if (object->private.pSubprimeQ) {
        Safefree(object->private.pSubprimeQ);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pPassword) {
        CK_BYTE_PTR pPassword = 0;
        myNewxz(pPassword, object->private.ulPasswordLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pPassword) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPassword, pPassword, object->private.ulPasswordLen, CK_BYTE);
        object->private.pPassword = pPassword;
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
    if (object->private.pPrimeP) {
        CK_BYTE_PTR pPrimeP = 0;
        myNewxz(pPrimeP, object->private.ulPAndGLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pPrimeP) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pPrimeP, pPrimeP, object->private.ulPAndGLen, CK_BYTE);
        object->private.pPrimeP = pPrimeP;
    }
    if (object->private.pBaseG) {
        CK_BYTE_PTR pBaseG = 0;
        myNewxz(pBaseG, object->private.ulPAndGLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pBaseG) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pBaseG, pBaseG, object->private.ulPAndGLen, CK_BYTE);
        object->private.pBaseG = pBaseG;
    }
    if (object->private.pSubprimeQ) {
        CK_BYTE_PTR pSubprimeQ = 0;
        myNewxz(pSubprimeQ, object->private.ulQLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pSubprimeQ) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pSubprimeQ, pSubprimeQ, object->private.ulQLen, CK_BYTE);
        object->private.pSubprimeQ = pSubprimeQ;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_skipjack_private_wrap_params_DESTROY(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object) {
    if (object) {
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
        }
        if (object->private.pPublicData) {
            Safefree(object->private.pPublicData);
        }
        if (object->private.pRandomA) {
            Safefree(object->private.pRandomA);
        }
        if (object->private.pPrimeP) {
            Safefree(object->private.pPrimeP);
        }
        if (object->private.pBaseG) {
            Safefree(object->private.pBaseG);
        }
        if (object->private.pSubprimeQ) {
            Safefree(object->private.pSubprimeQ);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pPassword, object->private.ulPasswordLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPassword(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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
        if (object->private.pPassword) {
            Safefree(object->private.pPassword);
            object->private.pPassword = 0;
            object->private.ulPasswordLen = 0;
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
    if (object->private.pPassword) {
        Safefree(object->private.pPassword);
    }
    object->private.pPassword = n;
    object->private.ulPasswordLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPublicData(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pRandomA(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pPrimeP, object->private.ulPAndGLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPrimeP(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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
        if (object->private.pPrimeP) {
            Safefree(object->private.pPrimeP);
            object->private.pPrimeP = 0;
            object->private.ulPAndGLen = 0;
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
    if (object->private.pPrimeP) {
        Safefree(object->private.pPrimeP);
    }
    object->private.pPrimeP = n;
    object->private.ulPAndGLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pBaseG, object->private.ulPAndGLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pBaseG(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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
        if (object->private.pBaseG) {
            Safefree(object->private.pBaseG);
            object->private.pBaseG = 0;
            object->private.ulPAndGLen = 0;
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
    if (object->private.pBaseG) {
        Safefree(object->private.pBaseG);
    }
    object->private.pBaseG = n;
    object->private.ulPAndGLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pSubprimeQ, object->private.ulQLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pSubprimeQ(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv) {
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
        if (object->private.pSubprimeQ) {
            Safefree(object->private.pSubprimeQ);
            object->private.pSubprimeQ = 0;
            object->private.ulQLen = 0;
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
    if (object->private.pSubprimeQ) {
        Safefree(object->private.pSubprimeQ);
    }
    object->private.pSubprimeQ = n;
    object->private.ulQLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* crypt_pkcs11_ck_skipjack_relayx_params_new(const char* class) {
    Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_skipjack_relayx_params_toBytes(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SKIPJACK_RELAYX_PARAMS));
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_fromBytes(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_SKIPJACK_RELAYX_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pOldWrappedX) {
        Safefree(object->private.pOldWrappedX);
    }
    if (object->private.pOldPassword) {
        Safefree(object->private.pOldPassword);
    }
    if (object->private.pOldPublicData) {
        Safefree(object->private.pOldPublicData);
    }
    if (object->private.pOldRandomA) {
        Safefree(object->private.pOldRandomA);
    }
    if (object->private.pNewPassword) {
        Safefree(object->private.pNewPassword);
    }
    if (object->private.pNewPublicData) {
        Safefree(object->private.pNewPublicData);
    }
    if (object->private.pNewRandomA) {
        Safefree(object->private.pNewRandomA);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pOldWrappedX) {
        CK_BYTE_PTR pOldWrappedX = 0;
        myNewxz(pOldWrappedX, object->private.ulOldWrappedXLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pOldWrappedX) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pOldWrappedX, pOldWrappedX, object->private.ulOldWrappedXLen, CK_BYTE);
        object->private.pOldWrappedX = pOldWrappedX;
    }
    if (object->private.pOldPassword) {
        CK_BYTE_PTR pOldPassword = 0;
        myNewxz(pOldPassword, object->private.ulOldPasswordLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pOldPassword) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pOldPassword, pOldPassword, object->private.ulOldPasswordLen, CK_BYTE);
        object->private.pOldPassword = pOldPassword;
    }
    if (object->private.pOldPublicData) {
        CK_BYTE_PTR pOldPublicData = 0;
        myNewxz(pOldPublicData, object->private.ulOldPublicDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pOldPublicData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pOldPublicData, pOldPublicData, object->private.ulOldPublicDataLen, CK_BYTE);
        object->private.pOldPublicData = pOldPublicData;
    }
    if (object->private.pOldRandomA) {
        CK_BYTE_PTR pOldRandomA = 0;
        myNewxz(pOldRandomA, object->private.ulOldRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pOldRandomA) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pOldRandomA, pOldRandomA, object->private.ulOldRandomLen, CK_BYTE);
        object->private.pOldRandomA = pOldRandomA;
    }
    if (object->private.pNewPassword) {
        CK_BYTE_PTR pNewPassword = 0;
        myNewxz(pNewPassword, object->private.ulNewPasswordLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pNewPassword) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pNewPassword, pNewPassword, object->private.ulNewPasswordLen, CK_BYTE);
        object->private.pNewPassword = pNewPassword;
    }
    if (object->private.pNewPublicData) {
        CK_BYTE_PTR pNewPublicData = 0;
        myNewxz(pNewPublicData, object->private.ulNewPublicDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pNewPublicData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pNewPublicData, pNewPublicData, object->private.ulNewPublicDataLen, CK_BYTE);
        object->private.pNewPublicData = pNewPublicData;
    }
    if (object->private.pNewRandomA) {
        CK_BYTE_PTR pNewRandomA = 0;
        myNewxz(pNewRandomA, object->private.ulNewRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pNewRandomA) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pNewRandomA, pNewRandomA, object->private.ulNewRandomLen, CK_BYTE);
        object->private.pNewRandomA = pNewRandomA;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_skipjack_relayx_params_DESTROY(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object) {
    if (object) {
        if (object->private.pOldWrappedX) {
            Safefree(object->private.pOldWrappedX);
        }
        if (object->private.pOldPassword) {
            Safefree(object->private.pOldPassword);
        }
        if (object->private.pOldPublicData) {
            Safefree(object->private.pOldPublicData);
        }
        if (object->private.pOldRandomA) {
            Safefree(object->private.pOldRandomA);
        }
        if (object->private.pNewPassword) {
            Safefree(object->private.pNewPassword);
        }
        if (object->private.pNewPublicData) {
            Safefree(object->private.pNewPublicData);
        }
        if (object->private.pNewRandomA) {
            Safefree(object->private.pNewRandomA);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pOldWrappedX, object->private.ulOldWrappedXLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldWrappedX(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pOldWrappedX) {
            Safefree(object->private.pOldWrappedX);
            object->private.pOldWrappedX = 0;
            object->private.ulOldWrappedXLen = 0;
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
    if (object->private.pOldWrappedX) {
        Safefree(object->private.pOldWrappedX);
    }
    object->private.pOldWrappedX = n;
    object->private.ulOldWrappedXLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pOldPassword, object->private.ulOldPasswordLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pOldPassword) {
            Safefree(object->private.pOldPassword);
            object->private.pOldPassword = 0;
            object->private.ulOldPasswordLen = 0;
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
    if (object->private.pOldPassword) {
        Safefree(object->private.pOldPassword);
    }
    object->private.pOldPassword = n;
    object->private.ulOldPasswordLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pOldPublicData, object->private.ulOldPublicDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pOldPublicData) {
            Safefree(object->private.pOldPublicData);
            object->private.pOldPublicData = 0;
            object->private.ulOldPublicDataLen = 0;
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
    if (object->private.pOldPublicData) {
        Safefree(object->private.pOldPublicData);
    }
    object->private.pOldPublicData = n;
    object->private.ulOldPublicDataLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pOldRandomA, object->private.ulOldRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pOldRandomA) {
            Safefree(object->private.pOldRandomA);
            object->private.pOldRandomA = 0;
            object->private.ulOldRandomLen = 0;
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
    if (object->private.pOldRandomA) {
        Safefree(object->private.pOldRandomA);
    }
    object->private.pOldRandomA = n;
    object->private.ulOldRandomLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pNewPassword, object->private.ulNewPasswordLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pNewPassword) {
            Safefree(object->private.pNewPassword);
            object->private.pNewPassword = 0;
            object->private.ulNewPasswordLen = 0;
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
    if (object->private.pNewPassword) {
        Safefree(object->private.pNewPassword);
    }
    object->private.pNewPassword = n;
    object->private.ulNewPasswordLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pNewPublicData, object->private.ulNewPublicDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pNewPublicData) {
            Safefree(object->private.pNewPublicData);
            object->private.pNewPublicData = 0;
            object->private.ulNewPublicDataLen = 0;
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
    if (object->private.pNewPublicData) {
        Safefree(object->private.pNewPublicData);
    }
    object->private.pNewPublicData = n;
    object->private.ulNewPublicDataLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pNewRandomA, object->private.ulNewRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv) {
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
        if (object->private.pNewRandomA) {
            Safefree(object->private.pNewRandomA);
            object->private.pNewRandomA = 0;
            object->private.ulNewRandomLen = 0;
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
    if (object->private.pNewRandomA) {
        Safefree(object->private.pNewRandomA);
    }
    object->private.pNewRandomA = n;
    object->private.ulNewRandomLen = l;

    return CKR_OK;
}

