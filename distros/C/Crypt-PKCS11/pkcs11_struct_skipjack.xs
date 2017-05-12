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

MODULE = Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS  PACKAGE = Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS  PREFIX = crypt_pkcs11_ck_skipjack_private_wrap_params_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS*
crypt_pkcs11_ck_skipjack_private_wrap_params_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS  PACKAGE = Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMSPtr  PREFIX = crypt_pkcs11_ck_skipjack_private_wrap_params_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_skipjack_private_wrap_params_DESTROY(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_toBytes(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_fromBytes(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pPassword(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pPublicData(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pRandomA(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pPrimeP(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPrimeP(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pBaseG(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pBaseG(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_private_wrap_params_pSubprimeQ(object)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_private_wrap_params_set_pSubprimeQ(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS  PACKAGE = Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS  PREFIX = crypt_pkcs11_ck_skipjack_relayx_params_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS*
crypt_pkcs11_ck_skipjack_relayx_params_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS  PACKAGE = Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMSPtr  PREFIX = crypt_pkcs11_ck_skipjack_relayx_params_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_skipjack_relayx_params_DESTROY(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_skipjack_relayx_params_toBytes(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_fromBytes(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pOldWrappedX(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pOldWrappedX(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pOldPassword(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pOldPublicData(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pOldRandomA(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pOldRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pNewPassword(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPassword(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pNewPublicData(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPublicData(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_skipjack_relayx_params_pNewRandomA(object)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_skipjack_relayx_params_set_pNewRandomA(object, sv)
    Crypt::PKCS11::CK_SKIPJACK_RELAYX_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL


MODULE = Crypt::PKCS11::CK_SKIPJACK  PACKAGE = Crypt::PKCS11::CK_SKIPJACK

