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

MODULE = Crypt::PKCS11::CK_SSL3_RANDOM_DATA  PACKAGE = Crypt::PKCS11::CK_SSL3_RANDOM_DATA  PREFIX = crypt_pkcs11_ck_ssl3_random_data_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SSL3_RANDOM_DATA*
crypt_pkcs11_ck_ssl3_random_data_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_RANDOM_DATA  PACKAGE = Crypt::PKCS11::CK_SSL3_RANDOM_DATAPtr  PREFIX = crypt_pkcs11_ck_ssl3_random_data_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_ssl3_random_data_DESTROY(object)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_ssl3_random_data_toBytes(object)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_random_data_fromBytes(object, sv)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(object, sv)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_random_data_pClientRandom(object)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_random_data_set_pClientRandom(object, sv)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(object, sv)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_random_data_pServerRandom(object)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_random_data_set_pServerRandom(object, sv)
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS  PACKAGE = Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS  PREFIX = crypt_pkcs11_ck_ssl3_master_key_derive_params_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS*
crypt_pkcs11_ck_ssl3_master_key_derive_params_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS  PACKAGE = Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMSPtr  PREFIX = crypt_pkcs11_ck_ssl3_master_key_derive_params_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_ssl3_master_key_derive_params_DESTROY(object)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_ssl3_master_key_derive_params_toBytes(object)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_master_key_derive_params_fromBytes(object, sv)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(object, sv)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

Crypt::PKCS11::CK_SSL3_RANDOM_DATA*
crypt_pkcs11_ck_ssl3_master_key_derive_params_RandomInfo(object)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = crypt_pkcs11_ck_ssl3_random_data_new("Crypt::PKCS11::CK_SSL3_RANDOM_DATA");
    crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_master_key_derive_params_set_RandomInfo(object, sv)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_master_key_derive_params_get_pVersion(object, sv)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
    Crypt::PKCS11::CK_VERSION* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

Crypt::PKCS11::CK_VERSION*
crypt_pkcs11_ck_ssl3_master_key_derive_params_pVersion(object)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = crypt_pkcs11_ck_version_new("Crypt::PKCS11::CK_VERSION");
    crypt_pkcs11_ck_ssl3_master_key_derive_params_get_pVersion(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_master_key_derive_params_set_pVersion(object, sv)
    Crypt::PKCS11::CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object
    Crypt::PKCS11::CK_VERSION* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT  PACKAGE = Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT  PREFIX = crypt_pkcs11_ck_ssl3_key_mat_out_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT*
crypt_pkcs11_ck_ssl3_key_mat_out_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT  PACKAGE = Crypt::PKCS11::CK_SSL3_KEY_MAT_OUTPtr  PREFIX = crypt_pkcs11_ck_ssl3_key_mat_out_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_ssl3_key_mat_out_DESTROY(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_toBytes(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_fromBytes(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_hClientMacSecret(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientMacSecret(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_hServerMacSecret(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerMacSecret(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_hClientKey(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientKey(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_hServerKey(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerKey(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_pIVClient(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVClient(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_out_pIVServer(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVServer(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS  PACKAGE = Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS  PREFIX = crypt_pkcs11_ck_ssl3_key_mat_params_

PROTOTYPES: ENABLE

Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS*
crypt_pkcs11_ck_ssl3_key_mat_params_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

MODULE = Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS  PACKAGE = Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMSPtr  PREFIX = crypt_pkcs11_ck_ssl3_key_mat_params_

PROTOTYPES: ENABLE

void
crypt_pkcs11_ck_ssl3_key_mat_params_DESTROY(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $

SV*
crypt_pkcs11_ck_ssl3_key_mat_params_toBytes(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_fromBytes(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_params_ulMacSizeInBits(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_set_ulMacSizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_params_ulKeySizeInBits(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_set_ulKeySizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_params_ulIVSizeInBits(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_set_ulIVSizeInBits(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

SV*
crypt_pkcs11_ck_ssl3_key_mat_params_bIsExport(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = newSV(0);
    crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_set_bIsExport(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    SV* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

Crypt::PKCS11::CK_SSL3_RANDOM_DATA*
crypt_pkcs11_ck_ssl3_key_mat_params_RandomInfo(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = crypt_pkcs11_ck_ssl3_random_data_new("Crypt::PKCS11::CK_SSL3_RANDOM_DATA");
    crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(object, RETVAL);
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_set_RandomInfo(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    Crypt::PKCS11::CK_SSL3_RANDOM_DATA* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_ck_ssl3_key_mat_params_get_pReturnedKeyMaterial(object, sv)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
    Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT* sv
PROTOTYPE: $$
OUTPUT:
    RETVAL

Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT*
crypt_pkcs11_ck_ssl3_key_mat_params_pReturnedKeyMaterial(object)
    Crypt::PKCS11::CK_SSL3_KEY_MAT_PARAMS* object
PROTOTYPE: $
CODE:
    RETVAL = crypt_pkcs11_ck_ssl3_key_mat_out_new("Crypt::PKCS11::CK_SSL3_KEY_MAT_OUT");
    crypt_pkcs11_ck_ssl3_key_mat_params_get_pReturnedKeyMaterial(object, RETVAL);
OUTPUT:
    RETVAL


MODULE = Crypt::PKCS11::CK_SSL3  PACKAGE = Crypt::PKCS11::CK_SSL3

