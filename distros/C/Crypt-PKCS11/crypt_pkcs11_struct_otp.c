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

Crypt__PKCS11__CK_OTP_PARAM* crypt_pkcs11_ck_otp_param_new(const char* class) {
    Crypt__PKCS11__CK_OTP_PARAM* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_OTP_PARAM);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_otp_param_toBytes(Crypt__PKCS11__CK_OTP_PARAM* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_OTP_PARAM));
}

CK_RV crypt_pkcs11_ck_otp_param_fromBytes(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv) {
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
        || l != sizeof(CK_OTP_PARAM))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pValue) {
        Safefree(object->private.pValue);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pValue) {
        CK_BYTE_PTR pValue = 0;
        myNewxz(pValue, object->private.ulValueLen, CK_BYTE);
        /* uncoverable branch 0 */
        if (!pValue) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }
        Copy(object->private.pValue, pValue, object->private.ulValueLen, CK_BYTE);
        object->private.pValue = pValue;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_otp_param_DESTROY(Crypt__PKCS11__CK_OTP_PARAM* object) {
    if (object) {
        if (object->private.pValue) {
            Safefree(object->private.pValue);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_otp_param_get_type(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.type);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_param_set_type(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv) {
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

    object->private.type = SvUV(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_param_get_pValue(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setpvn(sv, object->private.pValue, object->private.ulValueLen * sizeof(CK_BYTE));
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_param_set_pValue(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv) {
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
        if (object->private.pValue) {
            Safefree(object->private.pValue);
            object->private.pValue = 0;
            object->private.ulValueLen = 0;
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
    if (object->private.pValue) {
        Safefree(object->private.pValue);
    }
    object->private.pValue = n;
    object->private.ulValueLen = l;

    return CKR_OK;
}

Crypt__PKCS11__CK_OTP_PARAMS* crypt_pkcs11_ck_otp_params_new(const char* class) {
    Crypt__PKCS11__CK_OTP_PARAMS* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_OTP_PARAMS);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_otp_params_toBytes(Crypt__PKCS11__CK_OTP_PARAMS* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_OTP_PARAMS));
}

CK_RV crypt_pkcs11_ck_otp_params_fromBytes(Crypt__PKCS11__CK_OTP_PARAMS* object, SV* sv) {
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
        || l != sizeof(CK_OTP_PARAMS))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pParams) {
        CK_ULONG ulCount;
        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                Safefree(object->private.pParams[ulCount].pValue);
            }
        }
        Safefree(object->private.pParams);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pParams) {
        CK_OTP_PARAM_PTR params = 0;
        CK_ULONG ulCount;

        myNewxz(params, object->private.ulCount, CK_OTP_PARAM);
        /* uncoverable branch 0 */
        if (!params) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }

        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            params[ulCount].type = object->private.pParams[ulCount].type;
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                myNewxz(params[ulCount].pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
                /* uncoverable branch 0 */
                if (!params[ulCount].pValue) {
                    /* uncoverable block 0 */
                    __croak("memory allocation error");
                }
                Copy(object->private.pParams[ulCount].pValue, params[ulCount].pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            }
        }
        object->private.pParams = params;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_otp_params_DESTROY(Crypt__PKCS11__CK_OTP_PARAMS* object) {
    if (object) {
        if (object->private.pParams) {
            CK_ULONG ulCount;
            for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
                /* uncoverable branch 1 */
                if (object->private.pParams[ulCount].pValue) {
                    Safefree(object->private.pParams[ulCount].pValue);
                }
            }
            Safefree(object->private.pParams);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_otp_params_get_pParams(Crypt__PKCS11__CK_OTP_PARAMS* object, AV* sv) {
    CK_ULONG ulCount;
    Crypt__PKCS11__CK_OTP_PARAM* param;
    SV* paramSV;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (!(object->private.ulCount)) {
        return CKR_OK;
    }

    for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
        param = 0;
        myNewxz(param, 1, Crypt__PKCS11__CK_OTP_PARAM);
        /* uncoverable branch 0 */
        if (!param) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }

        param->private.type = object->private.pParams[ulCount].type;
        /* uncoverable branch 1 */
        if (object->private.pParams[ulCount].pValue) {
            myNewxz(param->private.pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!param->private.pValue) {
                /* uncoverable begin */
                Safefree(param);
                return CKR_HOST_MEMORY;
                /* uncoverable end */
            }
            Copy(object->private.pParams[ulCount].pValue, param->private.pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            param->private.ulValueLen = object->private.pParams[ulCount].ulValueLen;
        }

        paramSV = sv_setref_pv(newSV(0), "Crypt::PKCS11::CK_OTP_PARAMPtr", param);
        av_push(sv, paramSV);
    }

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_params_set_pParams(Crypt__PKCS11__CK_OTP_PARAMS* object, AV* sv) {
    CK_ULONG ulCount;
    I32 key;
    SV** item;
    SV* entry;
    IV tmp;
    Crypt__PKCS11__CK_OTP_PARAM* param;
    CK_OTP_PARAM_PTR params = 0;
    CK_ULONG paramCount = 0;
    CK_RV rv = CKR_OK;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    for (key = 0; key < av_len(sv) + 1; key++) {
        item = av_fetch(sv, key, 0);

        /* uncoverable begin */
        if (!item || !*item || !SvROK(*item)
        /* uncoverable end */
            || !sv_derived_from(*item, "Crypt::PKCS11::CK_OTP_PARAMPtr"))
        {
            return CKR_ARGUMENTS_BAD;
        }

        paramCount++;
    }

    myNewxz(params, paramCount, CK_OTP_PARAM);
    /* uncoverable branch 0 */
    if (!params) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    for (key = 0; key < av_len(sv) + 1; key++) {
        item = av_fetch(sv, key, 0);

        /* uncoverable begin */
        if (!item || !*item || !SvROK(*item)
            || !sv_derived_from(*item, "Crypt::PKCS11::CK_OTP_PARAMPtr"))
        {
            rv = CKR_ARGUMENTS_BAD;
            break;
        }

        tmp = SvIV((SV*)SvRV(*item));
        if (!(param = INT2PTR(Crypt__PKCS11__CK_OTP_PARAM*, tmp))) {
            rv = CKR_GENERAL_ERROR;
            break;
        }
        /* uncoverable end */

        params[key].type = param->private.type;
        /* uncoverable branch 1 */
        if (param->private.pValue) {
            myNewxz(params[key].pValue, param->private.ulValueLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!params[key].pValue) {
                /* uncoverable begin */
                rv = CKR_HOST_MEMORY;
                break;
                /* uncoverable end */
            }

            Copy(param->private.pValue, params[key].pValue, param->private.ulValueLen, CK_BYTE);
            params[key].ulValueLen = param->private.ulValueLen;
        }
    }

    /* uncoverable begin */
    if (rv != CKR_OK) {
        for (ulCount = 0; ulCount < paramCount; ulCount++) {
            if (params[ulCount].pValue) {
                Safefree(params[ulCount].pValue);
            }
        }
        Safefree(params);
        return rv;
    }
    /* uncoverable end */

    if (object->private.pParams) {
        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                Safefree(object->private.pParams[ulCount].pValue);
            }
        }
        Safefree(object->private.pParams);
    }
    object->private.pParams = params;
    object->private.ulCount = paramCount;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_params_get_ulCount(Crypt__PKCS11__CK_OTP_PARAMS* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulCount);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_params_set_ulCount(Crypt__PKCS11__CK_OTP_PARAMS* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* crypt_pkcs11_ck_otp_signature_info_new(const char* class) {
    Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object = 0;
    myNewxz(object, 1, Crypt__PKCS11__CK_OTP_SIGNATURE_INFO);

    if (!object) {
        /* uncoverable block 0 */
        __croak("memory allocation error");
    }
    return object;
}

SV* crypt_pkcs11_ck_otp_signature_info_toBytes(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object) {
    if (!object) {
        return 0;
    }

    return newSVpvn((const char*)&(object->private), sizeof(CK_OTP_SIGNATURE_INFO));
}

CK_RV crypt_pkcs11_ck_otp_signature_info_fromBytes(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, SV* sv) {
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
        || l != sizeof(CK_OTP_SIGNATURE_INFO))
    {
        return CKR_ARGUMENTS_BAD;
    }

    if (object->private.pParams) {
        CK_ULONG ulCount;
        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                Safefree(object->private.pParams[ulCount].pValue);
            }
        }
        Safefree(object->private.pParams);
    }
    Copy(p, &(object->private), l, char);

    if (object->private.pParams) {
        CK_OTP_PARAM_PTR params = 0;
        CK_ULONG ulCount;

        myNewxz(params, object->private.ulCount, CK_OTP_PARAM);
        /* uncoverable branch 0 */
        if (!params) {
            /* uncoverable block 0 */
            __croak("memory allocation error");
        }

        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            params[ulCount].type = object->private.pParams[ulCount].type;
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                myNewxz(params[ulCount].pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
                /* uncoverable branch 0 */
                if (!params[ulCount].pValue) {
                    /* uncoverable block 0 */
                    __croak("memory allocation error");
                }
                Copy(object->private.pParams[ulCount].pValue, params[ulCount].pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            }
        }
        object->private.pParams = params;
    }
    return CKR_OK;
}

void crypt_pkcs11_ck_otp_signature_info_DESTROY(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object) {
    if (object) {
        if (object->private.pParams) {
            CK_ULONG ulCount;
            for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
                /* uncoverable branch 1 */
                if (object->private.pParams[ulCount].pValue) {
                    Safefree(object->private.pParams[ulCount].pValue);
                }
            }
            Safefree(object->private.pParams);
        }
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_ck_otp_signature_info_get_pParams(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, AV* sv) {
    CK_ULONG ulCount;
    Crypt__PKCS11__CK_OTP_PARAM* param;
    SV* paramSV;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    if (!(object->private.ulCount)) {
        return CKR_OK;
    }

    for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
        param = 0;
        myNewxz(param, 1, Crypt__PKCS11__CK_OTP_PARAM);
        /* uncoverable branch 0 */
        if (!param) {
            /* uncoverable block 0 */
            return CKR_HOST_MEMORY;
        }

        param->private.type = object->private.pParams[ulCount].type;
        /* uncoverable branch 1 */
        if (object->private.pParams[ulCount].pValue) {
            myNewxz(param->private.pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!param->private.pValue) {
                /* uncoverable begin */
                Safefree(param);
                return CKR_HOST_MEMORY;
                /* uncoverable end */
            }
            Copy(object->private.pParams[ulCount].pValue, param->private.pValue, object->private.pParams[ulCount].ulValueLen, CK_BYTE);
            param->private.ulValueLen = object->private.pParams[ulCount].ulValueLen;
        }

        paramSV = sv_setref_pv(newSV(0), "Crypt::PKCS11::CK_OTP_PARAMPtr", param);
        av_push(sv, paramSV);
    }

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_signature_info_set_pParams(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, AV* sv) {
    CK_ULONG ulCount;
    I32 key;
    SV** item;
    SV* entry;
    IV tmp;
    Crypt__PKCS11__CK_OTP_PARAM* param;
    CK_OTP_PARAM_PTR params = 0;
    CK_ULONG paramCount = 0;
    CK_RV rv = CKR_OK;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    for (key = 0; key < av_len(sv) + 1; key++) {
        item = av_fetch(sv, key, 0);

        /* uncoverable begin */
        if (!item || !*item || !SvROK(*item)
        /* uncoverable end */
            || !sv_derived_from(*item, "Crypt::PKCS11::CK_OTP_PARAMPtr"))
        {
            return CKR_ARGUMENTS_BAD;
        }

        paramCount++;
    }

    myNewxz(params, paramCount, CK_OTP_PARAM);
    /* uncoverable branch 0 */
    if (!params) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    for (key = 0; key < av_len(sv) + 1; key++) {
        item = av_fetch(sv, key, 0);

        /* uncoverable begin */
        if (!item || !*item || !SvROK(*item)
            || !sv_derived_from(*item, "Crypt::PKCS11::CK_OTP_PARAMPtr"))
        {
            rv = CKR_ARGUMENTS_BAD;
            break;
        }

        tmp = SvIV((SV*)SvRV(*item));
        if (!(param = INT2PTR(Crypt__PKCS11__CK_OTP_PARAM*, tmp))) {
            rv = CKR_GENERAL_ERROR;
            break;
        }
        /* uncoverable end */

        params[key].type = param->private.type;
        /* uncoverable branch 1 */
        if (param->private.pValue) {
            myNewxz(params[key].pValue, param->private.ulValueLen, CK_BYTE);
            /* uncoverable branch 0 */
            if (!params[key].pValue) {
                /* uncoverable begin */
                rv = CKR_HOST_MEMORY;
                break;
                /* uncoverable end */
            }

            Copy(param->private.pValue, params[key].pValue, param->private.ulValueLen, CK_BYTE);
            params[key].ulValueLen = param->private.ulValueLen;
        }
    }

    /* uncoverable begin */
    if (rv != CKR_OK) {
        for (ulCount = 0; ulCount < paramCount; ulCount++) {
            if (params[ulCount].pValue) {
                Safefree(params[ulCount].pValue);
            }
        }
        Safefree(params);
        return rv;
    }
    /* uncoverable end */

    if (object->private.pParams) {
        for (ulCount = 0; ulCount < object->private.ulCount; ulCount++) {
            /* uncoverable branch 1 */
            if (object->private.pParams[ulCount].pValue) {
                Safefree(object->private.pParams[ulCount].pValue);
            }
        }
        Safefree(object->private.pParams);
    }
    object->private.pParams = params;
    object->private.ulCount = paramCount;

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_signature_info_get_ulCount(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, SV* sv) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!sv) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(sv);
    sv_setuv(sv, object->private.ulCount);
    SvSETMAGIC(sv);

    return CKR_OK;
}

CK_RV crypt_pkcs11_ck_otp_signature_info_set_ulCount(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, SV* sv) {
    return CKR_FUNCTION_NOT_SUPPORTED;
}

