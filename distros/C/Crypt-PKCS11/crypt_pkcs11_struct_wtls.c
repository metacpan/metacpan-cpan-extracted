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

Crypt__PKCS11__CK_WTLS_RANDOM_DATA* crypt_pkcs11_ck_wtls_random_data_new(const char* class) {
    Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_RANDOM_DATA);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_wtls_random_data_toBytes(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_WTLS_RANDOM_DATA));
}

CK_RV crypt_pkcs11_ck_wtls_random_data_fromBytes(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv) {
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
        || l != sizeof(CK_WTLS_RANDOM_DATA))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pClientRandom) {
        Safefree(object->private.pClientRandom);
    }
    if (object->private.pServerRandom) {
        Safefree(object->private.pServerRandom);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pClientRandom) {
        CK_BYTE_PTR pClientRandom = 0;
        myNewxz(pClientRandom, object->private.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pClientRandom, pClientRandom, object->private.ulClientRandomLen, CK_BYTE);
        object->private.pClientRandom = pClientRandom;
    }
    if (object->private.pServerRandom) {
        CK_BYTE_PTR pServerRandom = 0;
        myNewxz(pServerRandom, object->private.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pServerRandom, pServerRandom, object->private.ulServerRandomLen, CK_BYTE);
        object->private.pServerRandom = pServerRandom;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_wtls_random_data_DESTROY(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object) {
    if (object) {
        if (object->private.pClientRandom) {
            Safefree(object->private.pClientRandom);
        }
        if (object->private.pServerRandom) {
            Safefree(object->private.pServerRandom);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_wtls_random_data_get_pClientRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pClientRandom, object->private.ulClientRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_random_data_set_pClientRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv) {
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
        if (object->private.pClientRandom) {
            Safefree(object->private.pClientRandom);
            object->private.pClientRandom = 0;
            object->private.ulClientRandomLen = 0;
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
    if (object->private.pClientRandom) {
        Safefree(object->private.pClientRandom);
    }
    object->private.pClientRandom = n;
    object->private.ulClientRandomLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_random_data_get_pServerRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pServerRandom, object->private.ulServerRandomLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_random_data_set_pServerRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv) {
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
        if (object->private.pServerRandom) {
            Safefree(object->private.pServerRandom);
            object->private.pServerRandom = 0;
            object->private.ulServerRandomLen = 0;
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
    if (object->private.pServerRandom) {
        Safefree(object->private.pServerRandom);
    }
    object->private.pServerRandom = n;
    object->private.ulServerRandomLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* crypt_pkcs11_ck_wtls_master_key_derive_params_new(const char* class) {
    Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pVersion = 0;
        myNewxz(object->private.pVersion, 1, CK_BYTE);
        /* uncoverable branch 0 */
        if (!object->private.pVersion) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
    }
    return object;
}

SV* crypt_pkcs11_ck_wtls_master_key_derive_params_toBytes(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_WTLS_MASTER_KEY_DERIVE_PARAMS));
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_fromBytes(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_WTLS_MASTER_KEY_DERIVE_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.RandomInfo.pClientRandom) {
        Safefree(object->private.RandomInfo.pClientRandom);
    }
    if (object->private.RandomInfo.pServerRandom) {
        Safefree(object->private.RandomInfo.pServerRandom);
    }
    /* uncoverable branch 1 */
    if (object->private.pVersion) {
        Safefree(object->private.pVersion);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.RandomInfo.pClientRandom) {
        CK_BYTE_PTR pClientRandom = 0;
        myNewxz(pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.RandomInfo.pClientRandom, pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
        object->private.RandomInfo.pClientRandom = pClientRandom;
    }
    if (object->private.RandomInfo.pServerRandom) {
        CK_BYTE_PTR pServerRandom = 0;
        myNewxz(pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.RandomInfo.pServerRandom, pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
        object->private.RandomInfo.pServerRandom = pServerRandom;
    }
    /* uncoverable branch 1 */
    if (object->private.pVersion) {
        CK_BYTE_PTR pVersion = 0;
        myNewxz(pVersion, 1, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pVersion) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pVersion, pVersion, 1, CK_BYTE);
        object->private.pVersion = pVersion;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_wtls_master_key_derive_params_DESTROY(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object) {
    if (object) {
        if (object->private.RandomInfo.pClientRandom) {
            Safefree(object->private.RandomInfo.pClientRandom);
        }
        if (object->private.RandomInfo.pServerRandom) {
            Safefree(object->private.RandomInfo.pServerRandom);
        }
        /* uncoverable branch 1 */
        if (object->private.pVersion) {
            Safefree(object->private.pVersion);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.DigestMechanism);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
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

    object->private.DigestMechanism = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_get_RandomInfo(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv) {
    CK_BYTE_PTR pClientRandom = NULL_PTR;
    CK_BYTE_PTR pServerRandom = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.RandomInfo.pClientRandom) {
        myNewxz(pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }
    if (object->private.RandomInfo.pServerRandom) {
        myNewxz(pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable begin */
            Safefree(pClientRandom);
            return CKR_HOST_MEMORY;
            /* uncoverable end */
        }
    }

    if (pClientRandom) {
        Copy(object->private.RandomInfo.pClientRandom, pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
    }
    if (pServerRandom) {
        Copy(object->private.RandomInfo.pServerRandom, pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
    }

    if (sv->private.pClientRandom) {
        Safefree(sv->private.pClientRandom);
    }
    if (sv->private.pServerRandom) {
        Safefree(sv->private.pServerRandom);
    }

    sv->private.pClientRandom = pClientRandom;
    sv->private.ulClientRandomLen = object->private.RandomInfo.ulClientRandomLen;
    sv->private.pServerRandom = pServerRandom;
    sv->private.ulServerRandomLen = object->private.RandomInfo.ulServerRandomLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_set_RandomInfo(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv) {
    CK_BYTE_PTR pClientRandom = NULL_PTR;
    CK_BYTE_PTR pServerRandom = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (sv->private.pClientRandom) {
        myNewxz(pClientRandom, sv->private.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }
    if (sv->private.pServerRandom) {
        myNewxz(pServerRandom, sv->private.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable begin */
            Safefree(pClientRandom);
            return CKR_HOST_MEMORY;
            /* uncoverable end */
        }
    }

    if (pClientRandom) {
        Copy(sv->private.pClientRandom, pClientRandom, sv->private.ulClientRandomLen, CK_BYTE);
    }
    if (pServerRandom) {
        Copy(sv->private.pServerRandom, pServerRandom, sv->private.ulServerRandomLen, CK_BYTE);
    }

    if (object->private.RandomInfo.pClientRandom) {
        Safefree(object->private.RandomInfo.pClientRandom);
    }
    if (object->private.RandomInfo.pServerRandom) {
        Safefree(object->private.RandomInfo.pServerRandom);
    }

    object->private.RandomInfo.pClientRandom = pClientRandom;
    object->private.RandomInfo.ulClientRandomLen = sv->private.ulClientRandomLen;
    object->private.RandomInfo.pServerRandom = pServerRandom;
    object->private.RandomInfo.ulServerRandomLen = sv->private.ulServerRandomLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_get_pVersion(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, *(object->private.pVersion));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_set_pVersion(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

Crypt__PKCS11__CK_WTLS_PRF_PARAMS* crypt_pkcs11_ck_wtls_prf_params_new(const char* class) {
    Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_PRF_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_wtls_prf_params_toBytes(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_WTLS_PRF_PARAMS));
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_fromBytes(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_WTLS_PRF_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pSeed) {
        Safefree(object->private.pSeed);
    }
    if (object->private.pLabel) {
        Safefree(object->private.pLabel);
    }
    if (object->private.pOutput) {
        Safefree(object->private.pOutput);
    }
    Copy(p, &(object->private), l, char);

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
    if (object->private.pLabel) {
        CK_BYTE_PTR pLabel = 0;
        myNewxz(pLabel, object->private.ulLabelLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pLabel) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pLabel, pLabel, object->private.ulLabelLen, CK_BYTE);
        object->private.pLabel = pLabel;
    }
    if (object->private.pulOutputLen) {
        object->pulOutputLen = *(object->private.pulOutputLen);
    }
    object->private.pulOutputLen = &(object->pulOutputLen);
    if (object->private.pOutput) {
        CK_BYTE_PTR pOutput = 0;
        myNewxz(pOutput, object->pulOutputLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pOutput) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pOutput, pOutput, object->pulOutputLen, CK_BYTE);
        object->private.pOutput = pOutput;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_wtls_prf_params_DESTROY(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object) {
    if (object) {
        if (object->private.pSeed) {
            Safefree(object->private.pSeed);
        }
        if (object->private.pLabel) {
            Safefree(object->private.pLabel);
        }
        if (object->private.pOutput) {
            Safefree(object->private.pOutput);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.DigestMechanism);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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

    object->private.DigestMechanism = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pSeed(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pSeed(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pLabel(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pLabel, object->private.ulLabelLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pLabel(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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
        if (object->private.pLabel) {
            Safefree(object->private.pLabel);
            object->private.pLabel = 0;
            object->private.ulLabelLen = 0;
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
    if (object->private.pLabel) {
        Safefree(object->private.pLabel);
    }
    object->private.pLabel = n;
    object->private.ulLabelLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pOutput(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    /* uncoverable branch 0 */
    if (!SvOK(sv)) {
        if (!object->pulOutputLen) {
            return CKR_FUNCTION_FAILED;
        }

        /* uncoverable branch 1 */
        if (object->private.pOutput) {
            Safefree(object->private.pOutput);
        }

        object->private.pOutput = 0;
        myNewxz(object->private.pOutput, object->pulOutputLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!object->private.pOutput) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
        return CKR_OK;
    }

    /* uncoverable branch 3 */
    if (object->private.pOutput && object->pulOutputLen) {
        sv_setpvn(sv, object->private.pOutput, object->pulOutputLen * sizeof(CK_BYTE));
    }
    else {
        sv_setsv(sv, &PL_sv_undef);
    }
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pOutput(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv) {
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
        if (object->private.pOutput) {
            Safefree(object->private.pOutput);
            object->private.pOutput = 0;
        }
        object->private.pulOutputLen = &(object->pulOutputLen);
        object->pulOutputLen = 0;
        return CKR_OK;
    }

    if (!crypt_pkcs11_xs_SvUOK(sv)
        || !(l = SvUV(sv)))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pOutput) {
        Safefree(object->private.pOutput);
    }

    object->private.pOutput = 0;
    myNewxz(object->private.pOutput, l, CK_BYTE);
    /* uncoverable branch 0 */
    if (!object->private.pOutput) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }
    object->private.pulOutputLen = &(object->pulOutputLen);
    object->pulOutputLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* crypt_pkcs11_ck_wtls_key_mat_out_new(const char* class) {
    Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
    }
    return object;
}

SV* crypt_pkcs11_ck_wtls_key_mat_out_toBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_WTLS_KEY_MAT_OUT));
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_fromBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

void crypt_pkcs11_ck_wtls_key_mat_out_DESTROY(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object) {
    if (object) {
        if (object->private.pIV) {
            Safefree(object->private.pIV);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_hMacSecret(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hMacSecret);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_hMacSecret(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
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

    object->private.hMacSecret = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_hKey(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_hKey(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_pIV(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pIV, object->ulIV * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_pIV(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* crypt_pkcs11_ck_wtls_key_mat_params_new(const char* class) {
    Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pReturnedKeyMaterial = &(object->pReturnedKeyMaterial);
    }
    return object;
}

SV* crypt_pkcs11_ck_wtls_key_mat_params_toBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_WTLS_KEY_MAT_PARAMS));
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_fromBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

void crypt_pkcs11_ck_wtls_key_mat_params_DESTROY(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object) {
    if (object) {
        if (object->private.RandomInfo.pClientRandom) {
            Safefree(object->private.RandomInfo.pClientRandom);
        }
        if (object->private.RandomInfo.pServerRandom) {
            Safefree(object->private.RandomInfo.pServerRandom);
        }
        if (object->pReturnedKeyMaterial.pIV) {
            Safefree(object->pReturnedKeyMaterial.pIV);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.DigestMechanism);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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

    object->private.DigestMechanism = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulMacSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulMacSizeInBits);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulMacSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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

    object->private.ulMacSizeInBits = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulKeySizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulKeySizeInBits);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulKeySizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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

    object->private.ulKeySizeInBits = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulIVSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulIVSizeInBits);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulIVSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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

    object->private.ulIVSizeInBits = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulSequenceNumber(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulSequenceNumber);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulSequenceNumber(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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

    object->private.ulSequenceNumber = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_bIsExport(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.bIsExport);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_bIsExport(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv) {
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
        object->private.bIsExport = CK_TRUE;
    }
    else {
        object->private.bIsExport = CK_FALSE;
    }

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_RandomInfo(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv) {
    CK_BYTE_PTR pClientRandom = NULL_PTR;
    CK_BYTE_PTR pServerRandom = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.RandomInfo.pClientRandom) {
        myNewxz(pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }
    if (object->private.RandomInfo.pServerRandom) {
        myNewxz(pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable begin */
            Safefree(pClientRandom);
            return CKR_HOST_MEMORY;
            /* uncoverable end */
        }
    }

    if (pClientRandom) {
        Copy(object->private.RandomInfo.pClientRandom, pClientRandom, object->private.RandomInfo.ulClientRandomLen, CK_BYTE);
    }
    if (pServerRandom) {
        Copy(object->private.RandomInfo.pServerRandom, pServerRandom, object->private.RandomInfo.ulServerRandomLen, CK_BYTE);
    }

    if (sv->private.pClientRandom) {
        Safefree(sv->private.pClientRandom);
    }
    if (sv->private.pServerRandom) {
        Safefree(sv->private.pServerRandom);
    }

    sv->private.pClientRandom = pClientRandom;
    sv->private.ulClientRandomLen = object->private.RandomInfo.ulClientRandomLen;
    sv->private.pServerRandom = pServerRandom;
    sv->private.ulServerRandomLen = object->private.RandomInfo.ulServerRandomLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_RandomInfo(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv) {
    CK_BYTE_PTR pClientRandom = NULL_PTR;
    CK_BYTE_PTR pServerRandom = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (sv->private.pClientRandom) {
        myNewxz(pClientRandom, sv->private.ulClientRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pClientRandom) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }
    if (sv->private.pServerRandom) {
        myNewxz(pServerRandom, sv->private.ulServerRandomLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pServerRandom) {
            /* uncoverable begin */
            Safefree(pClientRandom);
            return CKR_HOST_MEMORY;
            /* uncoverable end */
        }
    }

    if (pClientRandom) {
        Copy(sv->private.pClientRandom, pClientRandom, sv->private.ulClientRandomLen, CK_BYTE);
    }
    if (pServerRandom) {
        Copy(sv->private.pServerRandom, pServerRandom, sv->private.ulServerRandomLen, CK_BYTE);
    }

    if (object->private.RandomInfo.pClientRandom) {
        Safefree(object->private.RandomInfo.pClientRandom);
    }
    if (object->private.RandomInfo.pServerRandom) {
        Safefree(object->private.RandomInfo.pServerRandom);
    }

    object->private.RandomInfo.pClientRandom = pClientRandom;
    object->private.RandomInfo.ulClientRandomLen = sv->private.ulClientRandomLen;
    object->private.RandomInfo.pServerRandom = pServerRandom;
    object->private.RandomInfo.ulServerRandomLen = sv->private.ulServerRandomLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_pReturnedKeyMaterial(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* sv) {
    CK_BYTE_PTR pIV = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((object->private.ulIVSizeInBits % 8)) {
        return CKR_GENERAL_ERROR;
    }

    if (object->private.ulIVSizeInBits) {
        myNewxz(pIV, object->private.ulIVSizeInBits / 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pIV) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }

    /* uncoverable branch 2 */
    if (pIV && object->pReturnedKeyMaterial.pIV) {
        /* uncoverable block 0 */
        Copy(object->pReturnedKeyMaterial.pIV, pIV, (object->private.ulIVSizeInBits / 8), CK_BYTE);
    }

    if (sv->private.pIV) {
        Safefree(sv->private.pIV);
    }

    sv->private.hMacSecret = object->pReturnedKeyMaterial.hMacSecret;
    sv->private.hKey = object->pReturnedKeyMaterial.hKey;
    sv->private.pIV = pIV;
    if (pIV) {
        sv->ulIV = (object->private.ulIVSizeInBits / 8) * sizeof(CK_BYTE);
    }
    else {
        sv->ulIV = 0;
    }

    return CKR_OK;
}

