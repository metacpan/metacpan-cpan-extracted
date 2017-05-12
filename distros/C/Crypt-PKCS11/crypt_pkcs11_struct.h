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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "cryptoki.h"

#ifdef TEST_DEVEL_COVER
int crypt_pkcs11_struct_xs_test_devel_cover(void);
#endif

typedef struct Crypt__PKCS11__CK_VERSION {
    CK_VERSION private;
} Crypt__PKCS11__CK_VERSION;
Crypt__PKCS11__CK_VERSION* crypt_pkcs11_ck_version_new(const char* class);
void crypt_pkcs11_ck_version_DESTROY(Crypt__PKCS11__CK_VERSION* object);
SV* crypt_pkcs11_ck_version_toBytes(Crypt__PKCS11__CK_VERSION* object);
CK_RV crypt_pkcs11_ck_version_fromBytes(Crypt__PKCS11__CK_VERSION* object, SV* sv);
CK_RV crypt_pkcs11_ck_version_get_major(Crypt__PKCS11__CK_VERSION* object, SV* sv);
CK_RV crypt_pkcs11_ck_version_set_major(Crypt__PKCS11__CK_VERSION* object, SV* sv);
CK_RV crypt_pkcs11_ck_version_get_minor(Crypt__PKCS11__CK_VERSION* object, SV* sv);
CK_RV crypt_pkcs11_ck_version_set_minor(Crypt__PKCS11__CK_VERSION* object, SV* sv);

typedef struct Crypt__PKCS11__CK_MECHANISM {
    CK_MECHANISM private;
} Crypt__PKCS11__CK_MECHANISM;
Crypt__PKCS11__CK_MECHANISM* crypt_pkcs11_ck_mechanism_new(const char* class);
void crypt_pkcs11_ck_mechanism_DESTROY(Crypt__PKCS11__CK_MECHANISM* object);
SV* crypt_pkcs11_ck_mechanism_toBytes(Crypt__PKCS11__CK_MECHANISM* object);
CK_RV crypt_pkcs11_ck_mechanism_fromBytes(Crypt__PKCS11__CK_MECHANISM* object, SV* sv);
CK_RV crypt_pkcs11_ck_mechanism_get_mechanism(Crypt__PKCS11__CK_MECHANISM* object, SV* sv);
CK_RV crypt_pkcs11_ck_mechanism_set_mechanism(Crypt__PKCS11__CK_MECHANISM* object, SV* sv);
CK_RV crypt_pkcs11_ck_mechanism_get_pParameter(Crypt__PKCS11__CK_MECHANISM* object, SV* sv);
CK_RV crypt_pkcs11_ck_mechanism_set_pParameter(Crypt__PKCS11__CK_MECHANISM* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS {
    CK_RSA_PKCS_OAEP_PARAMS private;
} Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS;
Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* crypt_pkcs11_ck_rsa_pkcs_oaep_params_new(const char* class);
void crypt_pkcs11_ck_rsa_pkcs_oaep_params_DESTROY(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object);
SV* crypt_pkcs11_ck_rsa_pkcs_oaep_params_toBytes(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_fromBytes(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_mgf(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_mgf(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_source(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_source(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_pSourceData(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_pSourceData(Crypt__PKCS11__CK_RSA_PKCS_OAEP_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS {
    CK_RSA_PKCS_PSS_PARAMS private;
} Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS;
Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* crypt_pkcs11_ck_rsa_pkcs_pss_params_new(const char* class);
void crypt_pkcs11_ck_rsa_pkcs_pss_params_DESTROY(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object);
SV* crypt_pkcs11_ck_rsa_pkcs_pss_params_toBytes(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_fromBytes(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_hashAlg(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_mgf(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_mgf(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_get_sLen(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rsa_pkcs_pss_params_set_sLen(Crypt__PKCS11__CK_RSA_PKCS_PSS_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS {
    CK_ECDH1_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS;
Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* crypt_pkcs11_ck_ecdh1_derive_params_new(const char* class);
void crypt_pkcs11_ck_ecdh1_derive_params_DESTROY(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_ecdh1_derive_params_toBytes(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_fromBytes(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_get_kdf(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_set_kdf(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_get_pSharedData(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_set_pSharedData(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_get_pPublicData(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh1_derive_params_set_pPublicData(Crypt__PKCS11__CK_ECDH1_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS {
    CK_ECDH2_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS;
Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* crypt_pkcs11_ck_ecdh2_derive_params_new(const char* class);
void crypt_pkcs11_ck_ecdh2_derive_params_DESTROY(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_ecdh2_derive_params_toBytes(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_fromBytes(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_get_kdf(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_set_kdf(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_get_pSharedData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_set_pSharedData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_get_hPrivateData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_set_hPrivateData(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData2(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData2(Crypt__PKCS11__CK_ECDH2_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS {
    CK_ECMQV_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS;
Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* crypt_pkcs11_ck_ecmqv_derive_params_new(const char* class);
void crypt_pkcs11_ck_ecmqv_derive_params_DESTROY(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_ecmqv_derive_params_toBytes(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_fromBytes(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_kdf(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_kdf(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_pSharedData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_pSharedData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_hPrivateData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_hPrivateData(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData2(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData2(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_get_publicKey(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ecmqv_derive_params_set_publicKey(Crypt__PKCS11__CK_ECMQV_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS {
    CK_X9_42_DH1_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS;
Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* crypt_pkcs11_ck_x9_42_dh1_derive_params_new(const char* class);
void crypt_pkcs11_ck_x9_42_dh1_derive_params_DESTROY(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_x9_42_dh1_derive_params_toBytes(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_fromBytes(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_get_kdf(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_set_kdf(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pOtherInfo(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pOtherInfo(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pPublicData(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pPublicData(Crypt__PKCS11__CK_X9_42_DH1_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS {
    CK_X9_42_DH2_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS;
Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* crypt_pkcs11_ck_x9_42_dh2_derive_params_new(const char* class);
void crypt_pkcs11_ck_x9_42_dh2_derive_params_DESTROY(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_x9_42_dh2_derive_params_toBytes(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_fromBytes(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_get_kdf(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_set_kdf(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pOtherInfo(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pOtherInfo(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_get_hPrivateData(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_set_hPrivateData(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData2(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData2(Crypt__PKCS11__CK_X9_42_DH2_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS {
    CK_X9_42_MQV_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS;
Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* crypt_pkcs11_ck_x9_42_mqv_derive_params_new(const char* class);
void crypt_pkcs11_ck_x9_42_mqv_derive_params_DESTROY(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_x9_42_mqv_derive_params_toBytes(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_fromBytes(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_kdf(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_kdf(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pOtherInfo(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pOtherInfo(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_hPrivateData(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_hPrivateData(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData2(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData2(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_get_publicKey(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_x9_42_mqv_derive_params_set_publicKey(Crypt__PKCS11__CK_X9_42_MQV_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_KEA_DERIVE_PARAMS {
    CK_KEA_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_KEA_DERIVE_PARAMS;
Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* crypt_pkcs11_ck_kea_derive_params_new(const char* class);
void crypt_pkcs11_ck_kea_derive_params_DESTROY(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_kea_derive_params_toBytes(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_kea_derive_params_fromBytes(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_get_isSender(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_set_isSender(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_get_pRandomA(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_set_pRandomA(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_get_pRandomB(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_set_pRandomB(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_get_pPublicData(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kea_derive_params_set_pPublicData(Crypt__PKCS11__CK_KEA_DERIVE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RC2_CBC_PARAMS {
    CK_RC2_CBC_PARAMS private;
} Crypt__PKCS11__CK_RC2_CBC_PARAMS;
Crypt__PKCS11__CK_RC2_CBC_PARAMS* crypt_pkcs11_ck_rc2_cbc_params_new(const char* class);
void crypt_pkcs11_ck_rc2_cbc_params_DESTROY(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object);
SV* crypt_pkcs11_ck_rc2_cbc_params_toBytes(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object);
CK_RV crypt_pkcs11_ck_rc2_cbc_params_fromBytes(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_cbc_params_get_ulEffectiveBits(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_cbc_params_set_ulEffectiveBits(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_cbc_params_get_iv(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_cbc_params_set_iv(Crypt__PKCS11__CK_RC2_CBC_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS {
    CK_RC2_MAC_GENERAL_PARAMS private;
} Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS;
Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* crypt_pkcs11_ck_rc2_mac_general_params_new(const char* class);
void crypt_pkcs11_ck_rc2_mac_general_params_DESTROY(Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* object);
SV* crypt_pkcs11_ck_rc2_mac_general_params_toBytes(Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* object);
CK_RV crypt_pkcs11_ck_rc2_mac_general_params_fromBytes(Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_mac_general_params_get_ulEffectiveBits(Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc2_mac_general_params_set_ulEffectiveBits(Crypt__PKCS11__CK_RC2_MAC_GENERAL_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RC5_PARAMS {
    CK_RC5_PARAMS private;
} Crypt__PKCS11__CK_RC5_PARAMS;
Crypt__PKCS11__CK_RC5_PARAMS* crypt_pkcs11_ck_rc5_params_new(const char* class);
void crypt_pkcs11_ck_rc5_params_DESTROY(Crypt__PKCS11__CK_RC5_PARAMS* object);
SV* crypt_pkcs11_ck_rc5_params_toBytes(Crypt__PKCS11__CK_RC5_PARAMS* object);
CK_RV crypt_pkcs11_ck_rc5_params_fromBytes(Crypt__PKCS11__CK_RC5_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_params_get_ulWordsize(Crypt__PKCS11__CK_RC5_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_params_set_ulWordsize(Crypt__PKCS11__CK_RC5_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_params_get_ulRounds(Crypt__PKCS11__CK_RC5_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_params_set_ulRounds(Crypt__PKCS11__CK_RC5_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RC5_CBC_PARAMS {
    CK_RC5_CBC_PARAMS private;
} Crypt__PKCS11__CK_RC5_CBC_PARAMS;
Crypt__PKCS11__CK_RC5_CBC_PARAMS* crypt_pkcs11_ck_rc5_cbc_params_new(const char* class);
void crypt_pkcs11_ck_rc5_cbc_params_DESTROY(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object);
SV* crypt_pkcs11_ck_rc5_cbc_params_toBytes(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_fromBytes(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_get_ulWordsize(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_set_ulWordsize(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_get_ulRounds(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_set_ulRounds(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_get_pIv(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_cbc_params_set_pIv(Crypt__PKCS11__CK_RC5_CBC_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS {
    CK_RC5_MAC_GENERAL_PARAMS private;
} Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS;
Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* crypt_pkcs11_ck_rc5_mac_general_params_new(const char* class);
void crypt_pkcs11_ck_rc5_mac_general_params_DESTROY(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object);
SV* crypt_pkcs11_ck_rc5_mac_general_params_toBytes(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object);
CK_RV crypt_pkcs11_ck_rc5_mac_general_params_fromBytes(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_mac_general_params_get_ulWordsize(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_mac_general_params_set_ulWordsize(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_mac_general_params_get_ulRounds(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_rc5_mac_general_params_set_ulRounds(Crypt__PKCS11__CK_RC5_MAC_GENERAL_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS {
    CK_DES_CBC_ENCRYPT_DATA_PARAMS private;
} Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS;
Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* crypt_pkcs11_ck_des_cbc_encrypt_data_params_new(const char* class);
void crypt_pkcs11_ck_des_cbc_encrypt_data_params_DESTROY(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object);
SV* crypt_pkcs11_ck_des_cbc_encrypt_data_params_toBytes(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object);
CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_fromBytes(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_iv(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_iv(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_pData(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_pData(Crypt__PKCS11__CK_DES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS {
    CK_AES_CBC_ENCRYPT_DATA_PARAMS private;
} Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS;
Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* crypt_pkcs11_ck_aes_cbc_encrypt_data_params_new(const char* class);
void crypt_pkcs11_ck_aes_cbc_encrypt_data_params_DESTROY(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object);
SV* crypt_pkcs11_ck_aes_cbc_encrypt_data_params_toBytes(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object);
CK_RV crypt_pkcs11_ck_aes_cbc_encrypt_data_params_fromBytes(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_iv(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_iv(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_pData(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_pData(Crypt__PKCS11__CK_AES_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS {
    CK_SKIPJACK_PRIVATE_WRAP_PARAMS private;
} Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS;
Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* crypt_pkcs11_ck_skipjack_private_wrap_params_new(const char* class);
void crypt_pkcs11_ck_skipjack_private_wrap_params_DESTROY(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object);
SV* crypt_pkcs11_ck_skipjack_private_wrap_params_toBytes(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_fromBytes(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPassword(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPublicData(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pRandomA(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPrimeP(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pBaseG(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_private_wrap_params_set_pSubprimeQ(Crypt__PKCS11__CK_SKIPJACK_PRIVATE_WRAP_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS {
    CK_SKIPJACK_RELAYX_PARAMS private;
} Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS;
Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* crypt_pkcs11_ck_skipjack_relayx_params_new(const char* class);
void crypt_pkcs11_ck_skipjack_relayx_params_DESTROY(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object);
SV* crypt_pkcs11_ck_skipjack_relayx_params_toBytes(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_fromBytes(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldWrappedX(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pOldRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPassword(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPublicData(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_skipjack_relayx_params_set_pNewRandomA(Crypt__PKCS11__CK_SKIPJACK_RELAYX_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_PBE_PARAMS {
    CK_PBE_PARAMS private;
} Crypt__PKCS11__CK_PBE_PARAMS;
Crypt__PKCS11__CK_PBE_PARAMS* crypt_pkcs11_ck_pbe_params_new(const char* class);
void crypt_pkcs11_ck_pbe_params_DESTROY(Crypt__PKCS11__CK_PBE_PARAMS* object);
SV* crypt_pkcs11_ck_pbe_params_toBytes(Crypt__PKCS11__CK_PBE_PARAMS* object);
CK_RV crypt_pkcs11_ck_pbe_params_fromBytes(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_get_pInitVector(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_set_pInitVector(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_get_pPassword(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_set_pPassword(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_get_pSalt(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_set_pSalt(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_get_ulIteration(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pbe_params_set_ulIteration(Crypt__PKCS11__CK_PBE_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS {
    CK_KEY_WRAP_SET_OAEP_PARAMS private;
} Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS;
Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* crypt_pkcs11_ck_key_wrap_set_oaep_params_new(const char* class);
void crypt_pkcs11_ck_key_wrap_set_oaep_params_DESTROY(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object);
SV* crypt_pkcs11_ck_key_wrap_set_oaep_params_toBytes(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object);
CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_set_bBC(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_wrap_set_oaep_params_set_pX(Crypt__PKCS11__CK_KEY_WRAP_SET_OAEP_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_SSL3_RANDOM_DATA {
    CK_SSL3_RANDOM_DATA private;
} Crypt__PKCS11__CK_SSL3_RANDOM_DATA;
Crypt__PKCS11__CK_SSL3_RANDOM_DATA* crypt_pkcs11_ck_ssl3_random_data_new(const char* class);
void crypt_pkcs11_ck_ssl3_random_data_DESTROY(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object);
SV* crypt_pkcs11_ck_ssl3_random_data_toBytes(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object);
CK_RV crypt_pkcs11_ck_ssl3_random_data_fromBytes(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_random_data_set_pClientRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_random_data_set_pServerRandom(Crypt__PKCS11__CK_SSL3_RANDOM_DATA* object, SV* sv);

typedef struct Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS {
    CK_SSL3_MASTER_KEY_DERIVE_PARAMS private;
    CK_VERSION pVersion;
} Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS;
Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* crypt_pkcs11_ck_ssl3_master_key_derive_params_new(const char* class);
void crypt_pkcs11_ck_ssl3_master_key_derive_params_DESTROY(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_ssl3_master_key_derive_params_toBytes(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_fromBytes(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv);
CK_RV crypt_pkcs11_ck_ssl3_master_key_derive_params_set_RandomInfo(Crypt__PKCS11__CK_SSL3_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv);

typedef struct Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT {
    CK_SSL3_KEY_MAT_OUT private;
    CK_ULONG ulIVClient;
    CK_ULONG ulIVServer;
} Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT;
Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* crypt_pkcs11_ck_ssl3_key_mat_out_new(const char* class);
void crypt_pkcs11_ck_ssl3_key_mat_out_DESTROY(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object);
SV* crypt_pkcs11_ck_ssl3_key_mat_out_toBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_fromBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerMacSecret(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerKey(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVClient(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVServer(Crypt__PKCS11__CK_SSL3_KEY_MAT_OUT* object, SV* sv);

typedef struct Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS {
    CK_SSL3_KEY_MAT_PARAMS private;
    CK_SSL3_KEY_MAT_OUT pReturnedKeyMaterial;
} Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS;
Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* crypt_pkcs11_ck_ssl3_key_mat_params_new(const char* class);
void crypt_pkcs11_ck_ssl3_key_mat_params_DESTROY(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object);
SV* crypt_pkcs11_ck_ssl3_key_mat_params_toBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_fromBytes(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulMacSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulKeySizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_ulIVSizeInBits(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_bIsExport(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv);
CK_RV crypt_pkcs11_ck_ssl3_key_mat_params_set_RandomInfo(Crypt__PKCS11__CK_SSL3_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_SSL3_RANDOM_DATA* sv);

typedef struct Crypt__PKCS11__CK_TLS_PRF_PARAMS {
    CK_TLS_PRF_PARAMS private;
    CK_ULONG pulOutputLen;
} Crypt__PKCS11__CK_TLS_PRF_PARAMS;
Crypt__PKCS11__CK_TLS_PRF_PARAMS* crypt_pkcs11_ck_tls_prf_params_new(const char* class);
void crypt_pkcs11_ck_tls_prf_params_DESTROY(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object);
SV* crypt_pkcs11_ck_tls_prf_params_toBytes(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object);
CK_RV crypt_pkcs11_ck_tls_prf_params_fromBytes(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_get_pSeed(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_set_pSeed(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_get_pLabel(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_set_pLabel(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_get_pOutput(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_tls_prf_params_set_pOutput(Crypt__PKCS11__CK_TLS_PRF_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_WTLS_RANDOM_DATA {
    CK_WTLS_RANDOM_DATA private;
} Crypt__PKCS11__CK_WTLS_RANDOM_DATA;
Crypt__PKCS11__CK_WTLS_RANDOM_DATA* crypt_pkcs11_ck_wtls_random_data_new(const char* class);
void crypt_pkcs11_ck_wtls_random_data_DESTROY(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object);
SV* crypt_pkcs11_ck_wtls_random_data_toBytes(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object);
CK_RV crypt_pkcs11_ck_wtls_random_data_fromBytes(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_random_data_get_pClientRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_random_data_set_pClientRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_random_data_get_pServerRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_random_data_set_pServerRandom(Crypt__PKCS11__CK_WTLS_RANDOM_DATA* object, SV* sv);

typedef struct Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS {
    CK_WTLS_MASTER_KEY_DERIVE_PARAMS private;
} Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS;
Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* crypt_pkcs11_ck_wtls_master_key_derive_params_new(const char* class);
void crypt_pkcs11_ck_wtls_master_key_derive_params_DESTROY(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object);
SV* crypt_pkcs11_ck_wtls_master_key_derive_params_toBytes(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object);
CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_fromBytes(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_get_RandomInfo(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv);
CK_RV crypt_pkcs11_ck_wtls_master_key_derive_params_set_RandomInfo(Crypt__PKCS11__CK_WTLS_MASTER_KEY_DERIVE_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv);

typedef struct Crypt__PKCS11__CK_WTLS_PRF_PARAMS {
    CK_WTLS_PRF_PARAMS private;
    CK_ULONG pulOutputLen;
} Crypt__PKCS11__CK_WTLS_PRF_PARAMS;
Crypt__PKCS11__CK_WTLS_PRF_PARAMS* crypt_pkcs11_ck_wtls_prf_params_new(const char* class);
void crypt_pkcs11_ck_wtls_prf_params_DESTROY(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object);
SV* crypt_pkcs11_ck_wtls_prf_params_toBytes(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object);
CK_RV crypt_pkcs11_ck_wtls_prf_params_fromBytes(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pSeed(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pSeed(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pLabel(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pLabel(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_get_pOutput(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_prf_params_set_pOutput(Crypt__PKCS11__CK_WTLS_PRF_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT {
    CK_WTLS_KEY_MAT_OUT private;
    CK_ULONG ulIV;
} Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT;
Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* crypt_pkcs11_ck_wtls_key_mat_out_new(const char* class);
void crypt_pkcs11_ck_wtls_key_mat_out_DESTROY(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object);
SV* crypt_pkcs11_ck_wtls_key_mat_out_toBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_fromBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_hMacSecret(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_hMacSecret(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_hKey(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_hKey(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_get_pIV(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_out_set_pIV(Crypt__PKCS11__CK_WTLS_KEY_MAT_OUT* object, SV* sv);

typedef struct Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS {
    CK_WTLS_KEY_MAT_PARAMS private;
    CK_WTLS_KEY_MAT_OUT pReturnedKeyMaterial;
} Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS;
Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* crypt_pkcs11_ck_wtls_key_mat_params_new(const char* class);
void crypt_pkcs11_ck_wtls_key_mat_params_DESTROY(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object);
SV* crypt_pkcs11_ck_wtls_key_mat_params_toBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_fromBytes(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_DigestMechanism(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_DigestMechanism(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulMacSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulMacSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulKeySizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulKeySizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulIVSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulIVSizeInBits(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_ulSequenceNumber(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_ulSequenceNumber(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_bIsExport(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_bIsExport(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_get_RandomInfo(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv);
CK_RV crypt_pkcs11_ck_wtls_key_mat_params_set_RandomInfo(Crypt__PKCS11__CK_WTLS_KEY_MAT_PARAMS* object, Crypt__PKCS11__CK_WTLS_RANDOM_DATA* sv);

typedef struct Crypt__PKCS11__CK_CMS_SIG_PARAMS {
    CK_CMS_SIG_PARAMS private;
    CK_MECHANISM pSigningMechanism;
    CK_MECHANISM pDigestMechanism;
} Crypt__PKCS11__CK_CMS_SIG_PARAMS;
Crypt__PKCS11__CK_CMS_SIG_PARAMS* crypt_pkcs11_ck_cms_sig_params_new(const char* class);
void crypt_pkcs11_ck_cms_sig_params_DESTROY(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object);
SV* crypt_pkcs11_ck_cms_sig_params_toBytes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object);
CK_RV crypt_pkcs11_ck_cms_sig_params_fromBytes(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_cms_sig_params_get_certificateHandle(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_cms_sig_params_set_certificateHandle(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_cms_sig_params_get_pSigningMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv);
CK_RV crypt_pkcs11_ck_cms_sig_params_set_pSigningMechanism(Crypt__PKCS11__CK_CMS_SIG_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv);

typedef struct Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA {
    CK_KEY_DERIVATION_STRING_DATA private;
} Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA;
Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* crypt_pkcs11_ck_key_derivation_string_data_new(const char* class);
void crypt_pkcs11_ck_key_derivation_string_data_DESTROY(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object);
SV* crypt_pkcs11_ck_key_derivation_string_data_toBytes(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object);
CK_RV crypt_pkcs11_ck_key_derivation_string_data_fromBytes(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_derivation_string_data_get_pData(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv);
CK_RV crypt_pkcs11_ck_key_derivation_string_data_set_pData(Crypt__PKCS11__CK_KEY_DERIVATION_STRING_DATA* object, SV* sv);

typedef struct Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS {
    CK_PKCS5_PBKD2_PARAMS private;
    CK_ULONG ulPasswordLen;
} Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS;
Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* crypt_pkcs11_ck_pkcs5_pbkd2_params_new(const char* class);
void crypt_pkcs11_ck_pkcs5_pbkd2_params_DESTROY(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object);
SV* crypt_pkcs11_ck_pkcs5_pbkd2_params_toBytes(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_fromBytes(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_saltSource(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_saltSource(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pSaltSourceData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pSaltSourceData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_iterations(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_iterations(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_prf(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_prf(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPrfData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPrfData(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPassword(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPassword(Crypt__PKCS11__CK_PKCS5_PBKD2_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_OTP_PARAM {
    CK_OTP_PARAM private;
} Crypt__PKCS11__CK_OTP_PARAM;
Crypt__PKCS11__CK_OTP_PARAM* crypt_pkcs11_ck_otp_param_new(const char* class);
void crypt_pkcs11_ck_otp_param_DESTROY(Crypt__PKCS11__CK_OTP_PARAM* object);
SV* crypt_pkcs11_ck_otp_param_toBytes(Crypt__PKCS11__CK_OTP_PARAM* object);
CK_RV crypt_pkcs11_ck_otp_param_fromBytes(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_param_get_type(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_param_set_type(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_param_get_pValue(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_param_set_pValue(Crypt__PKCS11__CK_OTP_PARAM* object, SV* sv);

typedef struct Crypt__PKCS11__CK_OTP_PARAMS {
    CK_OTP_PARAMS private;
} Crypt__PKCS11__CK_OTP_PARAMS;
Crypt__PKCS11__CK_OTP_PARAMS* crypt_pkcs11_ck_otp_params_new(const char* class);
void crypt_pkcs11_ck_otp_params_DESTROY(Crypt__PKCS11__CK_OTP_PARAMS* object);
SV* crypt_pkcs11_ck_otp_params_toBytes(Crypt__PKCS11__CK_OTP_PARAMS* object);
CK_RV crypt_pkcs11_ck_otp_params_fromBytes(Crypt__PKCS11__CK_OTP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_params_get_pParams(Crypt__PKCS11__CK_OTP_PARAMS* object, AV* sv);
CK_RV crypt_pkcs11_ck_otp_params_set_pParams(Crypt__PKCS11__CK_OTP_PARAMS* object, AV* sv);

typedef struct Crypt__PKCS11__CK_OTP_SIGNATURE_INFO {
    CK_OTP_SIGNATURE_INFO private;
} Crypt__PKCS11__CK_OTP_SIGNATURE_INFO;
Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* crypt_pkcs11_ck_otp_signature_info_new(const char* class);
void crypt_pkcs11_ck_otp_signature_info_DESTROY(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object);
SV* crypt_pkcs11_ck_otp_signature_info_toBytes(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object);
CK_RV crypt_pkcs11_ck_otp_signature_info_fromBytes(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, SV* sv);
CK_RV crypt_pkcs11_ck_otp_signature_info_get_pParams(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, AV* sv);
CK_RV crypt_pkcs11_ck_otp_signature_info_set_pParams(Crypt__PKCS11__CK_OTP_SIGNATURE_INFO* object, AV* sv);

typedef struct Crypt__PKCS11__CK_KIP_PARAMS {
    CK_KIP_PARAMS private;
    CK_MECHANISM pMechanism;
} Crypt__PKCS11__CK_KIP_PARAMS;
Crypt__PKCS11__CK_KIP_PARAMS* crypt_pkcs11_ck_kip_params_new(const char* class);
void crypt_pkcs11_ck_kip_params_DESTROY(Crypt__PKCS11__CK_KIP_PARAMS* object);
SV* crypt_pkcs11_ck_kip_params_toBytes(Crypt__PKCS11__CK_KIP_PARAMS* object);
CK_RV crypt_pkcs11_ck_kip_params_fromBytes(Crypt__PKCS11__CK_KIP_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_kip_params_get_pMechanism(Crypt__PKCS11__CK_KIP_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv);
CK_RV crypt_pkcs11_ck_kip_params_set_pMechanism(Crypt__PKCS11__CK_KIP_PARAMS* object, Crypt__PKCS11__CK_MECHANISM* sv);

typedef struct Crypt__PKCS11__CK_AES_CTR_PARAMS {
    CK_AES_CTR_PARAMS private;
} Crypt__PKCS11__CK_AES_CTR_PARAMS;
Crypt__PKCS11__CK_AES_CTR_PARAMS* crypt_pkcs11_ck_aes_ctr_params_new(const char* class);
void crypt_pkcs11_ck_aes_ctr_params_DESTROY(Crypt__PKCS11__CK_AES_CTR_PARAMS* object);
SV* crypt_pkcs11_ck_aes_ctr_params_toBytes(Crypt__PKCS11__CK_AES_CTR_PARAMS* object);
CK_RV crypt_pkcs11_ck_aes_ctr_params_fromBytes(Crypt__PKCS11__CK_AES_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ctr_params_get_ulCounterBits(Crypt__PKCS11__CK_AES_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ctr_params_set_ulCounterBits(Crypt__PKCS11__CK_AES_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ctr_params_get_cb(Crypt__PKCS11__CK_AES_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ctr_params_set_cb(Crypt__PKCS11__CK_AES_CTR_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_AES_GCM_PARAMS {
    CK_AES_GCM_PARAMS private;
} Crypt__PKCS11__CK_AES_GCM_PARAMS;
Crypt__PKCS11__CK_AES_GCM_PARAMS* crypt_pkcs11_ck_aes_gcm_params_new(const char* class);
void crypt_pkcs11_ck_aes_gcm_params_DESTROY(Crypt__PKCS11__CK_AES_GCM_PARAMS* object);
SV* crypt_pkcs11_ck_aes_gcm_params_toBytes(Crypt__PKCS11__CK_AES_GCM_PARAMS* object);
CK_RV crypt_pkcs11_ck_aes_gcm_params_fromBytes(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_get_pIv(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_set_pIv(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_get_ulIvBits(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_set_ulIvBits(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_get_pAAD(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_set_pAAD(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_get_ulTagBits(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_gcm_params_set_ulTagBits(Crypt__PKCS11__CK_AES_GCM_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_AES_CCM_PARAMS {
    CK_AES_CCM_PARAMS private;
} Crypt__PKCS11__CK_AES_CCM_PARAMS;
Crypt__PKCS11__CK_AES_CCM_PARAMS* crypt_pkcs11_ck_aes_ccm_params_new(const char* class);
void crypt_pkcs11_ck_aes_ccm_params_DESTROY(Crypt__PKCS11__CK_AES_CCM_PARAMS* object);
SV* crypt_pkcs11_ck_aes_ccm_params_toBytes(Crypt__PKCS11__CK_AES_CCM_PARAMS* object);
CK_RV crypt_pkcs11_ck_aes_ccm_params_fromBytes(Crypt__PKCS11__CK_AES_CCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ccm_params_get_pNonce(Crypt__PKCS11__CK_AES_CCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ccm_params_set_pNonce(Crypt__PKCS11__CK_AES_CCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ccm_params_get_pAAD(Crypt__PKCS11__CK_AES_CCM_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aes_ccm_params_set_pAAD(Crypt__PKCS11__CK_AES_CCM_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS {
    CK_CAMELLIA_CTR_PARAMS private;
} Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS;
Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* crypt_pkcs11_ck_camellia_ctr_params_new(const char* class);
void crypt_pkcs11_ck_camellia_ctr_params_DESTROY(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object);
SV* crypt_pkcs11_ck_camellia_ctr_params_toBytes(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object);
CK_RV crypt_pkcs11_ck_camellia_ctr_params_fromBytes(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_ctr_params_get_ulCounterBits(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_ctr_params_set_ulCounterBits(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_ctr_params_get_cb(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_ctr_params_set_cb(Crypt__PKCS11__CK_CAMELLIA_CTR_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS {
    CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS private;
} Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS;
Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_new(const char* class);
void crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_DESTROY(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object);
SV* crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_toBytes(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object);
CK_RV crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_fromBytes(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_iv(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_iv(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_pData(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_pData(Crypt__PKCS11__CK_CAMELLIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);

typedef struct Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS {
    CK_ARIA_CBC_ENCRYPT_DATA_PARAMS private;
} Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS;
Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* crypt_pkcs11_ck_aria_cbc_encrypt_data_params_new(const char* class);
void crypt_pkcs11_ck_aria_cbc_encrypt_data_params_DESTROY(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object);
SV* crypt_pkcs11_ck_aria_cbc_encrypt_data_params_toBytes(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object);
CK_RV crypt_pkcs11_ck_aria_cbc_encrypt_data_params_fromBytes(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_iv(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_iv(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_pData(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);
CK_RV crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_pData(Crypt__PKCS11__CK_ARIA_CBC_ENCRYPT_DATA_PARAMS* object, SV* sv);

