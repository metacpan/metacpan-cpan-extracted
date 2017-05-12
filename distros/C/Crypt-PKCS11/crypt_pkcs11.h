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

typedef struct crypt_pkcs11_xs_object Crypt__PKCS11__XS;

struct crypt_pkcs11_xs_object {
    void* handle;
    CK_FUNCTION_LIST_PTR function_list;
    CK_INFO info;
};

Crypt__PKCS11__XS* crypt_pkcs11_xs_new(const char* class);
const char* crypt_pkcs11_xs_rv2str(CK_RV rv);
int crypt_pkcs11_xs_SvUOK(SV* sv);
int crypt_pkcs11_xs_SvIOK(SV* sv);
void crypt_pkcs11_xs_setCreateMutex(SV* pCreateMutex);
void crypt_pkcs11_xs_clearCreateMutex(void);
void crypt_pkcs11_xs_setDestroyMutex(SV* pDestroyMutex);
void crypt_pkcs11_xs_clearDestroyMutex(void);
void crypt_pkcs11_xs_setLockMutex(SV* pLockMutex);
void crypt_pkcs11_xs_clearLockMutex(void);
void crypt_pkcs11_xs_setUnlockMutex(SV* pUnlockMutex);
void crypt_pkcs11_xs_clearUnlockMutex(void);

void crypt_pkcs11_xs_DESTROY(Crypt__PKCS11__XS* object);

CK_RV crypt_pkcs11_xs_load(Crypt__PKCS11__XS* object, const char* path);
CK_RV crypt_pkcs11_xs_unload(Crypt__PKCS11__XS* object);

CK_RV crypt_pkcs11_xs_C_Initialize(Crypt__PKCS11__XS* object, HV* pInitArgs);
CK_RV crypt_pkcs11_xs_C_Finalize(Crypt__PKCS11__XS* object);
CK_RV crypt_pkcs11_xs_C_GetInfo(Crypt__PKCS11__XS* object, HV* pInfo);
CK_RV crypt_pkcs11_xs_C_GetSlotList(Crypt__PKCS11__XS* object, CK_BBOOL tokenPresent, AV* pSlotList);
CK_RV crypt_pkcs11_xs_C_GetSlotInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, HV* pInfo);
CK_RV crypt_pkcs11_xs_C_GetTokenInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, HV* pInfo);
CK_RV crypt_pkcs11_xs_C_GetMechanismList(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, AV* pMechanismList);
CK_RV crypt_pkcs11_xs_C_GetMechanismInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, CK_MECHANISM_TYPE type, HV* pInfo);
CK_RV crypt_pkcs11_xs_C_InitToken(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, SV* pPin, SV* pLabel);
CK_RV crypt_pkcs11_xs_C_InitPIN(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPin);
CK_RV crypt_pkcs11_xs_C_SetPIN(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOldPin, SV* pNewPin);
CK_RV crypt_pkcs11_xs_C_OpenSession(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, CK_FLAGS flags, SV* Notify, SV* phSession);
CK_RV crypt_pkcs11_xs_C_CloseSession(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession);
CK_RV crypt_pkcs11_xs_C_CloseAllSessions(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID);
CK_RV crypt_pkcs11_xs_C_GetSessionInfo(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pInfo);
CK_RV crypt_pkcs11_xs_C_GetOperationState(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOperationState);
CK_RV crypt_pkcs11_xs_C_SetOperationState(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOperationState, CK_OBJECT_HANDLE hEncryptionKey, CK_OBJECT_HANDLE hAuthenticationKey);
CK_RV crypt_pkcs11_xs_C_Login(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_USER_TYPE userType, SV* pPin);
CK_RV crypt_pkcs11_xs_C_Logout(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession);
CK_RV crypt_pkcs11_xs_C_CreateObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* pTemplate, SV* phObject);
CK_RV crypt_pkcs11_xs_C_CopyObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate, SV* phNewObject);
CK_RV crypt_pkcs11_xs_C_DestroyObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject);
CK_RV crypt_pkcs11_xs_C_GetObjectSize(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, SV* pulSize);
CK_RV crypt_pkcs11_xs_C_GetAttributeValue(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate);
CK_RV crypt_pkcs11_xs_C_SetAttributeValue(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate);
CK_RV crypt_pkcs11_xs_C_FindObjectsInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* pTemplate);
CK_RV crypt_pkcs11_xs_C_FindObjects(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* phObject, CK_ULONG ulMaxObjectCount);
CK_RV crypt_pkcs11_xs_C_FindObjectsFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession);
CK_RV crypt_pkcs11_xs_C_EncryptInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_Encrypt(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pEncryptedData);
CK_RV crypt_pkcs11_xs_C_EncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart);
CK_RV crypt_pkcs11_xs_C_EncryptFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pLastEncryptedPart);
CK_RV crypt_pkcs11_xs_C_DecryptInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_Decrypt(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedData, SV* pData);
CK_RV crypt_pkcs11_xs_C_DecryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart);
CK_RV crypt_pkcs11_xs_C_DecryptFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pLastPart);
CK_RV crypt_pkcs11_xs_C_DigestInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism);
CK_RV crypt_pkcs11_xs_C_Digest(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pDigest);
CK_RV crypt_pkcs11_xs_C_DigestUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart);
CK_RV crypt_pkcs11_xs_C_DigestKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_DigestFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pDigest);
CK_RV crypt_pkcs11_xs_C_SignInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_Sign(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature);
CK_RV crypt_pkcs11_xs_C_SignUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart);
CK_RV crypt_pkcs11_xs_C_SignFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature);
CK_RV crypt_pkcs11_xs_C_SignRecoverInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_SignRecover(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature);
CK_RV crypt_pkcs11_xs_C_VerifyInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_Verify(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature);
CK_RV crypt_pkcs11_xs_C_VerifyUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart);
CK_RV crypt_pkcs11_xs_C_VerifyFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature);
CK_RV crypt_pkcs11_xs_C_VerifyRecoverInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey);
CK_RV crypt_pkcs11_xs_C_VerifyRecover(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature, SV* pData);
CK_RV crypt_pkcs11_xs_C_DigestEncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart);
CK_RV crypt_pkcs11_xs_C_DecryptDigestUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart);
CK_RV crypt_pkcs11_xs_C_SignEncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart);
CK_RV crypt_pkcs11_xs_C_DecryptVerifyUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart);
CK_RV crypt_pkcs11_xs_C_GenerateKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, AV* pTemplate, SV* phKey);
CK_RV crypt_pkcs11_xs_C_GenerateKeyPair(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, AV* pPublicKeyTemplate, AV* pPrivateKeyTemplate, SV* phPublicKey, SV* phPrivateKey);
CK_RV crypt_pkcs11_xs_C_WrapKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hWrappingKey, CK_OBJECT_HANDLE hKey, SV* pWrappedKey);
CK_RV crypt_pkcs11_xs_C_UnwrapKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hUnwrappingKey, SV* pWrappedKey, AV* pTemplate, SV* phKey);
CK_RV crypt_pkcs11_xs_C_DeriveKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hBaseKey, AV* pTemplate, SV* phKey);
CK_RV crypt_pkcs11_xs_C_SeedRandom(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSeed);
CK_RV crypt_pkcs11_xs_C_GenerateRandom(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* RandomData, CK_ULONG ulRandomLen);
CK_RV crypt_pkcs11_xs_C_GetFunctionStatus(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession);
CK_RV crypt_pkcs11_xs_C_CancelFunction(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession);
CK_RV crypt_pkcs11_xs_C_WaitForSlotEvent(Crypt__PKCS11__XS* object, CK_FLAGS flags, SV* pSlot);
#ifdef TEST_DEVEL_COVER
int crypt_pkcs11_xs_test_devel_cover(Crypt__PKCS11__XS* object);
CK_RV crypt_pkcs11_xs_test_devel_cover_check_pTemplate(AV* pTemplate, int allow_undef_pValue);
CK_RV crypt_pkcs11_xs_test_devel_cover_create_CK_ATTRIBUTE(AV* pTemplate, CK_ULONG count, int allow_undef_pValue);
CK_RV crypt_pkcs11_xs_test_devel_cover_action_init(HV* pMechanism);
#endif
