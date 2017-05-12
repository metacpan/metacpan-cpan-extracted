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

Crypt__PKCS11__CK_CMS_SIG_PARAMS* crypt_pkcs11_ck_cms_sig_params_new(const char* class) {
    Crypt__PKCS11__CK_CMS_SIG_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_CMS_SIG_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    else {
        object->private.pSigningMechanism = &(object->pSigningMechanism);
        object->private.pDigestMechanism = &(object->pDigestMechanism);
    }
    return object;
}

SV* crypt_pkcs11_ck_cms_sig_params_toBytes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_CMS_SIG_PARAMS));
}

CK_RV crypt_pkcs11_ck_cms_sig_params_fromBytes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_CMS_SIG_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->pSigningMechanism.pParameter) {
        Safefree(object->pSigningMechanism.pParameter);
    }
    Zero(&(object->pSigningMechanism), 1, CK_MECHANISM);
    if (object->pDigestMechanism.pParameter) {
        Safefree(object->pDigestMechanism.pParameter);
    }
    Zero(&(object->pDigestMechanism), 1, CK_MECHANISM);
    if (object->private.pContentType) {
        Safefree(object->private.pContentType);
    }
    if (object->private.pRequestedAttributes) {
        Safefree(object->private.pRequestedAttributes);
    }
    if (object->private.pRequiredAttributes) {
        Safefree(object->private.pRequiredAttributes);
    }
    Copy(p, &(object->private), l, char);

    /* uncoverable branch 1 */
    if (object->private.pSigningMechanism) {
        Copy(object->private.pSigningMechanism, &(object->pSigningMechanism), 1, CK_MECHANISM);
        if (object->pSigningMechanism.pParameter) {
            CK_VOID_PTR pParameter = 0;
            myNewxz(pParameter, object->pSigningMechanism.ulParameterLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!pParameter) {
                /* uncoverable block 0 */
                __croak("memory allocation error");
            }
            Copy(object->pSigningMechanism.pParameter, pParameter, object->pSigningMechanism.ulParameterLen, CK_BYTE);
            object->pSigningMechanism.pParameter = pParameter;
        }
    }
    object->private.pSigningMechanism = &(object->pSigningMechanism);

    /* uncoverable branch 1 */
    if (object->private.pDigestMechanism) {
        Copy(object->private.pDigestMechanism, &(object->pDigestMechanism), 1, CK_MECHANISM);
        if (object->pDigestMechanism.pParameter) {
            CK_VOID_PTR pParameter = 0;
            myNewxz(pParameter, object->pDigestMechanism.ulParameterLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!pParameter) {
                /* uncoverable block 0 */
                __croak("memory allocation error");
            }
            Copy(object->pDigestMechanism.pParameter, pParameter, object->pDigestMechanism.ulParameterLen, CK_BYTE);
            object->pDigestMechanism.pParameter = pParameter;
        }
    }
    object->private.pDigestMechanism = &(object->pDigestMechanism);

    if (object->private.pContentType) {
        CK_CHAR_PTR pContentType = savepv(object->private.pContentType);
        /* uncoverable branch 0 */
        if (!pContentType) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        object->private.pContentType = pContentType;
    }
    if (object->private.pRequestedAttributes) {
        CK_BYTE_PTR pRequestedAttributes = 0;
        myNewxz(pRequestedAttributes, object->private.ulRequestedAttributesLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pRequestedAttributes) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pRequestedAttributes, pRequestedAttributes, object->private.ulRequestedAttributesLen, CK_BYTE);
        object->private.pRequestedAttributes = pRequestedAttributes;
    }
    if (object->private.pRequiredAttributes) {
        CK_BYTE_PTR pRequiredAttributes = 0;
        myNewxz(pRequiredAttributes, object->private.ulRequiredAttributesLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pRequiredAttributes) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pRequiredAttributes, pRequiredAttributes, object->private.ulRequiredAttributesLen, CK_BYTE);
        object->private.pRequiredAttributes = pRequiredAttributes;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_cms_sig_params_DESTROY(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object) {
    if (object) {
        if (object->pSigningMechanism.pParameter) {
            Safefree(object->pSigningMechanism.pParameter);
        }
        if (object->pDigestMechanism.pParameter) {
            Safefree(object->pDigestMechanism.pParameter);
        }
        if (object->private.pContentType) {
            Safefree(object->private.pContentType);
        }
        if (object->private.pRequestedAttributes) {
            Safefree(object->private.pRequestedAttributes);
        }
        if (object->private.pRequiredAttributes) {
            Safefree(object->private.pRequiredAttributes);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_certificateHandle(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.certificateHandle);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_certificateHandle(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
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

    object->private.certificateHandle = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_pSigningMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
    CK_VOID_PTR pParameter = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->pSigningMechanism.ulParameterLen) {
        myNewxz(pParameter, object->pSigningMechanism.ulParameterLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pParameter) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }

    if (pParameter) {
        Copy(object->pSigningMechanism.pParameter, pParameter, object->pSigningMechanism.ulParameterLen, CK_BYTE);
    }

    if (sv->private.pParameter) {
        Safefree(sv->private.pParameter);
    }
    sv->private.mechanism = object->pSigningMechanism.mechanism;
    sv->private.pParameter = pParameter;
    sv->private.ulParameterLen = object->pSigningMechanism.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_pSigningMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
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

    if (object->pSigningMechanism.pParameter) {
        Safefree(object->pSigningMechanism.pParameter);
    }
    object->pSigningMechanism.mechanism = sv->private.mechanism;
    object->pSigningMechanism.pParameter = pParameter;
    object->pSigningMechanism.ulParameterLen = sv->private.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_pDigestMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
    CK_VOID_PTR pParameter = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->pDigestMechanism.ulParameterLen) {
        myNewxz(pParameter, object->pDigestMechanism.ulParameterLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pParameter) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }
    }

    if (pParameter) {
        Copy(object->pDigestMechanism.pParameter, pParameter, object->pDigestMechanism.ulParameterLen, CK_BYTE);
    }

    if (sv->private.pParameter) {
        Safefree(sv->private.pParameter);
    }
    sv->private.mechanism = object->pDigestMechanism.mechanism;
    sv->private.pParameter = pParameter;
    sv->private.ulParameterLen = object->pDigestMechanism.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_pDigestMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv) {
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

    if (object->pDigestMechanism.pParameter) {
        Safefree(object->pDigestMechanism.pParameter);
    }
    object->pDigestMechanism.mechanism = sv->private.mechanism;
    object->pDigestMechanism.pParameter = pParameter;
    object->pDigestMechanism.ulParameterLen = sv->private.ulParameterLen;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_pContentType(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpv(sv, object->private.pContentType);
    sv_utf8_upgrade_nomg(sv);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_pContentType(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
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
        if (object->private.pContentType) {
            Safefree(object->private.pContentType);
            object->private.pContentType = 0;
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

    myNewxz(n, l + 1, CK_CHAR);
    /* uncoverable branch 0 */
    if (!n) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    Copy(p, n, l, CK_CHAR);
    if (object->private.pContentType) {
        Safefree(object->private.pContentType);
    }
    object->private.pContentType = n;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_pRequestedAttributes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pRequestedAttributes, object->private.ulRequestedAttributesLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_pRequestedAttributes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
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
        if (object->private.pRequestedAttributes) {
            Safefree(object->private.pRequestedAttributes);
            object->private.pRequestedAttributes = 0;
            object->private.ulRequestedAttributesLen = 0;
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
    if (object->private.pRequestedAttributes) {
        Safefree(object->private.pRequestedAttributes);
    }
    object->private.pRequestedAttributes = n;
    object->private.ulRequestedAttributesLen = l;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_get_pRequiredAttributes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pRequiredAttributes, object->private.ulRequiredAttributesLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_cms_sig_params_set_pRequiredAttributes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv) {
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
        if (object->private.pRequiredAttributes) {
            Safefree(object->private.pRequiredAttributes);
            object->private.pRequiredAttributes = 0;
            object->private.ulRequiredAttributesLen = 0;
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
    if (object->private.pRequiredAttributes) {
        Safefree(object->private.pRequiredAttributes);
    }
    object->private.pRequiredAttributes = n;
    object->private.ulRequiredAttributesLen = l;

    return CKR_OK;
}

