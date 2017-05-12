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

Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* crypt_pkcs11_ck_rsa_pkcs_oaep_params_new(const char* class) {
    Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_rsa_pkcs_oaep_params_toBytes(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_RSA_PKCS_OAEP_PARAMS));
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_fromBytes(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_RSA_PKCS_OAEP_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pSourceData) {
        Safefree(object->private.pSourceData);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pSourceData) {
        CK_BYTE_PTR pSourceData = 0;
        myNewxz(pSourceData, object->private.ulSourceDataLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pSourceData) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pSourceData, pSourceData, object->private.ulSourceDataLen, CK_BYTE);
        object->private.pSourceData = pSourceData;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_rsa_pkcs_oaep_params_DESTROY(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object) {
    if (object) {
        if (object->private.pSourceData) {
            Safefree(object->private.pSourceData);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hashAlg);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
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

    object->private.hashAlg = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_mgf(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.mgf);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_mgf(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
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

    object->private.mgf = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_source(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.source);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_source(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
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

    object->private.source = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_pSourceData(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pSourceData, object->private.ulSourceDataLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_pSourceData(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv) {
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
        if (object->private.pSourceData) {
            Safefree(object->private.pSourceData);
            object->private.pSourceData = 0;
            object->private.ulSourceDataLen = 0;
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
    if (object->private.pSourceData) {
        Safefree(object->private.pSourceData);
    }
    object->private.pSourceData = n;
    object->private.ulSourceDataLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* crypt_pkcs11_ck_rsa_pkcs_pss_params_new(const char* class) {
    Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_rsa_pkcs_pss_params_toBytes(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_RSA_PKCS_PSS_PARAMS));
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_fromBytes(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_RSA_PKCS_PSS_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    Copy(p, &(object->private), l, char);

    return CKR_OK;
}

void crypt_pkcs11_ck_rsa_pkcs_pss_params_DESTROY(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object) {
    if (object) {
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.hashAlg);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
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

    object->private.hashAlg = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_mgf(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.mgf);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_mgf(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
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

    object->private.mgf = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_sLen(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.sLen);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_sLen(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv) {
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

    object->private.sLen = SvUV(sv);

    return CKR_OK;
}

