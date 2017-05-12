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

MODULE = Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS  PACKAGE = Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS  PREFIX = crypt_pkcs11_ck_key_wrap_set_oaep_params_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS*
crypt_pkcs11_ck_key_wrap_set_oaep_params_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS  PACKAGE = Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMSPtr  PREFIX = crypt_pkcs11_ck_key_wrap_set_oaep_params_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_key_wrap_set_oaep_params_DESTROY(object)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_key_wrap_set_oaep_params_toBytes(object)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(object, sv)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(object, sv)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_key_wrap_set_oaep_params_bBC(object)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_wrap_set_oaep_params_set_bBC(object, sv)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(object, sv)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_key_wrap_set_oaep_params_pX(object)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_wrap_set_oaep_params_set_pX(object, sv)
    Crypt::PKCS11::CK_KEY_WRAP_SET_OAEP_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA  PACKAGE = Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA  PREFIX = crypt_pkcs11_ck_key_derivation_string_data_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA*
crypt_pkcs11_ck_key_derivation_string_data_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA  PACKAGE = Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATAPtr  PREFIX = crypt_pkcs11_ck_key_derivation_string_data_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_key_derivation_string_data_DESTROY(object)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_key_derivation_string_data_toBytes(object)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_derivation_string_data_fromBytes(object, sv)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_derivation_string_data_get_pData(object, sv)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_key_derivation_string_data_pData(object)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_key_derivation_string_data_get_pData(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_key_derivation_string_data_set_pData(object, sv)
    Crypt::PKCS11::CK_KEY_DERIVATION_STRING_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL


MODULE = Crypt::PKCS11::CK_KEY  PACKAGE = Crypt::PKCS11::CK_KEY

