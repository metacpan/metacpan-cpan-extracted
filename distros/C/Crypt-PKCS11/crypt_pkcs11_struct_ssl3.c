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

Crypt__PKCS11__CK_SSL3_RANDOM_DATA* crypt_pkcs11_ck_ssl3_random_data_new(const char* class) {
    Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_RANDOM_DATA);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_ssl3_random_data_toBytes(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SSL3_RANDOM_DATA));
}

CK_RV crypt_pkcs11_ck_ssl3_random_data_fromBytes(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv) {
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
        || l != sizeof(CK_SSL3_RANDOM_DATA))
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

void crypt_pkcs11_ck_ssl3_random_data_DESTROY(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object) {
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

CK_RV crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_random_data_set_pClientRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_random_data_set_pServerRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv) {
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

Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* crypt_pkcs11_ck_ssl3_master_key_derive_params_new(const char* class) {
    Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pVersion = &(object->pVersion);
    }
    return object;
}

SV* crypt_pkcs11_ck_ssl3_master_key_derive_params_toBytes(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SSL3_MASTER_KEY_DERIVE_PARAMS));
}

CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_fromBytes(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_SSL3_MASTER_KEY_DERIVE_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.RandomInfo.pClientRandom) {
        Safefree(object->private.RandomInfo.pClientRandom);
    }
    if (object->private.RandomInfo.pServerRandom) {
        Safefree(object->private.RandomInfo.pServerRandom);
    }
    Zero(object->private.pVersion, 1, CK_VERSION);

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
        Copy(object->private.pVersion, &(object->pVersion), 1, CK_VERSION);
    }
    object->private.pVersion = &(object->pVersion);

    return CKR_OK;
}

void crypt_pkcs11_ck_ssl3_master_key_derive_params_DESTROY(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object) {
    if (object) {
        if (object->private.RandomInfo.pClientRandom) {
            Safefree(object->private.RandomInfo.pClientRandom);
        }
        if (object->private.RandomInfo.pServerRandom) {
            Safefree(object->private.RandomInfo.pServerRandom);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_set_RandomInfo(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_get_pVersion(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_VERSION* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    sv->private.major = object->pVersion.major;
    sv->private.minor = object->pVersion.minor;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_set_pVersion(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_VERSION* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    object->pVersion.major = sv->private.major;
    object->pVersion.minor = sv->private.minor;

    return CKR_OK;
}

Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* crypt_pkcs11_ck_ssl3_key_mat_out_new(const char* class) {
    Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
    }
    return object;
}

SV* crypt_pkcs11_ck_ssl3_key_mat_out_toBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SSL3_KEY_MAT_OUT));
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_fromBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

void crypt_pkcs11_ck_ssl3_key_mat_out_DESTROY(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object) {
    if (object) {
        if (object->private.pIVClient) {
            Safefree(object->private.pIVClient);
        }
        if (object->private.pIVServer) {
            Safefree(object->private.pIVServer);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hClientMacSecret);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
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

    object->private.hClientMacSecret = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hServerMacSecret);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
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

    object->private.hServerMacSecret = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hClientKey);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
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

    object->private.hClientKey = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hServerKey);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
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

    object->private.hServerKey = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pIVClient, object->ulIVClient * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVClient(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pIVServer, object->ulIVServer * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVServer(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* crypt_pkcs11_ck_ssl3_key_mat_params_new(const char* class) {
    Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pReturnedKeyMaterial = &(object->pReturnedKeyMaterial);
    }
    return object;
}

SV* crypt_pkcs11_ck_ssl3_key_mat_params_toBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_SSL3_KEY_MAT_PARAMS));
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_fromBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

void crypt_pkcs11_ck_ssl3_key_mat_params_DESTROY(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object) {
    if (object) {
        if (object->private.RandomInfo.pClientRandom) {
            Safefree(object->private.RandomInfo.pClientRandom);
        }
        if (object->private.RandomInfo.pServerRandom) {
            Safefree(object->private.RandomInfo.pServerRandom);
        }
        if (object->pReturnedKeyMaterial.pIVClient) {
            Safefree(object->pReturnedKeyMaterial.pIVClient);
        }
        if (object->pReturnedKeyMaterial.pIVServer) {
            Safefree(object->pReturnedKeyMaterial.pIVServer);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulMacSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulKeySizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulIVSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_bIsExport(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_RandomInfo(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv) {
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

CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_pReturnedKeyMaterial(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* sv) {
    CK_BYTE_PTR pIVClient = NULL_PTR;
    CK_BYTE_PTR pIVServer = NULL_PTR;

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
        myNewxz(pIVClient, object->private.ulIVSizeInBits / 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pIVClient) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }
    if (object->private.ulIVSizeInBits) {
        myNewxz(pIVServer, object->private.ulIVSizeInBits / 8, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pIVServer) {
            /* uncoverable begin */
            Safefree(pIVClient);
            return CKR_HOST_MEMORY;
            /* uncoverable end */
        }
    }

    /* uncoverable branch 2 */
    if (pIVClient && object->pReturnedKeyMaterial.pIVClient) {
        /* uncoverable block 0 */
        Copy(object->pReturnedKeyMaterial.pIVClient, pIVClient, (object->private.ulIVSizeInBits / 8), CK_BYTE);
    }
    /* uncoverable branch 2 */
    if (pIVServer && object->pReturnedKeyMaterial.pIVServer) {
        /* uncoverable block 0 */
        Copy(object->pReturnedKeyMaterial.pIVServer, pIVServer, (object->private.ulIVSizeInBits / 8), CK_BYTE);
    }

    if (sv->private.pIVClient) {
        Safefree(sv->private.pIVClient);
    }
    if (sv->private.pIVServer) {
        Safefree(sv->private.pIVServer);
    }

    sv->private.hClientMacSecret = object->pReturnedKeyMaterial.hClientMacSecret;
    sv->private.hServerMacSecret = object->pReturnedKeyMaterial.hServerMacSecret;
    sv->private.hClientKey = object->pReturnedKeyMaterial.hClientKey;
    sv->private.hServerKey = object->pReturnedKeyMaterial.hServerKey;
    sv->private.pIVClient = pIVClient;

    if (pIVClient) {
        sv->ulIVClient = (object->private.ulIVSizeInBits / 8) * sizeof(CK_BYTE);
    }
    else {
        sv->ulIVClient = 0;
    }
    sv->private.pIVServer = pIVServer;
    if (pIVServer) {
        sv->ulIVServer = (object->private.ulIVSizeInBits / 8) * sizeof(CK_BYTE);
    }
    else {
        sv->ulIVServer = 0;
    }

    return CKR_OK;
}

