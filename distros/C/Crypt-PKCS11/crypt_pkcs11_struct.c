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
int __test_devel_cover_calloc_always_fail = 0;
#define myNewxz(a,b,c) if (__test_devel_cover_calloc_always_fail) { a = 0; } else { Newxz(a, b, c); }
#define __croak(x) return 0
/* uncoverable begin */
int crypt_pkcs11_struct_xs_test_devel_cover(void) {
    {
        Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object = 0;
        myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT);
        if (!object) { return __LINE__; };
        myNewxz(object->private.pIVClient, 1, char);
        if (!object->private.pIVClient) { return __LINE__; }
        myNewxz(object->private.pIVServer, 1, char);
        if (!object->private.pIVServer) { return __LINE__; }
        crypt_pkcs11_ck_ssl3_key_mat_out_DESTROY(object);
    }
    {
        Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object = 0;
        myNewxz(object, 1, Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS);
        if (!object) { return __LINE__; };
        myNewxz(object->pReturnedKeyMaterial.pIVClient, 1, char);
        if (!object->pReturnedKeyMaterial.pIVClient) { return __LINE__; }
        myNewxz(object->pReturnedKeyMaterial.pIVServer, 1, char);
        if (!object->pReturnedKeyMaterial.pIVServer) { return __LINE__; }
        crypt_pkcs11_ck_ssl3_key_mat_params_DESTROY(object);
    }
    {
        Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object = 0;
        myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT);
        if (!object) { return __LINE__; };
        myNewxz(object->private.pIV, 1, char);
        if (!object->private.pIV) { return __LINE__; }
        crypt_pkcs11_ck_wtls_key_mat_out_DESTROY(object);
    }
    {
        Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object = 0;
        myNewxz(object, 1, Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS);
        if (!object) { return __LINE__; };
        myNewxz(object->pReturnedKeyMaterial.pIV, 1, char);
        if (!object->pReturnedKeyMaterial.pIV) { return __LINE__; }
        crypt_pkcs11_ck_wtls_key_mat_params_DESTROY(object);
    }
    return 0;
}
/* uncoverable end */
#else
#define myNewxz Newxz
#define __croak(x) croak(x)
#endif

extern int crypt_pkcs11_xs_SvUOK(SV* sv);

