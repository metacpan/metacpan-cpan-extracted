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

#include "crypt_pkcs11.h"

MODULE = Crypt::PKCS11::XS  PACKAGE = Crypt::PKCS11::XS  PREFIX = crypt_pkcs11_xs_

PROTOTYPES: ENABLE

Crypt::PKCS11::XS*
crypt_pkcs11_xs_new(class)
    const char* class
PROTOTYPE: $
OUTPUT:
    RETVAL

const char*
crypt_pkcs11_xs_rv2str(rv)
    CK_RV rv
PROTOTYPE: $
OUTPUT:
    RETVAL

int
crypt_pkcs11_xs_SvUOK(sv)
    SV* sv
PROTOTYPE: $
OUTPUT:
    RETVAL

int
crypt_pkcs11_xs_SvIOK(sv)
    SV* sv
PROTOTYPE: $
OUTPUT:
    RETVAL

void
crypt_pkcs11_xs_setCreateMutex(pCreateMutex)
    SV* pCreateMutex
PROTOTYPE: $

void
crypt_pkcs11_xs_clearCreateMutex()
PROTOTYPE: DISABLE

void
crypt_pkcs11_xs_setDestroyMutex(pDestroyMutex)
    SV* pDestroyMutex
PROTOTYPE: $

void
crypt_pkcs11_xs_clearDestroyMutex()
PROTOTYPE: DISABLE

void
crypt_pkcs11_xs_setLockMutex(pLockMutex)
    SV* pLockMutex
PROTOTYPE: $

void
crypt_pkcs11_xs_clearLockMutex()
PROTOTYPE: DISABLE

void
crypt_pkcs11_xs_setUnlockMutex(pUnlockMutex)
    SV* pUnlockMutex
PROTOTYPE: $

void
crypt_pkcs11_xs_clearUnlockMutex()
PROTOTYPE: DISABLE

MODULE = Crypt::PKCS11::XS  PACKAGE = Crypt::PKCS11::XSPtr  PREFIX = crypt_pkcs11_xs_

PROTOTYPES: ENABLE

CK_RV
crypt_pkcs11_xs_load(object, path)
    Crypt::PKCS11::XS* object
    const char* path
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_unload(object)
    Crypt::PKCS11::XS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

void
crypt_pkcs11_xs_DESTROY(object)
    Crypt::PKCS11::XS* object
PROTOTYPE: $

CK_RV
crypt_pkcs11_xs_C_Initialize(object, pInitArgs)
    Crypt::PKCS11::XS* object
    HV* pInitArgs
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Finalize(object)
    Crypt::PKCS11::XS* object
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetInfo(object, pInfo)
    Crypt::PKCS11::XS* object
    HV* pInfo
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetSlotList(object, tokenPresent, pSlotList)
    Crypt::PKCS11::XS* object
    CK_BBOOL tokenPresent
    AV* pSlotList
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetSlotInfo(object, slotID, pInfo)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    HV* pInfo
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetTokenInfo(object, slotID, pInfo)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    HV* pInfo
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetMechanismList(object, slotID, pMechanismList)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    AV* pMechanismList
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetMechanismInfo(object, slotID, type, pInfo)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    CK_MECHANISM_TYPE type
    HV* pInfo
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_InitToken(object, slotID, pPin, pLabel)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    SV* pPin
    SV* pLabel
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_InitPIN(object, hSession, pPin)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPin
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_SetPIN(object, hSession, pOldPin, pNewPin)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pOldPin
    SV* pNewPin
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_OpenSession(object, slotID, flags, Notify, phSession)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
    CK_FLAGS flags
    SV* Notify
    SV* phSession
PROTOTYPE: $$$$$
OUTPUT:
    RETVAL
    phSession

CK_RV
crypt_pkcs11_xs_C_CloseSession(object, hSession)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_CloseAllSessions(object, slotID)
    Crypt::PKCS11::XS* object
    CK_SLOT_ID slotID
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetSessionInfo(object, hSession, pInfo)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pInfo
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetOperationState(object, hSession, pOperationState)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pOperationState
PROTOTYPE: $$$
OUTPUT:
    RETVAL
    pOperationState

CK_RV
crypt_pkcs11_xs_C_SetOperationState(object, hSession, pOperationState, hEncryptionKey, hAuthenticationKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pOperationState
    CK_OBJECT_HANDLE hEncryptionKey
    CK_OBJECT_HANDLE hAuthenticationKey
PROTOTYPE: $$$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Login(object, hSession, userType, pPin)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_USER_TYPE userType
    SV* pPin
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Logout(object, hSession)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_CreateObject(object, hSession, pTemplate, phObject)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    AV* pTemplate
    SV* phObject
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    phObject

CK_RV
crypt_pkcs11_xs_C_CopyObject(object, hSession, hObject, pTemplate, phNewObject)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hObject
    AV* pTemplate
    SV* phNewObject
PROTOTYPE: $$$$$
OUTPUT:
    RETVAL
    phNewObject

CK_RV
crypt_pkcs11_xs_C_DestroyObject(object, hSession, hObject)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hObject
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GetObjectSize(object, hSession, hObject, pulSize)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hObject
    SV* pulSize
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pulSize

CK_RV
crypt_pkcs11_xs_C_GetAttributeValue(object, hSession, hObject, pTemplate)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hObject
    AV* pTemplate
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_SetAttributeValue(object, hSession, hObject, pTemplate)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hObject
    AV* pTemplate
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_FindObjectsInit(object, hSession, pTemplate)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    AV* pTemplate
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_FindObjects(object, hSession, phObject, ulMaxObjectCount)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    AV* phObject
    CK_ULONG ulMaxObjectCount
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_FindObjectsFinal(object, hSession)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_EncryptInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Encrypt(object, hSession, pData, pEncryptedData)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pData
    SV* pEncryptedData
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pEncryptedData

CK_RV
crypt_pkcs11_xs_C_EncryptUpdate(object, hSession, pPart, pEncryptedPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
    SV* pEncryptedPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pEncryptedPart

CK_RV
crypt_pkcs11_xs_C_EncryptFinal(object, hSession, pLastEncryptedPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pLastEncryptedPart
PROTOTYPE: $$$
OUTPUT:
    RETVAL
    pLastEncryptedPart

CK_RV
crypt_pkcs11_xs_C_DecryptInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Decrypt(object, hSession, pEncryptedData, pData)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pEncryptedData
    SV* pData
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pData

CK_RV
crypt_pkcs11_xs_C_DecryptUpdate(object, hSession, pEncryptedPart, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pEncryptedPart
    SV* pPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pPart

CK_RV
crypt_pkcs11_xs_C_DecryptFinal(object, hSession, pLastPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pLastPart
PROTOTYPE: $$$
OUTPUT:
    RETVAL
    pLastPart

CK_RV
crypt_pkcs11_xs_C_DigestInit(object, hSession, pMechanism)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Digest(object, hSession, pData, pDigest)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pData
    SV* pDigest
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pDigest

CK_RV
crypt_pkcs11_xs_C_DigestUpdate(object, hSession, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_DigestKey(object, hSession, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_DigestFinal(object, hSession, pDigest)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pDigest
PROTOTYPE: $$$
OUTPUT:
    RETVAL
    pDigest

CK_RV
crypt_pkcs11_xs_C_SignInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Sign(object, hSession, pData, pSignature)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pData
    SV* pSignature
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pSignature

CK_RV
crypt_pkcs11_xs_C_SignUpdate(object, hSession, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_SignFinal(object, hSession, pSignature)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pSignature
PROTOTYPE: $$$
OUTPUT:
    RETVAL
    pSignature

CK_RV
crypt_pkcs11_xs_C_SignRecoverInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_SignRecover(object, hSession, pData, pSignature)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pData
    SV* pSignature
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pSignature

CK_RV
crypt_pkcs11_xs_C_VerifyInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_Verify(object, hSession, pData, pSignature)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pData
    SV* pSignature
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pSignature

CK_RV
crypt_pkcs11_xs_C_VerifyUpdate(object, hSession, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_VerifyFinal(object, hSession, pSignature)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pSignature
PROTOTYPE: $
OUTPUT:
    RETVAL
    pSignature

CK_RV
crypt_pkcs11_xs_C_VerifyRecoverInit(object, hSession, pMechanism, hKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hKey
PROTOTYPE: $$$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_VerifyRecover(object, hSession, pSignature, pData)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pSignature
    SV* pData
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pData

CK_RV
crypt_pkcs11_xs_C_DigestEncryptUpdate(object, hSession, pPart, pEncryptedPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
    SV* pEncryptedPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pEncryptedPart

CK_RV
crypt_pkcs11_xs_C_DecryptDigestUpdate(object, hSession, pEncryptedPart, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pEncryptedPart
    SV* pPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pPart

CK_RV
crypt_pkcs11_xs_C_SignEncryptUpdate(object, hSession, pPart, pEncryptedPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pPart
    SV* pEncryptedPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pEncryptedPart

CK_RV
crypt_pkcs11_xs_C_DecryptVerifyUpdate(object, hSession, pEncryptedPart, pPart)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pEncryptedPart
    SV* pPart
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    pPart

CK_RV
crypt_pkcs11_xs_C_GenerateKey(object, hSession, pMechanism, pTemplate, phKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    AV* pTemplate
    SV* phKey
PROTOTYPE: $$$$$
OUTPUT:
    RETVAL
    phKey

CK_RV
crypt_pkcs11_xs_C_GenerateKeyPair(object, hSession, pMechanism, pPublicKeyTemplate, pPrivateKeyTemplate, phPublicKey, phPrivateKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    AV* pPublicKeyTemplate
    AV* pPrivateKeyTemplate
    SV* phPublicKey
    SV* phPrivateKey
PROTOTYPE: $$$$$$$
OUTPUT:
    RETVAL
    phPublicKey
    phPrivateKey

CK_RV
crypt_pkcs11_xs_C_WrapKey(object, hSession, pMechanism, hWrappingKey, hKey, pWrappedKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hWrappingKey
    CK_OBJECT_HANDLE hKey
    SV* pWrappedKey
PROTOTYPE: $$$$$$
OUTPUT:
    RETVAL
    pWrappedKey

CK_RV
crypt_pkcs11_xs_C_UnwrapKey(object, hSession, pMechanism, hUnwrappingKey, pWrappedKey, pTemplate, phKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hUnwrappingKey
    SV* pWrappedKey
    AV* pTemplate
    SV* phKey
PROTOTYPE: $$$$$$$
OUTPUT:
    RETVAL
    phKey

CK_RV
crypt_pkcs11_xs_C_DeriveKey(object, hSession, pMechanism, hBaseKey, pTemplate, phKey)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    HV* pMechanism
    CK_OBJECT_HANDLE hBaseKey
    AV* pTemplate
    SV* phKey
PROTOTYPE: $$$$$$
OUTPUT:
    RETVAL
    phKey

CK_RV
crypt_pkcs11_xs_C_SeedRandom(object, hSession, pSeed)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* pSeed
PROTOTYPE: $$$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_GenerateRandom(object, hSession, RandomData, ulRandomLen)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
    SV* RandomData
    CK_ULONG ulRandomLen
PROTOTYPE: $$$$
OUTPUT:
    RETVAL
    RandomData

CK_RV
crypt_pkcs11_xs_C_GetFunctionStatus(object, hSession)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
PROTOTYPE: $$
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_CancelFunction(object, hSession)
    Crypt::PKCS11::XS* object
    CK_SESSION_HANDLE hSession
PROTOTYPE: $
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_C_WaitForSlotEvent(object, flags, pSlot)
    Crypt::PKCS11::XS* object
    CK_FLAGS flags
    SV* pSlot
PROTOTYPE: $
OUTPUT:
    RETVAL
    pSlot

#ifdef TEST_DEVEL_COVER

int
crypt_pkcs11_xs_test_devel_cover(object)
    Crypt::PKCS11::XS* object
PROTOTYPE: DISABLE
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_test_devel_cover_check_pTemplate(pTemplate, allow_undef_pValue)
    AV* pTemplate
    int allow_undef_pValue
PROTOTYPE: DISABLE
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_test_devel_cover_create_CK_ATTRIBUTE(pTemplate, count, allow_undef_pValue)
    AV* pTemplate
    CK_ULONG count
    int allow_undef_pValue
PROTOTYPE: DISABLE
OUTPUT:
    RETVAL

CK_RV
crypt_pkcs11_xs_test_devel_cover_action_init(pMechanism)
    HV* pMechanism
PROTOTYPE: DISABLE
OUTPUT:
    RETVAL

#endif

MODULE = Crypt::PKCS11  PACKAGE = Crypt::PKCS11  PREFIX = crypt_pkcs11_

PROTOTYPES: ENABLE

BOOT:
{
    HV* stash = gv_stashpv("Crypt::PKCS11", TRUE);
    newCONSTSUB(stash, "CK_ULONG_SIZE", newSVuv(sizeof(CK_ULONG)));
}
