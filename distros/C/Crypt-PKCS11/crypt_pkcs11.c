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

#include <stdlib.h>
#include <string.h>
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif

static const char __CreateMutex_str[] = "CreateMutex";
static const char __DestroyMutex_str[] = "DestroyMutex";
static const char __LockMutex_str[] = "LockMutex";
static const char __UnlockMutex_str[] = "UnlockMutex";
static const char __flags_str[] = "flags";
static const char __major_str[] = "major";
static const char __minor_str[] = "minor";
static const char __cryptokiVersion_str[] = "cryptokiVersion";
static const char __manufacturerID_str[] = "manufacturerID";
static const char __libraryDescription_str[] = "libraryDescription";
static const char __libraryVersion_str[] = "libraryVersion";
static const char __slotDescription_str[] = "slotDescription";
static const char __hardwareVersion_str[] = "hardwareVersion";
static const char __firmwareVersion_str[] = "firmwareVersion";
static const char __label_str[] = "label";
static const char __model_str[] = "model";
static const char __serialNumber_str[] = "serialNumber";
static const char __ulMaxSessionCount_str[] = "ulMaxSessionCount";
static const char __ulSessionCount_str[] = "ulSessionCount";
static const char __ulMaxRwSessionCount_str[] = "ulMaxRwSessionCount";
static const char __ulRwSessionCount_str[] = "ulRwSessionCount";
static const char __ulMaxPinLen_str[] = "ulMaxPinLen";
static const char __ulMinPinLen_str[] = "ulMinPinLen";
static const char __ulTotalPublicMemory_str[] = "ulTotalPublicMemory";
static const char __ulFreePublicMemory_str[] = "ulFreePublicMemory";
static const char __ulTotalPrivateMemory_str[] = "ulTotalPrivateMemory";
static const char __ulFreePrivateMemory_str[] = "ulFreePrivateMemory";
static const char __utcTime_str[] = "utcTime";
static const char __ulMaxKeySize_str[] = "ulMaxKeySize";
static const char __ulMinKeySize_str[] = "ulMinKeySize";
static const char __slotID_str[] = "slotID";
static const char __state_str[] = "state";
static const char __ulDeviceError_str[] = "ulDeviceError";
static const char __type_str[] = "type";
static const char __pValue_str[] = "pValue";
static const char __ulValueLen_str[] = "ulValueLen";
static const char __mechanism_str[] = "mechanism";
static const char __pParameter_str[] = "pParameter";

Crypt__PKCS11__XS* crypt_pkcs11_xs_new(const char* class) {
    Crypt__PKCS11__XS* object = 0;
    Newxz(object, 1, Crypt__PKCS11__XS);

    /* uncoverable branch 0 */
    if (!object) {
        /* uncoverable block 0 */
        croak("Memory allocation error");
    }

    return object;
}

const char* crypt_pkcs11_xs_rv2str(CK_RV rv) {
    const char* str;

    switch (rv) {
    case CKR_OK:
        str = "CKR_OK";
        break;
    case CKR_CANCEL:
        str = "CKR_CANCEL";
        break;
    case CKR_HOST_MEMORY:
        str = "CKR_HOST_MEMORY";
        break;
    case CKR_SLOT_ID_INVALID:
        str = "CKR_SLOT_ID_INVALID";
        break;
    case CKR_GENERAL_ERROR:
        str = "CKR_GENERAL_ERROR";
        break;
    case CKR_FUNCTION_FAILED:
        str = "CKR_FUNCTION_FAILED";
        break;
    case CKR_ARGUMENTS_BAD:
        str = "CKR_ARGUMENTS_BAD";
        break;
    case CKR_NO_EVENT:
        str = "CKR_NO_EVENT";
        break;
    case CKR_NEED_TO_CREATE_THREADS:
        str = "CKR_NEED_TO_CREATE_THREADS";
        break;
    case CKR_CANT_LOCK:
        str = "CKR_CANT_LOCK";
        break;
    case CKR_ATTRIBUTE_READ_ONLY:
        str = "CKR_ATTRIBUTE_READ_ONLY";
        break;
    case CKR_ATTRIBUTE_SENSITIVE:
        str = "CKR_ATTRIBUTE_SENSITIVE";
        break;
    case CKR_ATTRIBUTE_TYPE_INVALID:
        str = "CKR_ATTRIBUTE_TYPE_INVALID";
        break;
    case CKR_ATTRIBUTE_VALUE_INVALID:
        str = "CKR_ATTRIBUTE_VALUE_INVALID";
        break;
    case CKR_DATA_INVALID:
        str = "CKR_DATA_INVALID";
        break;
    case CKR_DATA_LEN_RANGE:
        str = "CKR_DATA_LEN_RANGE";
        break;
    case CKR_DEVICE_ERROR:
        str = "CKR_DEVICE_ERROR";
        break;
    case CKR_DEVICE_MEMORY:
        str = "CKR_DEVICE_MEMORY";
        break;
    case CKR_DEVICE_REMOVED:
        str = "CKR_DEVICE_REMOVED";
        break;
    case CKR_ENCRYPTED_DATA_INVALID:
        str = "CKR_ENCRYPTED_DATA_INVALID";
        break;
    case CKR_ENCRYPTED_DATA_LEN_RANGE:
        str = "CKR_ENCRYPTED_DATA_LEN_RANGE";
        break;
    case CKR_FUNCTION_CANCELED:
        str = "CKR_FUNCTION_CANCELED";
        break;
    case CKR_FUNCTION_NOT_PARALLEL:
        str = "CKR_FUNCTION_NOT_PARALLEL";
        break;
    case CKR_FUNCTION_NOT_SUPPORTED:
        str = "CKR_FUNCTION_NOT_SUPPORTED";
        break;
    case CKR_KEY_HANDLE_INVALID:
        str = "CKR_KEY_HANDLE_INVALID";
        break;
    case CKR_KEY_SIZE_RANGE:
        str = "CKR_KEY_SIZE_RANGE";
        break;
    case CKR_KEY_TYPE_INCONSISTENT:
        str = "CKR_KEY_TYPE_INCONSISTENT";
        break;
    case CKR_KEY_NOT_NEEDED:
        str = "CKR_KEY_NOT_NEEDED";
        break;
    case CKR_KEY_CHANGED:
        str = "CKR_KEY_CHANGED";
        break;
    case CKR_KEY_NEEDED:
        str = "CKR_KEY_NEEDED";
        break;
    case CKR_KEY_INDIGESTIBLE:
        str = "CKR_KEY_INDIGESTIBLE";
        break;
    case CKR_KEY_FUNCTION_NOT_PERMITTED:
        str = "CKR_KEY_FUNCTION_NOT_PERMITTED";
        break;
    case CKR_KEY_NOT_WRAPPABLE:
        str = "CKR_KEY_NOT_WRAPPABLE";
        break;
    case CKR_KEY_UNEXTRACTABLE:
        str = "CKR_KEY_UNEXTRACTABLE";
        break;
    case CKR_MECHANISM_INVALID:
        str = "CKR_MECHANISM_INVALID";
        break;
    case CKR_MECHANISM_PARAM_INVALID:
        str = "CKR_MECHANISM_PARAM_INVALID";
        break;
    case CKR_OBJECT_HANDLE_INVALID:
        str = "CKR_OBJECT_HANDLE_INVALID";
        break;
    case CKR_OPERATION_ACTIVE:
        str = "CKR_OPERATION_ACTIVE";
        break;
    case CKR_OPERATION_NOT_INITIALIZED:
        str = "CKR_OPERATION_NOT_INITIALIZED";
        break;
    case CKR_PIN_INCORRECT:
        str = "CKR_PIN_INCORRECT";
        break;
    case CKR_PIN_INVALID:
        str = "CKR_PIN_INVALID";
        break;
    case CKR_PIN_LEN_RANGE:
        str = "CKR_PIN_LEN_RANGE";
        break;
    case CKR_PIN_EXPIRED:
        str = "CKR_PIN_EXPIRED";
        break;
    case CKR_PIN_LOCKED:
        str = "CKR_PIN_LOCKED";
        break;
    case CKR_SESSION_CLOSED:
        str = "CKR_SESSION_CLOSED";
        break;
    case CKR_SESSION_COUNT:
        str = "CKR_SESSION_COUNT";
        break;
    case CKR_SESSION_HANDLE_INVALID:
        str = "CKR_SESSION_HANDLE_INVALID";
        break;
    case CKR_SESSION_PARALLEL_NOT_SUPPORTED:
        str = "CKR_SESSION_PARALLEL_NOT_SUPPORTED";
        break;
    case CKR_SESSION_READ_ONLY:
        str = "CKR_SESSION_READ_ONLY";
        break;
    case CKR_SESSION_EXISTS:
        str = "CKR_SESSION_EXISTS";
        break;
    case CKR_SESSION_READ_ONLY_EXISTS:
        str = "CKR_SESSION_READ_ONLY_EXISTS";
        break;
    case CKR_SESSION_READ_WRITE_SO_EXISTS:
        str = "CKR_SESSION_READ_WRITE_SO_EXISTS";
        break;
    case CKR_SIGNATURE_INVALID:
        str = "CKR_SIGNATURE_INVALID";
        break;
    case CKR_SIGNATURE_LEN_RANGE:
        str = "CKR_SIGNATURE_LEN_RANGE";
        break;
    case CKR_TEMPLATE_INCOMPLETE:
        str = "CKR_TEMPLATE_INCOMPLETE";
        break;
    case CKR_TEMPLATE_INCONSISTENT:
        str = "CKR_TEMPLATE_INCONSISTENT";
        break;
    case CKR_TOKEN_NOT_PRESENT:
        str = "CKR_TOKEN_NOT_PRESENT";
        break;
    case CKR_TOKEN_NOT_RECOGNIZED:
        str = "CKR_TOKEN_NOT_RECOGNIZED";
        break;
    case CKR_TOKEN_WRITE_PROTECTED:
        str = "CKR_TOKEN_WRITE_PROTECTED";
        break;
    case CKR_UNWRAPPING_KEY_HANDLE_INVALID:
        str = "CKR_UNWRAPPING_KEY_HANDLE_INVALID";
        break;
    case CKR_UNWRAPPING_KEY_SIZE_RANGE:
        str = "CKR_UNWRAPPING_KEY_SIZE_RANGE";
        break;
    case CKR_UNWRAPPING_KEY_TYPE_INCONSISTENT:
        str = "CKR_UNWRAPPING_KEY_TYPE_INCONSISTENT";
        break;
    case CKR_USER_ALREADY_LOGGED_IN:
        str = "CKR_USER_ALREADY_LOGGED_IN";
        break;
    case CKR_USER_NOT_LOGGED_IN:
        str = "CKR_USER_NOT_LOGGED_IN";
        break;
    case CKR_USER_PIN_NOT_INITIALIZED:
        str = "CKR_USER_PIN_NOT_INITIALIZED";
        break;
    case CKR_USER_TYPE_INVALID:
        str = "CKR_USER_TYPE_INVALID";
        break;
    case CKR_USER_ANOTHER_ALREADY_LOGGED_IN:
        str = "CKR_USER_ANOTHER_ALREADY_LOGGED_IN";
        break;
    case CKR_USER_TOO_MANY_TYPES:
        str = "CKR_USER_TOO_MANY_TYPES";
        break;
    case CKR_WRAPPED_KEY_INVALID:
        str = "CKR_WRAPPED_KEY_INVALID";
        break;
    case CKR_WRAPPED_KEY_LEN_RANGE:
        str = "CKR_WRAPPED_KEY_LEN_RANGE";
        break;
    case CKR_WRAPPING_KEY_HANDLE_INVALID:
        str = "CKR_WRAPPING_KEY_HANDLE_INVALID";
        break;
    case CKR_WRAPPING_KEY_SIZE_RANGE:
        str = "CKR_WRAPPING_KEY_SIZE_RANGE";
        break;
    case CKR_WRAPPING_KEY_TYPE_INCONSISTENT:
        str = "CKR_WRAPPING_KEY_TYPE_INCONSISTENT";
        break;
    case CKR_RANDOM_SEED_NOT_SUPPORTED:
        str = "CKR_RANDOM_SEED_NOT_SUPPORTED";
        break;
    case CKR_RANDOM_NO_RNG:
        str = "CKR_RANDOM_NO_RNG";
        break;
    case CKR_DOMAIN_PARAMS_INVALID:
        str = "CKR_DOMAIN_PARAMS_INVALID";
        break;
    case CKR_BUFFER_TOO_SMALL:
        str = "CKR_BUFFER_TOO_SMALL";
        break;
    case CKR_SAVED_STATE_INVALID:
        str = "CKR_SAVED_STATE_INVALID";
        break;
    case CKR_INFORMATION_SENSITIVE:
        str = "CKR_INFORMATION_SENSITIVE";
        break;
    case CKR_STATE_UNSAVEABLE:
        str = "CKR_STATE_UNSAVEABLE";
        break;
    case CKR_CRYPTOKI_NOT_INITIALIZED:
        str = "CKR_CRYPTOKI_NOT_INITIALIZED";
        break;
    case CKR_CRYPTOKI_ALREADY_INITIALIZED:
        str = "CKR_CRYPTOKI_ALREADY_INITIALIZED";
        break;
    case CKR_MUTEX_BAD:
        str = "CKR_MUTEX_BAD";
        break;
    case CKR_MUTEX_NOT_LOCKED:
        str = "CKR_MUTEX_NOT_LOCKED";
        break;
    case CKR_NEW_PIN_MODE:
        str = "CKR_NEW_PIN_MODE";
        break;
    case CKR_NEXT_OTP:
        str = "CKR_NEXT_OTP";
        break;
    case CKR_FUNCTION_REJECTED:
        str = "CKR_FUNCTION_REJECTED";
        break;
    case CKR_VENDOR_DEFINED:
        str = "CKR_VENDOR_DEFINED";
        break;
    default:
        str = "UNKNOWN_ERROR";
    }

    return str;
}

int crypt_pkcs11_xs_SvUOK(SV* sv) {
    if (!sv) {
        return 0;
    }

    SvGETMAGIC(sv);

    if (SvIOK(sv)) {
        /* uncoverable branch 1 */
        return SvIV(sv) < 0 ? 0 : 1;
    }

    return SvUOK(sv) ? 1 : 0;
}

int crypt_pkcs11_xs_SvIOK(SV* sv) {
    if (!sv) {
        return 0;
    }

    SvGETMAGIC(sv);

    return SvIOK(sv) ? 1 : 0;
}

/* TODO:
 * Change Mutex design to incapsulate an object that refers to the CODE
 * references and mutex data to allow for per PKCS11 object mutex callbacks.
 * Also store them in the PKCS11 object for cleanup.
 */

void crypt_pkcs11_xs_setCreateMutex(SV* pCreateMutex) {
    croak("Mutex functions are currently not supported");
}

void crypt_pkcs11_xs_clearCreateMutex(void) {
}

void crypt_pkcs11_xs_setDestroyMutex(SV* pDestroyMutex) {
    croak("Mutex functions are currently not supported");
}

void crypt_pkcs11_xs_clearDestroyMutex(void) {
}

void crypt_pkcs11_xs_setLockMutex(SV* pLockMutex) {
    croak("Mutex functions are currently not supported");
}

void crypt_pkcs11_xs_clearLockMutex(void) {
}

void crypt_pkcs11_xs_setUnlockMutex(SV* pUnlockMutex) {
    croak("Mutex functions are currently not supported");
}

void crypt_pkcs11_xs_clearUnlockMutex(void) {
}

#ifdef TEST_DEVEL_COVER
static CK_RV __test_C_GetFunctionList(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
static CK_RV __test_C_GetFunctionList_NO_FLIST(CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
#endif

CK_RV crypt_pkcs11_xs_load(Crypt__PKCS11__XS* object, const char* path) {
    CK_C_GetFunctionList pGetFunctionList = NULL_PTR;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (object->handle) {
        return CKR_GENERAL_ERROR;
    }
    if (object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!path) {
        return CKR_ARGUMENTS_BAD;
    }

#ifdef TEST_DEVEL_COVER
    if (!strcmp(path, "TEST_DEVEL_COVER")) {
        pGetFunctionList = &__test_C_GetFunctionList;
    }
    else if (!strcmp(path, "TEST_DEVEL_COVER_NO_FLIST")) {
        pGetFunctionList = &__test_C_GetFunctionList_NO_FLIST;
    }
    else {
#endif
#ifdef HAVE_DLFCN_H
    if (object->handle = dlopen(path, RTLD_NOW | RTLD_LOCAL)) {
        pGetFunctionList = (CK_C_GetFunctionList)dlsym(object->handle, "C_GetFunctionList");
    }
#else
    return CKR_FUNCTION_FAILED;
#endif
#ifdef TEST_DEVEL_COVER
    }
#endif

    if (pGetFunctionList) {
        /* uncoverable branch 2 */
        if ((rv = pGetFunctionList(&(object->function_list))) == CKR_OK) {
            return CKR_OK;
        }
        object->function_list = NULL_PTR;
        return rv;
    }

    return CKR_FUNCTION_FAILED;
}

CK_RV crypt_pkcs11_xs_unload(Crypt__PKCS11__XS* object) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->handle) {
        return CKR_GENERAL_ERROR;
    }

    crypt_pkcs11_xs_C_Finalize(object);

#ifdef HAVE_DLFCN_H
    /* uncoverable branch 1 */
    if (dlclose(object->handle)) {
        /* uncoverable block 0 */
        return CKR_FUNCTION_FAILED;
    }
#else
    return CKR_FUNCTION_FAILED;
#endif

    object->handle = NULL_PTR;
    object->function_list = NULL_PTR;
    Zero(&(object->info), 1, CK_INFO);

    return CKR_OK;
}

void crypt_pkcs11_xs_DESTROY(Crypt__PKCS11__XS* object) {
    if (object) {
        crypt_pkcs11_xs_unload(object);
        Safefree(object);
    }
}

CK_RV crypt_pkcs11_xs_C_Initialize(Crypt__PKCS11__XS* object, HV* pInitArgs) {
    CK_C_INITIALIZE_ARGS InitArgs = { NULL_PTR, NULL_PTR, NULL_PTR, NULL_PTR, 0, NULL_PTR };
    int useInitArgs = 0;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Initialize) {
        return CKR_GENERAL_ERROR;
    }

    if (pInitArgs) {
        /*
         * Fetch all hash values even if they may not exist.
         */
        SV** CreateMutex = hv_fetch(pInitArgs, __CreateMutex_str, sizeof(__CreateMutex_str)-1, 0);
        SV** DestroyMutex = hv_fetch(pInitArgs, __DestroyMutex_str, sizeof(__DestroyMutex_str)-1, 0);
        SV** LockMutex = hv_fetch(pInitArgs, __LockMutex_str, sizeof(__LockMutex_str)-1, 0);
        SV** UnlockMutex = hv_fetch(pInitArgs, __UnlockMutex_str, sizeof(__UnlockMutex_str)-1, 0);
        SV** flags = hv_fetch(pInitArgs, __flags_str, sizeof(__flags_str)-1, 0);

        /*
         * If any of the mutex callback exists, all must exist.
         */
        /* uncoverable begin */
        if (CreateMutex || DestroyMutex || LockMutex || UnlockMutex) {
            return CKR_ARGUMENTS_BAD;
            /* uncoverable end */
        }

        if (flags) {
            /* uncoverable begin */
            if (!*flags || !crypt_pkcs11_xs_SvUOK(*flags)) {
                return CKR_ARGUMENTS_BAD;
                /* uncoverable end */
            }

            InitArgs.flags = SvUV(*flags);

            useInitArgs = 1;
        }
    }

    return object->function_list->C_Initialize(useInitArgs ? &InitArgs : NULL_PTR);
}

CK_RV crypt_pkcs11_xs_C_Finalize(Crypt__PKCS11__XS* object) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Finalize) {
        return CKR_GENERAL_ERROR;
    }

    return object->function_list->C_Finalize(NULL_PTR);
}

CK_RV crypt_pkcs11_xs_C_GetInfo(Crypt__PKCS11__XS* object, HV* pInfo) {
    CK_INFO _pInfo = {
        { 0, 0 },
        "                                ",
        0,
        "                                ",
        { 0, 0 }
    };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetInfo) {
        return CKR_GENERAL_ERROR;
    }
    if (!pInfo) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = (object->function_list->C_GetInfo(&_pInfo))) == CKR_OK) {
        HV* cryptokiVersion = newHV();
        HV* libraryVersion = newHV();
        SV* manufacturerID;
        SV* libraryDescription;

        Copy(&_pInfo, &(object->info), 1, CK_INFO);

        hv_store(cryptokiVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.cryptokiVersion.major), 0);
        hv_store(cryptokiVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.cryptokiVersion.minor), 0);
        hv_store(pInfo, __cryptokiVersion_str, sizeof(__cryptokiVersion_str)-1, newRV_noinc((SV*)cryptokiVersion), 0);
        hv_store(pInfo, __manufacturerID_str, sizeof(__manufacturerID_str)-1, (manufacturerID = newSVpv((char*)_pInfo.manufacturerID,32)), 0);
        hv_store(pInfo, __flags_str, sizeof(__flags_str)-1, newSVuv(_pInfo.flags), 0);
        hv_store(pInfo, __libraryDescription_str, sizeof(__libraryDescription_str)-1, (libraryDescription = newSVpv((char*)_pInfo.libraryDescription,32)), 0);
        hv_store(libraryVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.libraryVersion.major), 0);
        hv_store(libraryVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.libraryVersion.minor), 0);
        hv_store(pInfo, __libraryVersion_str, sizeof(__libraryVersion_str)-1, newRV_noinc((SV*)libraryVersion), 0);

        sv_utf8_upgrade(manufacturerID);
        sv_utf8_upgrade(libraryDescription);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetSlotList(Crypt__PKCS11__XS* object, CK_BBOOL tokenPresent, AV* pSlotList) {
    CK_SLOT_ID_PTR _pSlotList = 0;
    CK_ULONG ulCount = 0, ulPos = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetSlotList) {
        return CKR_GENERAL_ERROR;
    }
    if (!pSlotList) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetSlotList(tokenPresent, NULL_PTR, &ulCount)) != CKR_OK) {
        return rv;
    }
    if (ulCount < 1) {
        return rv;
    }

    Newxz(_pSlotList, ulCount, CK_SLOT_ID);
    /* uncoverable branch 0 */
    if (!_pSlotList) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }
    if ((rv = object->function_list->C_GetSlotList(tokenPresent, _pSlotList, &ulCount)) != CKR_OK) {
        Safefree(_pSlotList);
        return rv;
    }

    for (ulPos = 0; ulPos < ulCount; ulPos++) {
        av_push(pSlotList, newSVuv(_pSlotList[ulPos]));
    }
    Safefree(_pSlotList);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetSlotInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, HV* pInfo) {
    CK_SLOT_INFO _pInfo = {
        "                                                                ",
        "                                ",
        0,
        { 0, 0 },
        { 0, 0 }
    };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetSlotInfo) {
        return CKR_GENERAL_ERROR;
    }
    if (!pInfo) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetSlotInfo(slotID, &_pInfo)) == CKR_OK) {
        HV* hardwareVersion = newHV();
        HV* firmwareVersion = newHV();
        SV* slotDescription;
        SV* manufacturerID;

        hv_store(pInfo, __slotDescription_str, sizeof(__slotDescription_str)-1, (slotDescription = newSVpv((char*)_pInfo.slotDescription,64)), 0);
        hv_store(pInfo, __manufacturerID_str, sizeof(__manufacturerID_str)-1, (manufacturerID = newSVpv((char*)_pInfo.manufacturerID,32)), 0);
        hv_store(pInfo, __flags_str, sizeof(__flags_str)-1, newSVuv(_pInfo.flags), 0);
        hv_store(hardwareVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.hardwareVersion.major), 0);
        hv_store(hardwareVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.hardwareVersion.minor), 0);
        hv_store(pInfo, __hardwareVersion_str, sizeof(__hardwareVersion_str)-1, newRV_noinc((SV*)hardwareVersion), 0);
        hv_store(firmwareVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.firmwareVersion.major), 0);
        hv_store(firmwareVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.firmwareVersion.minor), 0);
        hv_store(pInfo, __firmwareVersion_str, sizeof(__firmwareVersion_str)-1, newRV_noinc((SV*)firmwareVersion), 0);

        sv_utf8_upgrade(slotDescription);
        sv_utf8_upgrade(manufacturerID);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetTokenInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, HV* pInfo) {
    CK_TOKEN_INFO _pInfo = {
        "                                ",
        "                                ",
        "                ",
        "                ",
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        { 0, 0 },
        { 0, 0 },
        "                "
    };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetTokenInfo) {
        return CKR_GENERAL_ERROR;
    }
    if (!pInfo) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetTokenInfo(slotID, &_pInfo)) == CKR_OK) {
        HV* hardwareVersion = newHV();
        HV* firmwareVersion = newHV();
        SV* label;
        SV* manufacturerID;
        SV* model;
        SV* serialNumber;
        SV* utcTime;

        hv_store(pInfo, __label_str, sizeof(__label_str)-1, (label = newSVpv((char*)_pInfo.label,32)), 0);
        hv_store(pInfo, __manufacturerID_str, sizeof(__manufacturerID_str)-1, (manufacturerID = newSVpv((char*)_pInfo.manufacturerID,32)), 0);
        hv_store(pInfo, __model_str, sizeof(__model_str)-1, (model = newSVpv((char*)_pInfo.model,16)), 0);
        hv_store(pInfo, __serialNumber_str, sizeof(__serialNumber_str)-1, (serialNumber = newSVpv((char*)_pInfo.serialNumber,16)), 0);
        hv_store(pInfo, __flags_str, sizeof(__flags_str)-1, newSVuv(_pInfo.flags), 0);
        hv_store(pInfo, __ulMaxSessionCount_str, sizeof(__ulMaxSessionCount_str)-1, newSVuv(_pInfo.ulMaxSessionCount), 0);
        hv_store(pInfo, __ulSessionCount_str, sizeof(__ulSessionCount_str)-1, newSVuv(_pInfo.ulSessionCount), 0);
        hv_store(pInfo, __ulMaxRwSessionCount_str, sizeof(__ulMaxRwSessionCount_str)-1, newSVuv(_pInfo.ulMaxRwSessionCount), 0);
        hv_store(pInfo, __ulRwSessionCount_str, sizeof(__ulRwSessionCount_str)-1, newSVuv(_pInfo.ulRwSessionCount), 0);
        hv_store(pInfo, __ulMaxPinLen_str, sizeof(__ulMaxPinLen_str)-1, newSVuv(_pInfo.ulMaxPinLen), 0);
        hv_store(pInfo, __ulMinPinLen_str, sizeof(__ulMinPinLen_str)-1, newSVuv(_pInfo.ulMinPinLen), 0);
        hv_store(pInfo, __ulTotalPublicMemory_str, sizeof(__ulTotalPublicMemory_str)-1, newSVuv(_pInfo.ulTotalPublicMemory), 0);
        hv_store(pInfo, __ulFreePublicMemory_str, sizeof(__ulFreePublicMemory_str)-1, newSVuv(_pInfo.ulFreePublicMemory), 0);
        hv_store(pInfo, __ulTotalPrivateMemory_str, sizeof(__ulTotalPrivateMemory_str)-1, newSVuv(_pInfo.ulTotalPrivateMemory), 0);
        hv_store(pInfo, __ulFreePrivateMemory_str, sizeof(__ulFreePrivateMemory_str)-1, newSVuv(_pInfo.ulFreePrivateMemory), 0);
        hv_store(hardwareVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.hardwareVersion.major), 0);
        hv_store(hardwareVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.hardwareVersion.minor), 0);
        hv_store(pInfo, __hardwareVersion_str, sizeof(__hardwareVersion_str)-1, newRV_noinc((SV*)hardwareVersion), 0);
        hv_store(firmwareVersion, __major_str, sizeof(__major_str)-1, newSVuv(_pInfo.firmwareVersion.major), 0);
        hv_store(firmwareVersion, __minor_str, sizeof(__minor_str)-1, newSVuv(_pInfo.firmwareVersion.minor), 0);
        hv_store(pInfo, __firmwareVersion_str, sizeof(__firmwareVersion_str)-1, newRV_noinc((SV*)firmwareVersion), 0);
        hv_store(pInfo, __utcTime_str, sizeof(__utcTime_str)-1, (utcTime = newSVpv((char*)_pInfo.utcTime,16)), 0);

        sv_utf8_upgrade(label);
        sv_utf8_upgrade(manufacturerID);
        sv_utf8_upgrade(model);
        sv_utf8_upgrade(serialNumber);
        sv_utf8_upgrade(utcTime);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetMechanismList(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, AV* pMechanismList) {
    CK_MECHANISM_TYPE_PTR _pMechanismList = 0;
    CK_ULONG ulCount = 0, ulPos = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetMechanismList) {
        return CKR_GENERAL_ERROR;
    }
    if (!pMechanismList) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetMechanismList(slotID, NULL_PTR, &ulCount)) != CKR_OK) {
        return rv;
    }
    if (ulCount < 1) {
        return rv;
    }

    Newxz(_pMechanismList, ulCount, CK_MECHANISM_TYPE);
    /* uncoverable branch 0 */
    if (!_pMechanismList) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }
    if ((rv = object->function_list->C_GetMechanismList(slotID, _pMechanismList, &ulCount)) != CKR_OK) {
        Safefree(_pMechanismList);
        return rv;
    }

    for (ulPos = 0; ulPos < ulCount; ulPos++) {
        av_push(pMechanismList, newSVuv(_pMechanismList[ulPos]));
    }
    Safefree(_pMechanismList);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetMechanismInfo(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, CK_MECHANISM_TYPE type, HV* pInfo) {
    CK_MECHANISM_INFO _pInfo = { 0, 0, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetMechanismInfo) {
        return CKR_GENERAL_ERROR;
    }
    if (!pInfo) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetMechanismInfo(slotID, type, &_pInfo)) == CKR_OK) {
        hv_store(pInfo, __ulMinKeySize_str, sizeof(__ulMinKeySize_str)-1, newSVuv(_pInfo.ulMinKeySize), 0);
        hv_store(pInfo, __ulMaxKeySize_str, sizeof(__ulMaxKeySize_str)-1, newSVuv(_pInfo.ulMaxKeySize), 0);
        hv_store(pInfo, __flags_str, sizeof(__flags_str)-1, newSVuv(_pInfo.flags), 0);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_InitToken(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, SV* pPin, SV* pLabel) {
    CK_RV rv;
    SV* _pPin = NULL_PTR;
    SV* _pLabel;
    STRLEN len = 0;
    STRLEN len2;
    char* _pPin2 = NULL_PTR;
    char* _pLabel2;
    char* _pLabel3 = 0;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_InitToken) {
        return CKR_GENERAL_ERROR;
    }
    if (!pPin) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pLabel) {
        return CKR_ARGUMENTS_BAD;
    }
    /* uncoverable branch 0 */
    if (!SvOK(pLabel)) {
        return CKR_ARGUMENTS_BAD;
    }

    /* uncoverable branch 0 */
    if (SvOK(pPin)) {
        SvGETMAGIC(pPin);
        if (!(_pPin = newSVsv(pPin))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        sv_2mortal(_pPin);

        sv_utf8_downgrade(_pPin, 0);
        if (!(_pPin2 = SvPV(_pPin, len))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
    }

    SvGETMAGIC(pLabel);
    if (!(_pLabel = newSVsv(pLabel))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    sv_2mortal(_pLabel);

    sv_utf8_downgrade(_pLabel, 0);
    if (!(_pLabel2 = SvPV(_pLabel, len2))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }

    if (len2 < 32) {
        Newxz(_pLabel3, 32, char);
        /* uncoverable branch 0 */
        if (!_pLabel3) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        Copy(_pLabel2, _pLabel3, len2, char);
    }

    rv = object->function_list->C_InitToken(slotID, _pPin2, len, _pLabel3 ? _pLabel3 : _pLabel2);

    if (_pLabel3) {
        Safefree(_pLabel3);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_InitPIN(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPin) {
    CK_RV rv;
    SV* _pPin = NULL_PTR;
    STRLEN len = 0;
    char* _pPin2 = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_InitPIN) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPin) {
        return CKR_ARGUMENTS_BAD;
    }

    /* uncoverable branch 0 */
    if (SvOK(pPin)) {
        SvGETMAGIC(pPin);
        if (!(_pPin = newSVsv(pPin))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        sv_2mortal(_pPin);

        sv_utf8_downgrade(_pPin, 0);
        if (!(_pPin2 = SvPV(_pPin, len))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
    }

    rv = object->function_list->C_InitPIN(hSession, _pPin2, len);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_SetPIN(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOldPin, SV* pNewPin) {
    CK_RV rv;
    SV* _pOldPin = NULL_PTR;
    STRLEN oldLen = 0;
    char* _pOldPin2 = NULL_PTR;
    SV* _pNewPin = NULL_PTR;
    STRLEN newLen = 0;
    char* _pNewPin2 = NULL_PTR;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SetPIN) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pOldPin) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pNewPin) {
        return CKR_ARGUMENTS_BAD;
    }

    /* uncoverable branch 0 */
    if (SvOK(pOldPin)) {
        SvGETMAGIC(pOldPin);
        if (!(_pOldPin = newSVsv(pOldPin))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        sv_2mortal(_pOldPin);

        sv_utf8_downgrade(_pOldPin, 0);
        if (!(_pOldPin2 = SvPV(_pOldPin, oldLen))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
    }

    /* uncoverable branch 0 */
    if (SvOK(pNewPin)) {
        SvGETMAGIC(pNewPin);
        if (!(_pNewPin = newSVsv(pNewPin))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        sv_2mortal(_pNewPin);

        sv_utf8_downgrade(_pNewPin, 0);
        if (!(_pNewPin2 = SvPV(_pNewPin, newLen))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
    }

    rv = object->function_list->C_SetPIN(hSession, _pOldPin2, oldLen, _pNewPin2, newLen);

    return rv;
}

static CK_RV __OpenSession_Notify(CK_SESSION_HANDLE hSession, CK_NOTIFICATION event, CK_VOID_PTR pApplication) {
    dSP;
    int args;
    CK_RV rv = CKR_GENERAL_ERROR;

    if (!pApplication) {
        return CKR_ARGUMENTS_BAD;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(hSession)));
    XPUSHs(sv_2mortal(newSVuv(event)));
    PUTBACK;

    args = call_sv((SV*)pApplication, G_SCALAR);

    SPAGAIN;

    /* uncoverable branch 1 */
    if (args == 1) {
        rv = (CK_RV)POPl;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return rv;
}

CK_RV crypt_pkcs11_xs_C_OpenSession(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID, CK_FLAGS flags, SV* Notify, SV* phSession) {
    CK_SESSION_HANDLE hSession = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_OpenSession) {
        return CKR_GENERAL_ERROR;
    }
    if (!Notify) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phSession) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(Notify);
    SvGETMAGIC(phSession);
    /* uncoverable branch 0 */
    if (SvOK(Notify)) {
        if ((rv = object->function_list->C_OpenSession(slotID, flags, (CK_VOID_PTR)Notify, &__OpenSession_Notify, &hSession)) == CKR_OK) {
            sv_setuv(phSession, hSession);
            SvSETMAGIC(phSession);
        }
    }
    else {
        if ((rv = object->function_list->C_OpenSession(slotID, flags, NULL_PTR, NULL_PTR, &hSession)) == CKR_OK) {
            sv_setuv(phSession, hSession);
            SvSETMAGIC(phSession);
        }
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_CloseSession(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_CloseSession) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }

    return object->function_list->C_CloseSession(hSession);
}

CK_RV crypt_pkcs11_xs_C_CloseAllSessions(Crypt__PKCS11__XS* object, CK_SLOT_ID slotID) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_CloseAllSessions) {
        return CKR_GENERAL_ERROR;
    }

    return object->function_list->C_CloseAllSessions(slotID);
}

CK_RV crypt_pkcs11_xs_C_GetSessionInfo(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pInfo) {
    CK_SESSION_INFO _pInfo = { 0, 0, 0, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetSessionInfo) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pInfo) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetSessionInfo(hSession, &_pInfo)) == CKR_OK) {
        hv_store(pInfo, __slotID_str, sizeof(__slotID_str)-1, newSVuv(_pInfo.slotID), 0);
        hv_store(pInfo, __state_str, sizeof(__state_str)-1, newSVuv(_pInfo.state), 0);
        hv_store(pInfo, __flags_str, sizeof(__flags_str)-1, newSVuv(_pInfo.flags), 0);
        hv_store(pInfo, __ulDeviceError_str, sizeof(__ulDeviceError_str)-1, newSVuv(_pInfo.ulDeviceError), 0);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetOperationState(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOperationState) {
    CK_BYTE_PTR _pOperationState = 0;
    CK_ULONG ulOperationStateLen = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetOperationState) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pOperationState) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetOperationState(hSession, NULL_PTR, &ulOperationStateLen)) != CKR_OK) {
        return rv;
    }
    if (ulOperationStateLen < 1) {
        sv_setsv(pOperationState, &PL_sv_undef);
        return rv;
    }

    Newxz(_pOperationState, ulOperationStateLen, CK_BYTE);
    /* uncoverable branch 0 */
    if (!_pOperationState) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }
    if ((rv = object->function_list->C_GetOperationState(hSession, _pOperationState, &ulOperationStateLen)) != CKR_OK) {
        Safefree(_pOperationState);
        return rv;
    }

    SvGETMAGIC(pOperationState);
    SvUTF8_off(pOperationState);
    sv_setpvn(pOperationState, _pOperationState, ulOperationStateLen);
    SvSETMAGIC(pOperationState);
    Safefree(_pOperationState);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_SetOperationState(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pOperationState, CK_OBJECT_HANDLE hEncryptionKey, CK_OBJECT_HANDLE hAuthenticationKey) {
    CK_BYTE_PTR _pOperationState;
    STRLEN ulOperationStateLen;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SetOperationState) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pOperationState) {
        return CKR_ARGUMENTS_BAD;
    }
    /*
     * TODO: Should we check hEncryptionKey and/or hAuthenticationKey for
     * invalid handler?
     */

    SvGETMAGIC(pOperationState);
    if (!(_pOperationState = (CK_BYTE_PTR)SvPVbyte(pOperationState, ulOperationStateLen))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (ulOperationStateLen < 0) {
        return CKR_GENERAL_ERROR;
    }

    /*
     * TODO: What if ulOperationStateLen is 0 ?
     */

    return object->function_list->C_SetOperationState(hSession, _pOperationState, (CK_ULONG)ulOperationStateLen, hEncryptionKey, hAuthenticationKey);
}

CK_RV crypt_pkcs11_xs_C_Login(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_USER_TYPE userType, SV* pPin) {
    CK_RV rv;
    SV* _pPin;
    STRLEN len;
    char* _pPin2;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Login) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPin) {
        return CKR_ARGUMENTS_BAD;
    }

    /* uncoverable branch 0 */
    if (SvOK(pPin)) {
        SvGETMAGIC(pPin);
        if (!(_pPin = newSVsv(pPin))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }
        sv_2mortal(_pPin);

        sv_utf8_downgrade(_pPin, 0);
        if (!(_pPin2 = SvPV(_pPin, len))) {
            /* uncoverable block 0 */
            return CKR_GENERAL_ERROR;
        }

        rv = object->function_list->C_Login(hSession, userType, _pPin2, len);
    }
    else {
        rv = object->function_list->C_Login(hSession, userType, NULL_PTR, 0);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_Logout(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Logout) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }

    return object->function_list->C_Logout(hSession);
}

static CK_RV __check_pTemplate(AV* pTemplate, CK_ULONG_PTR pulCount, int allow_undef_pValue) {
    I32 key;
    SV** item;
    SV** type;
    SV** pValue;
    SV* entry;

    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pulCount) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    *pulCount = 0;
    for (key = 0; key < av_len(pTemplate) + 1; key++) {
        item = av_fetch(pTemplate, key, 0);

        /* uncoverable begin */
        if (!item || !*item
            /* uncoverable end */
            || !SvROK(*item))
        {
            return CKR_GENERAL_ERROR;
        }

        /* uncoverable branch 1 */
        if (!(entry = SvRV(*item)) || SvTYPE(entry) != SVt_PVHV) {
            return CKR_ARGUMENTS_BAD;
        }

        type = hv_fetch((HV*)entry, __type_str, sizeof(__type_str)-1, 0);
        pValue = hv_fetch((HV*)entry, __pValue_str, sizeof(__pValue_str)-1, 0);

        /*
         * TODO: Add support for pValue to be a nested hash with more attribute
         * values.
         */

        if (!type
            /* uncoverable branch 1 */
            || !*type
            || !crypt_pkcs11_xs_SvUOK(*type)
            || (!allow_undef_pValue
                && (!pValue
                    /* uncoverable branch 1 */
                    || !*pValue
                    || !SvPOK(*pValue)))
            || (allow_undef_pValue
                && pValue
                /* uncoverable branch 1 */
                && (!*pValue
                    || !SvPOK(*pValue))))
        {
            return CKR_ARGUMENTS_BAD;
        }

        (*pulCount)++;
    }

    return CKR_OK;
}

static CK_RV __create_CK_ATTRIBUTE(CK_ATTRIBUTE_PTR* ppTemplate, AV* pTemplate, CK_ULONG ulCount, int allow_undef_pValue) {
    I32 key;
    SV** item;
    SV** type;
    SV** pValue;
    STRLEN len;
    CK_ULONG i;
    CK_VOID_PTR _pValue;
    SV* entry;

    if (!ppTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!ulCount) {
        return CKR_ARGUMENTS_BAD;
    }
    if (*ppTemplate) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Create CK_ATTRIBUTE objects and extract the information from the hash.
     */

    Newxz(*ppTemplate, ulCount, CK_ATTRIBUTE);
    /* uncoverable branch 0 */
    if (!*ppTemplate) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    for (i = 0, key = 0; key < av_len(pTemplate) + 1; key++) {
        item = av_fetch(pTemplate, key, 0);

        /* uncoverable begin */
        if (!item || !*item
            /* uncoverable end */
            || !SvROK(*item))
        {
            Safefree(*ppTemplate);
            *ppTemplate = NULL_PTR;
            return CKR_GENERAL_ERROR;
        }

        /* uncoverable branch 1 */
        if (!(entry = SvRV(*item)) || SvTYPE(entry) != SVt_PVHV) {
            Safefree(*ppTemplate);
            *ppTemplate = NULL_PTR;
            return CKR_GENERAL_ERROR;
        }

        if (i >= ulCount) {
            Safefree(*ppTemplate);
            *ppTemplate = NULL_PTR;
            return CKR_GENERAL_ERROR;
        }

        type = hv_fetch((HV*)entry, __type_str, sizeof(__type_str)-1, 0);
        pValue = hv_fetch((HV*)entry, __pValue_str, sizeof(__pValue_str)-1, 0);

        _pValue = NULL_PTR;

        /*
         * TODO: Add support for pValue to be a nested hash with more attribute
         * values.
         */

        if (!type
            /* uncoverable branch 1 */
            || !*type
            || !crypt_pkcs11_xs_SvUOK(*type)
            || (!allow_undef_pValue
                && (!pValue
                    /* uncoverable branch 1 */
                    || !*pValue
                    || !SvPOK(*pValue)
                    || !(_pValue = SvPVbyte(*pValue, len))
                    || len < 0))
            || (allow_undef_pValue
                && pValue
                /* uncoverable branch 1 */
                && (!*pValue
                    || !SvPOK(*pValue)
                    || !(_pValue = SvPVbyte(*pValue, len))
                    || len < 0)))
        {
            Safefree(*ppTemplate);
            *ppTemplate = NULL_PTR;
            return CKR_GENERAL_ERROR;
        }

        (*ppTemplate)[i].type = (CK_ATTRIBUTE_TYPE)SvUV(*type);
        if (_pValue) {
            /*
             * TODO: What if len is 0 ?
             */
            (*ppTemplate)[i].pValue = _pValue;
            (*ppTemplate)[i].ulValueLen = (CK_ULONG)len;
        }
        else {
            (*ppTemplate)[i].pValue = NULL_PTR;
            (*ppTemplate)[i].ulValueLen = 0;
        }
        i++;
    }

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_CreateObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* pTemplate, SV* phObject) {
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_OBJECT_HANDLE hObject = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_CreateObject) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phObject) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 0)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /*
         * Create CK_ATTRIBUTE objects and extract the information from the hash.
         */

        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 0)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    /*
     * Call CreateObject
     */

    if ((rv = object->function_list->C_CreateObject(hSession, _pTemplate, ulCount, &hObject)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }
    Safefree(_pTemplate);

    SvGETMAGIC(phObject);
    sv_setuv(phObject, hObject);
    SvSETMAGIC(phObject);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_CopyObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate, SV* phNewObject) {
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_OBJECT_HANDLE hNewObject = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_CopyObject) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hObject == CK_INVALID_HANDLE) {
        return CKR_OBJECT_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phNewObject) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 0)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /*
         * Create CK_ATTRIBUTE objects and extract the information from the hash.
         */

        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 0)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    /*
     * Call CopyObject
     */

    if ((rv = object->function_list->C_CopyObject(hSession, hObject, _pTemplate, ulCount, &hNewObject)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }
    Safefree(_pTemplate);

    SvGETMAGIC(phNewObject);
    sv_setuv(phNewObject, hNewObject);
    SvSETMAGIC(phNewObject);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_DestroyObject(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DestroyObject) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hObject == CK_INVALID_HANDLE) {
        return CKR_OBJECT_HANDLE_INVALID;
    }

    return object->function_list->C_DestroyObject(hSession, hObject);
}

CK_RV crypt_pkcs11_xs_C_GetObjectSize(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, SV* pulSize) {
    CK_ULONG ulSize = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetObjectSize) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hObject == CK_INVALID_HANDLE) {
        return CKR_OBJECT_HANDLE_INVALID;
    }
    if (!pulSize) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_GetObjectSize(hSession, hObject, &ulSize)) == CKR_OK) {
        sv_setuv(pulSize, ulSize);
    }

    return rv;
}

CK_RV crypt_pkcs11_xs_C_GetAttributeValue(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate) {
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    I32 key;
    SV** item;
    SV** type;
    SV** ulValueLen;
    SV* entry;
    CK_ULONG i;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetAttributeValue) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hObject == CK_INVALID_HANDLE) {
        return CKR_OBJECT_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 1)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /*
         * Create CK_ATTRIBUTE objects and extract the information from the hash.
         */

        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 1)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    /*
     * Call GetAttributeValue
     */

    if ((rv = object->function_list->C_GetAttributeValue(hSession, hObject, _pTemplate, ulCount)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }

    /*
     * Walk the array again, for all values insert a hash entry with the size
     * of the value for that type.
     */

    for (i = 0, key = 0; key < av_len(pTemplate) + 1; key++) {
        item = av_fetch(pTemplate, key, 0);

        /* uncoverable begin */
        if (!item || !*item || !SvROK(*item)) {
            Safefree(_pTemplate);
            return CKR_GENERAL_ERROR;
        }

        if (!(entry = SvRV(*item)) || SvTYPE(entry) != SVt_PVHV) {
            Safefree(_pTemplate);
            return CKR_GENERAL_ERROR;
        }

        if (i >= ulCount) {
            Safefree(_pTemplate);
            return CKR_GENERAL_ERROR;
        }

        type = hv_fetch((HV*)entry, __type_str, sizeof(__type_str)-1, 0);
        ulValueLen = hv_fetch((HV*)entry, __ulValueLen_str, sizeof(__ulValueLen_str)-1, 0);

        if (!type
            || !*type
            || !crypt_pkcs11_xs_SvUOK(*type)
            || _pTemplate[i].type != SvUV(*type))
        {
            Safefree(_pTemplate);
            return CKR_GENERAL_ERROR;
        }

        if (!ulValueLen || !*ulValueLen) {
            hv_store((HV*)entry, __ulValueLen_str, sizeof(__ulValueLen_str)-1, newSVuv(_pTemplate[i].ulValueLen), 0);
        }
        else {
            sv_setuv(*ulValueLen, _pTemplate[i].ulValueLen);
        }
        /* uncoverable end */
        i++;
    }
    Safefree(_pTemplate);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_SetAttributeValue(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, AV* pTemplate) {
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SetAttributeValue) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hObject == CK_INVALID_HANDLE) {
        return CKR_OBJECT_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 1)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /*
         * Create CK_ATTRIBUTE objects and extract the information from the hash.
         */

        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 1)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    /*
     * Call SetAttributeValue
     */

    rv = object->function_list->C_SetAttributeValue(hSession, hObject, _pTemplate, ulCount);
    Safefree(_pTemplate);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_FindObjectsInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* pTemplate) {
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_FindObjectsInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }

    /*
     * Count the number of items in the template array and check that they are
     * valid hashes.
     */

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 1)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /*
         * Create CK_ATTRIBUTE objects and extract the information from the hash.
         */

        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 1)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    /*
     * Call FindObjectsInit
     */

    rv = object->function_list->C_FindObjectsInit(hSession, _pTemplate, ulCount);
    Safefree(_pTemplate);

    return rv;
}

CK_RV crypt_pkcs11_xs_C_FindObjects(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, AV* phObject, CK_ULONG ulMaxObjectCount) {
    CK_OBJECT_HANDLE_PTR _phObject = 0;
    CK_ULONG ulObjectCount = 0;
    CK_ULONG i;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_FindObjects) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!phObject) {
        return CKR_ARGUMENTS_BAD;
    }

    /* TODO: What? */
    if (!ulMaxObjectCount) {
        return CKR_OK;
    }

    Newxz(_phObject, ulMaxObjectCount, CK_OBJECT_HANDLE);
    /* uncoverable branch 0 */
    if (!_phObject) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    if ((rv = object->function_list->C_FindObjects(hSession, _phObject, ulMaxObjectCount, &ulObjectCount)) != CKR_OK) {
        Safefree(_phObject);
        return rv;
    }

    for (i = 0; i < ulObjectCount; i++) {
        av_push(phObject, newSVuv(_phObject[i]));
    }
    Safefree(_phObject);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_FindObjectsFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_FindObjectsFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }

    return object->function_list->C_FindObjectsFinal(hSession);
}

static CK_RV __action_init(HV* pMechanism, CK_MECHANISM_PTR _pMechanism) {
    SV** mechanism;
    SV** pParameter;
    char* _pParameter;
    STRLEN ulParameterLen;

    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!_pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }

    mechanism = hv_fetch(pMechanism, __mechanism_str, sizeof(__mechanism_str)-1, 0);
    pParameter = hv_fetch(pMechanism, __pParameter_str, sizeof(__pParameter_str)-1, 0);

    if (!mechanism
        /* uncoverable branch 1 */
        || !*mechanism
        || !crypt_pkcs11_xs_SvUOK(*mechanism)
        || (pParameter
            /* uncoverable branch 1 */
            && (!*pParameter
                || !SvPOK(*pParameter)
                || !(_pParameter = SvPVbyte(*pParameter, ulParameterLen))
                || ulParameterLen < 0)))
    {
        return CKR_ARGUMENTS_BAD;
    }

    _pMechanism->mechanism = SvUV(*mechanism);
    if (pParameter) {
        /*
         * TODO: What if ulParameterLen is 0 ?
         */
        _pMechanism->pParameter = _pParameter;
        _pMechanism->ulParameterLen = (CK_ULONG)ulParameterLen;
    }

    return CKR_OK;
}

typedef CK_RV (*__action_call_t)(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR, CK_ULONG_PTR);

static CK_RV __action(__action_call_t call, CK_SESSION_HANDLE hSession, SV* pFrom, SV* pTo) {
    char* _pFrom;
    STRLEN ulFromLen;
    char* _pTo = 0;
    STRLEN ulToLen = 0;
    CK_ULONG pulToLen = 0;
    CK_RV rv;

    if (!call) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pFrom) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pTo) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pFrom);
    SvGETMAGIC(pTo);
    if (!(_pFrom = SvPVbyte(pFrom, ulFromLen))
        || ulFromLen < 0
        /* uncoverable begin */
        || (SvOK(pTo)
            /* uncoverable end */
            && (!(_pTo = SvPVbyte(pTo, ulToLen))
                || ulToLen < 0)))
    {
        /* uncoverable block 0 */
        return CKR_ARGUMENTS_BAD;
    }

    if (!ulToLen) {
        /*
         * If pTo is not pre-allocated then we ask the PKCS#11 module how much
         * memory it will need for the encryption.
         */

        if ((rv = call(hSession, _pFrom, (CK_ULONG)ulFromLen, NULL_PTR, &pulToLen)) != CKR_OK) {
            return rv;
        }
    }
    else {
        pulToLen = ulToLen / sizeof(CK_BYTE);
    }
    if (!pulToLen) {
        return CKR_GENERAL_ERROR;
    }

    Newxz(_pTo, pulToLen, CK_BYTE);
    /* uncoverable branch 0 */
    if (!_pTo) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    if ((rv = call(hSession, _pFrom, (CK_ULONG)ulFromLen, _pTo, &pulToLen)) != CKR_OK) {
        Safefree(_pTo);
        return rv;
    }

    sv_setpvn(pTo, _pTo, pulToLen * sizeof(CK_BYTE));
    Safefree(_pTo);
    SvSETMAGIC(pTo);

    return CKR_OK;
}

typedef CK_RV (*__action_update_call_t)(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG);

static CK_RV __action_update(__action_update_call_t call, CK_SESSION_HANDLE hSession, SV* pFrom) {
    char* _pFrom;
    STRLEN ulFromLen;

    if (!call) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pFrom) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pFrom);
    if (!(_pFrom = SvPVbyte(pFrom, ulFromLen))
        || ulFromLen < 0)
    {
        /* uncoverable block 0 */
        return CKR_ARGUMENTS_BAD;
    }

    return call(hSession, _pFrom, ulFromLen);
}

typedef CK_RV (*__action_final_call_t)(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG_PTR);

static CK_RV __action_final(__action_final_call_t call, CK_SESSION_HANDLE hSession, SV* pLastPart) {
    CK_BYTE_PTR _pLastPart = 0;
    STRLEN ulLastPartLen = 0;
    CK_ULONG pulLastPartLen = 0;
    CK_RV rv;

    if (!call) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pLastPart) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pLastPart);
    if (SvOK(pLastPart)
        && (!(_pLastPart = SvPVbyte(pLastPart, ulLastPartLen))
            || ulLastPartLen < 0))
    {
        /* uncoverable block 0 */
        return CKR_ARGUMENTS_BAD;
    }

    if (!ulLastPartLen) {
        /*
         * If pLastPart is not pre-allocated when we ask the PKCS#11 module how
         * much memory it will need for the encryption.
         */

        if ((rv = call(hSession, NULL_PTR, &pulLastPartLen)) != CKR_OK) {
            return rv;
        }
    }
    else {
        pulLastPartLen = ulLastPartLen / sizeof(CK_BYTE);
    }
    if (!pulLastPartLen) {
        return CKR_GENERAL_ERROR;
    }

    Newxz(_pLastPart, pulLastPartLen, CK_BYTE);
    /* uncoverable branch 0 */
    if (!_pLastPart) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    if ((rv = call(hSession, _pLastPart, &pulLastPartLen)) != CKR_OK) {
        Safefree(_pLastPart);
        return rv;
    }

    sv_setpvn(pLastPart, _pLastPart, pulLastPartLen * sizeof(CK_BYTE));
    Safefree(_pLastPart);
    SvSETMAGIC(pLastPart);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_EncryptInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_EncryptInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_EncryptInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_Encrypt(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pEncryptedData) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Encrypt) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pEncryptedData) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_Encrypt, hSession, pData, pEncryptedData);
}

CK_RV crypt_pkcs11_xs_C_EncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_EncryptUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_EncryptUpdate, hSession, pPart, pEncryptedPart);
}

CK_RV crypt_pkcs11_xs_C_EncryptFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pLastEncryptedPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_EncryptFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pLastEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_final(object->function_list->C_EncryptFinal, hSession, pLastEncryptedPart);
}

CK_RV crypt_pkcs11_xs_C_DecryptInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DecryptInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_DecryptInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_Decrypt(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedData, SV* pData) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Decrypt) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pEncryptedData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_Decrypt, hSession, pEncryptedData, pData);
}

CK_RV crypt_pkcs11_xs_C_DecryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DecryptUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_DecryptUpdate, hSession, pEncryptedPart, pPart);
}

CK_RV crypt_pkcs11_xs_C_DecryptFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pLastPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DecryptFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pLastPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_final(object->function_list->C_DecryptFinal, hSession, pLastPart);
}

CK_RV crypt_pkcs11_xs_C_DigestInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DigestInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_DigestInit(hSession, &_pMechanism);
}

CK_RV crypt_pkcs11_xs_C_Digest(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pDigest) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Digest) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pDigest) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_Digest, hSession, pData, pDigest);
}

CK_RV crypt_pkcs11_xs_C_DigestUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DigestUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_update(object->function_list->C_DigestUpdate, hSession, pPart);
}

CK_RV crypt_pkcs11_xs_C_DigestKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hKey) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DigestKey) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    return object->function_list->C_DigestKey(hSession, hKey);
}

CK_RV crypt_pkcs11_xs_C_DigestFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pDigest) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DigestFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pDigest) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_final(object->function_list->C_DigestFinal, hSession, pDigest);
}

CK_RV crypt_pkcs11_xs_C_SignInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_SignInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_Sign(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Sign) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_Sign, hSession, pData, pSignature);
}

CK_RV crypt_pkcs11_xs_C_SignUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_update(object->function_list->C_SignUpdate, hSession, pPart);
}

CK_RV crypt_pkcs11_xs_C_SignFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_final(object->function_list->C_SignFinal, hSession, pSignature);
}

CK_RV crypt_pkcs11_xs_C_SignRecoverInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignRecoverInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_SignRecoverInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_SignRecover(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignRecover) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_SignRecover, hSession, pData, pSignature);
}

CK_RV crypt_pkcs11_xs_C_VerifyInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_VerifyInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_VerifyInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_Verify(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pData, SV* pSignature) {
    char* _pData;
    STRLEN ulDataLen;
    char* _pSignature;
    STRLEN ulSignatureLen;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_Verify) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pData);
    SvGETMAGIC(pSignature);
    if (!(_pData = SvPVbyte(pData, ulDataLen))
        || ulDataLen < 0
        || !(_pSignature = SvPVbyte(pSignature, ulSignatureLen))
        || ulSignatureLen < 0)
    {
        /* uncoverable block 0 */
        return CKR_ARGUMENTS_BAD;
    }

    return object->function_list->C_Verify(hSession, _pData, (CK_ULONG)ulDataLen, _pSignature, (CK_ULONG)ulSignatureLen);
}

CK_RV crypt_pkcs11_xs_C_VerifyUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_VerifyUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action_update(object->function_list->C_VerifyUpdate, hSession, pPart);
}

CK_RV crypt_pkcs11_xs_C_VerifyFinal(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature) {
    char* _pSignature;
    STRLEN ulSignatureLen;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_VerifyFinal) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pSignature);
    if (!(_pSignature = SvPVbyte(pSignature, ulSignatureLen))
        || ulSignatureLen < 0)
    {
        /* uncoverable block 0 */
        return CKR_ARGUMENTS_BAD;
    }

    return object->function_list->C_VerifyFinal(hSession, _pSignature, ulSignatureLen);
}

CK_RV crypt_pkcs11_xs_C_VerifyRecoverInit(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_VerifyRecoverInit) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    return object->function_list->C_VerifyRecoverInit(hSession, &_pMechanism, hKey);
}

CK_RV crypt_pkcs11_xs_C_VerifyRecover(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSignature, SV* pData) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_VerifyRecover) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pSignature) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pData) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_VerifyRecover, hSession, pSignature, pData);
}

CK_RV crypt_pkcs11_xs_C_DigestEncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DigestEncryptUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_DigestEncryptUpdate, hSession, pPart, pEncryptedPart);
}

CK_RV crypt_pkcs11_xs_C_DecryptDigestUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DecryptDigestUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_DecryptDigestUpdate, hSession, pEncryptedPart, pPart);
}

CK_RV crypt_pkcs11_xs_C_SignEncryptUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pPart, SV* pEncryptedPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SignEncryptUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_SignEncryptUpdate, hSession, pPart, pEncryptedPart);
}

CK_RV crypt_pkcs11_xs_C_DecryptVerifyUpdate(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pEncryptedPart, SV* pPart) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DecryptVerifyUpdate) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pEncryptedPart) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pPart) {
        return CKR_ARGUMENTS_BAD;
    }

    return __action(object->function_list->C_DecryptVerifyUpdate, hSession, pEncryptedPart, pPart);
}

CK_RV crypt_pkcs11_xs_C_GenerateKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, AV* pTemplate, SV* phKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_OBJECT_HANDLE hKey = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GenerateKey) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phKey) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 0)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 0)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    if ((rv = object->function_list->C_GenerateKey(hSession, &_pMechanism, _pTemplate, ulCount, &hKey)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }
    Safefree(_pTemplate);

    SvGETMAGIC(phKey);
    sv_setuv(phKey, hKey);
    SvSETMAGIC(phKey);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_GenerateKeyPair(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, AV* pPublicKeyTemplate, AV* pPrivateKeyTemplate, SV* phPublicKey, SV* phPrivateKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_ATTRIBUTE_PTR _pPublicKeyTemplate = NULL_PTR;
    CK_ULONG ulPublicKeyCount = 0;
    CK_ATTRIBUTE_PTR _pPrivateKeyTemplate = NULL_PTR;
    CK_ULONG ulPrivateKeyCount = 0;
    CK_OBJECT_HANDLE hPublicKey = CK_INVALID_HANDLE;
    CK_OBJECT_HANDLE hPrivateKey = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GenerateKeyPair) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pPublicKeyTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pPrivateKeyTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phPublicKey) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phPrivateKey) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    if ((rv = __check_pTemplate(pPublicKeyTemplate, &ulPublicKeyCount, 0)) != CKR_OK) {
        return rv;
    }
    if (ulPublicKeyCount) {
        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pPublicKeyTemplate, pPublicKeyTemplate, ulPublicKeyCount, 0)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    if ((rv = __check_pTemplate(pPrivateKeyTemplate, &ulPrivateKeyCount, 0)) != CKR_OK) {
        Safefree(_pPublicKeyTemplate);
        return rv;
    }
    if (ulPrivateKeyCount) {
        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pPrivateKeyTemplate, pPrivateKeyTemplate, ulPrivateKeyCount, 0)) != CKR_OK) {
            /* uncoverable begin */
            Safefree(_pPublicKeyTemplate);
            return rv;
            /* uncoverable end */
        }
    }

    if ((rv = object->function_list->C_GenerateKeyPair(hSession, &_pMechanism, _pPublicKeyTemplate, ulPublicKeyCount, _pPrivateKeyTemplate, ulPrivateKeyCount, &hPublicKey, &hPrivateKey)) != CKR_OK) {
        Safefree(_pPublicKeyTemplate);
        Safefree(_pPrivateKeyTemplate);
        return rv;
    }
    Safefree(_pPublicKeyTemplate);
    Safefree(_pPrivateKeyTemplate);

    SvGETMAGIC(phPublicKey);
    SvGETMAGIC(phPrivateKey);
    sv_setuv(phPublicKey, hPublicKey);
    sv_setuv(phPrivateKey, hPrivateKey);
    SvSETMAGIC(phPublicKey);
    SvSETMAGIC(phPrivateKey);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_WrapKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hWrappingKey, CK_OBJECT_HANDLE hKey, SV* pWrappedKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_BYTE_PTR _pWrappedKey = 0;
    STRLEN ulWrappedKey;
    CK_ULONG pulWrappedKey = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_WrapKey) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hWrappingKey == CK_INVALID_HANDLE) {
        return CKR_WRAPPING_KEY_HANDLE_INVALID;
    }
    if (hKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }
    if (!pWrappedKey) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    SvGETMAGIC(pWrappedKey);
    if (!(_pWrappedKey = (CK_BYTE_PTR)SvPVbyte(pWrappedKey, ulWrappedKey))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (ulWrappedKey < 0) {
        return CKR_GENERAL_ERROR;
    }

    if (!ulWrappedKey) {
        if ((rv = object->function_list->C_WrapKey(hSession, &_pMechanism, hWrappingKey, hKey, NULL_PTR, &pulWrappedKey)) != CKR_OK) {
            return rv;
        }
    }
    else {
        pulWrappedKey = ulWrappedKey / sizeof(CK_BYTE);
    }
    if (!pulWrappedKey) {
        return CKR_GENERAL_ERROR;
    }

    Newxz(_pWrappedKey, pulWrappedKey, CK_BYTE);
    /* uncoverable branch 0 */
    if (!_pWrappedKey) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    if ((rv = object->function_list->C_WrapKey(hSession, &_pMechanism, hWrappingKey, hKey, _pWrappedKey, &pulWrappedKey)) != CKR_OK) {
        Safefree(_pWrappedKey);
        return rv;
    }

    sv_setpvn(pWrappedKey, _pWrappedKey, pulWrappedKey * sizeof(CK_BYTE));
    Safefree(_pWrappedKey);
    SvSETMAGIC(pWrappedKey);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_UnwrapKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hUnwrappingKey, SV* pWrappedKey, AV* pTemplate, SV* phKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    char* _pWrappedKey;
    STRLEN ulWrappedKey;
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_OBJECT_HANDLE hKey = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_UnwrapKey) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hUnwrappingKey == CK_INVALID_HANDLE) {
        return CKR_UNWRAPPING_KEY_HANDLE_INVALID;
    }
    if (!pWrappedKey) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phKey) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    SvGETMAGIC(pWrappedKey);
    if (!(_pWrappedKey = (CK_BYTE_PTR)SvPVbyte(pWrappedKey, ulWrappedKey))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (ulWrappedKey < 0) {
        return CKR_GENERAL_ERROR;
    }

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 1)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 1)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    if ((rv = object->function_list->C_UnwrapKey(hSession, &_pMechanism, hUnwrappingKey, _pWrappedKey, ulWrappedKey, _pTemplate, ulCount, &hKey)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }
    Safefree(_pTemplate);

    SvGETMAGIC(phKey);
    sv_setuv(phKey, hKey);
    SvSETMAGIC(phKey);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_DeriveKey(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, HV* pMechanism, CK_OBJECT_HANDLE hBaseKey, AV* pTemplate, SV* phKey) {
    CK_MECHANISM _pMechanism = { 0, NULL_PTR, 0 };
    CK_ATTRIBUTE_PTR _pTemplate = NULL_PTR;
    CK_ULONG ulCount = 0;
    CK_OBJECT_HANDLE hKey = CK_INVALID_HANDLE;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_DeriveKey) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pMechanism) {
        return CKR_ARGUMENTS_BAD;
    }
    if (hBaseKey == CK_INVALID_HANDLE) {
        return CKR_KEY_HANDLE_INVALID;
    }
    if (!pTemplate) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!phKey) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = __action_init(pMechanism, &_pMechanism)) != CKR_OK) {
        return rv;
    }

    if ((rv = __check_pTemplate(pTemplate, &ulCount, 1)) != CKR_OK) {
        return rv;
    }

    if (ulCount) {
        /* uncoverable branch 1 */
        if ((rv = __create_CK_ATTRIBUTE(&_pTemplate, pTemplate, ulCount, 1)) != CKR_OK) {
            /* uncoverable block 0 */
            return rv;
        }
    }

    if ((rv = object->function_list->C_DeriveKey(hSession, &_pMechanism, hBaseKey, _pTemplate, ulCount, &hKey)) != CKR_OK) {
        Safefree(_pTemplate);
        return rv;
    }
    Safefree(_pTemplate);

    SvGETMAGIC(phKey);
    sv_setuv(phKey, hKey);
    SvSETMAGIC(phKey);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_SeedRandom(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* pSeed) {
    char* _pSeed;
    STRLEN ulSeedLen;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_SeedRandom) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!pSeed) {
        return CKR_ARGUMENTS_BAD;
    }

    SvGETMAGIC(pSeed);
    if (!(_pSeed = (CK_BYTE_PTR)SvPVbyte(pSeed, ulSeedLen))) {
        /* uncoverable block 0 */
        return CKR_GENERAL_ERROR;
    }
    if (ulSeedLen < 0) {
        return CKR_GENERAL_ERROR;
    }

    return object->function_list->C_SeedRandom(hSession, _pSeed, (CK_ULONG)ulSeedLen);
}

CK_RV crypt_pkcs11_xs_C_GenerateRandom(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession, SV* RandomData, CK_ULONG ulRandomLen) {
    CK_BYTE_PTR _RandomData = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GenerateRandom) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }
    if (!RandomData) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!ulRandomLen) {
        return CKR_ARGUMENTS_BAD;
    }

    Newxz(_RandomData, ulRandomLen, CK_BYTE);
    /* uncoverable branch 0 */
    if (!_RandomData) {
        /* uncoverable block 0 */
        return CKR_HOST_MEMORY;
    }

    if ((rv = object->function_list->C_GenerateRandom(hSession, _RandomData, ulRandomLen)) != CKR_OK) {
        Safefree(_RandomData);
        return rv;
    }

    /*
     * TODO: Do we need to turn off utf8 for SV* RandomData?
     */

    SvGETMAGIC(RandomData);
    sv_setpvn(RandomData, _RandomData, ulRandomLen * sizeof(CK_BYTE));
    Safefree(_RandomData);
    SvSETMAGIC(RandomData);

    return CKR_OK;
}

CK_RV crypt_pkcs11_xs_C_GetFunctionStatus(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_GetFunctionStatus) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }

    return object->function_list->C_GetFunctionStatus(hSession);
}

CK_RV crypt_pkcs11_xs_C_CancelFunction(Crypt__PKCS11__XS* object, CK_SESSION_HANDLE hSession) {
    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (!object->function_list->C_CancelFunction) {
        return CKR_GENERAL_ERROR;
    }
    if (hSession == CK_INVALID_HANDLE) {
        return CKR_SESSION_HANDLE_INVALID;
    }

    return object->function_list->C_CancelFunction(hSession);
}

CK_RV crypt_pkcs11_xs_C_WaitForSlotEvent(Crypt__PKCS11__XS* object, CK_FLAGS flags, SV* pSlot) {
    CK_SLOT_ID _pSlot = 0;
    CK_RV rv;

    if (!object) {
        return CKR_ARGUMENTS_BAD;
    }
    if (!object->function_list) {
        return CKR_GENERAL_ERROR;
    }
    if (object->info.cryptokiVersion.major < 2) {
        return CKR_FUNCTION_NOT_SUPPORTED;
    }
    if (object->info.cryptokiVersion.minor < 1) {
        return CKR_FUNCTION_NOT_SUPPORTED;
    }
    if (!object->function_list->C_WaitForSlotEvent) {
        return CKR_GENERAL_ERROR;
    }
    if (!pSlot) {
        return CKR_ARGUMENTS_BAD;
    }

    if ((rv = object->function_list->C_WaitForSlotEvent(flags, &_pSlot, NULL_PTR)) != CKR_OK) {
        return rv;
    }

    SvGETMAGIC(pSlot);
    sv_setuv(pSlot, _pSlot);
    SvSETMAGIC(pSlot);

    return CKR_OK;
}

#ifdef TEST_DEVEL_COVER
extern int __test_devel_cover_calloc_always_fail;
int __test_devel_cover_C_GetSlotList = 0;
int __test_devel_cover_C_GetMechanismList = 0;
int __test_devel_cover_C_GetOperationState = 0;
static CK_RV __test_action_call(CK_SESSION_HANDLE a, CK_BYTE_PTR b, CK_ULONG c, CK_BYTE_PTR d, CK_ULONG_PTR e);
static CK_RV __test_action_final_call(CK_SESSION_HANDLE a, CK_BYTE_PTR b, CK_ULONG_PTR c);

int crypt_pkcs11_xs_test_devel_cover(Crypt__PKCS11__XS* object) {
    struct crypt_pkcs11_xs_object object_no_function_list = {
        0,
        0,
        {
            { 2, 30 },
            "                                ",
            0,
            "                                ",
            { 2, 30 }
        }
    };
    CK_FUNCTION_LIST empty_function_list = {
        {
            2,
            30
        },
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0
    };
    struct crypt_pkcs11_xs_object object_empty_function_list = {
        0,
        &empty_function_list,
        {
            { 2, 30 },
            "                                ",
            0,
            "                                ",
            { 2, 30 }
        }
    };
    struct crypt_pkcs11_xs_object object_fake_handle = {
        (Crypt__PKCS11__XS*)1,
        0,
        {
            { 2, 30 },
            "                                ",
            0,
            "                                ",
            { 2, 30 }
        }
    };
    SV* sv;
    HV* hv;
    /* CRYPT PKCS11 TEST DEVEL COVER */
    if (crypt_pkcs11_xs_SvUOK(0) != 0) { return __LINE__; }
    if (crypt_pkcs11_xs_SvIOK(0) != 0) { return __LINE__; }
    sv = newSViv(1);
    if (crypt_pkcs11_xs_SvUOK(sv) != 1) { return __LINE__; }
    if (crypt_pkcs11_xs_SvIOK(sv) != 1) { return __LINE__; }
    /*
    crypt_pkcs11_xs_setCreateMutex(sv);
    crypt_pkcs11_xs_setDestroyMutex(sv);
    crypt_pkcs11_xs_setLockMutex(sv);
    crypt_pkcs11_xs_setUnlockMutex(sv);
    crypt_pkcs11_xs_setCreateMutex(sv);
    crypt_pkcs11_xs_setDestroyMutex(sv);
    crypt_pkcs11_xs_setLockMutex(sv);
    crypt_pkcs11_xs_setUnlockMutex(sv);
    */
    crypt_pkcs11_xs_clearCreateMutex();
    crypt_pkcs11_xs_clearDestroyMutex();
    crypt_pkcs11_xs_clearLockMutex();
    crypt_pkcs11_xs_clearUnlockMutex();
    SvREFCNT_dec(sv);
    if (crypt_pkcs11_xs_load(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_load(object, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_load(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_load(&object_no_function_list, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_load(&object_fake_handle, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_unload(0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_unload(&object_no_function_list) != CKR_GENERAL_ERROR) { return __LINE__; }
    crypt_pkcs11_xs_DESTROY(0);
    if (crypt_pkcs11_xs_C_Initialize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Initialize(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Initialize(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Initialize(object, 0) != CKR_OK) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Finalize(0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Finalize(&object_no_function_list) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Finalize(&object_empty_function_list) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Finalize(object) != CKR_OK) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetInfo(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetInfo(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetInfo(object, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    hv = newHV();
    if (crypt_pkcs11_xs_C_GetInfo(object, hv) != CKR_OK) { return __LINE__; }
    SvREFCNT_dec((SV*)hv);
    if (crypt_pkcs11_xs_C_GetSlotList(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotList(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotList(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotList(object, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotList(object, 0, (AV*)1) != CKR_OK) { return __LINE__; }
    __test_devel_cover_C_GetSlotList = 1;
    if (crypt_pkcs11_xs_C_GetSlotList(object, 0, (AV*)1) != CKR_GENERAL_ERROR) { return __LINE__; }
    __test_devel_cover_C_GetSlotList = 0;
    if (crypt_pkcs11_xs_C_GetSlotInfo(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotInfo(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotInfo(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSlotInfo(object, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetTokenInfo(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetTokenInfo(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetTokenInfo(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetTokenInfo(object, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismList(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismList(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismList(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismList(object, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismList(object, 0, (AV*)1) != CKR_OK) { return __LINE__; }
    __test_devel_cover_C_GetMechanismList = 1;
    if (crypt_pkcs11_xs_C_GetMechanismList(object, 0, (AV*)1) != CKR_GENERAL_ERROR) { return __LINE__; }
    __test_devel_cover_C_GetMechanismList = 0;
    if (crypt_pkcs11_xs_C_GetMechanismInfo(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismInfo(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismInfo(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetMechanismInfo(object, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitToken(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitToken(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitToken(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitToken(object, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitToken(object, 0, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitPIN(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitPIN(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitPIN(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitPIN(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_InitPIN(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetPIN(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_OpenSession(0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_OpenSession(&object_no_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_OpenSession(&object_empty_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_OpenSession(object, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_OpenSession(object, 0, 0, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__OpenSession_Notify(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseSession(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseSession(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseSession(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseSession(object, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseAllSessions(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseAllSessions(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseAllSessions(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CloseAllSessions(object, 0) != CKR_OK) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSessionInfo(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSessionInfo(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSessionInfo(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSessionInfo(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetSessionInfo(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetOperationState(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetOperationState(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetOperationState(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetOperationState(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetOperationState(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    __test_devel_cover_C_GetOperationState = 1;
    if (crypt_pkcs11_xs_C_GetOperationState(object, 1, (SV*)1) != CKR_GENERAL_ERROR) { return __LINE__; }
    __test_devel_cover_C_GetOperationState = 2;
    if (crypt_pkcs11_xs_C_GetOperationState(object, 1, (SV*)1) != CKR_GENERAL_ERROR) { return __LINE__; }
    __test_devel_cover_C_GetOperationState = 0;
    if (crypt_pkcs11_xs_C_SetOperationState(0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetOperationState(&object_no_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetOperationState(&object_empty_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetOperationState(object, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetOperationState(object, 1, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Login(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Login(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Login(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Login(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Login(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Logout(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Logout(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Logout(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Logout(object, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (__check_pTemplate((AV*)0, (CK_ULONG_PTR)0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__check_pTemplate((AV*)1, (CK_ULONG_PTR)0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__create_CK_ATTRIBUTE((CK_ATTRIBUTE_PTR*)0, (AV*)0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__create_CK_ATTRIBUTE((CK_ATTRIBUTE_PTR*)1, (AV*)0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__create_CK_ATTRIBUTE((CK_ATTRIBUTE_PTR*)1, (AV*)1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    {
        CK_ATTRIBUTE_PTR p = (CK_ATTRIBUTE_PTR)1;
        if (__create_CK_ATTRIBUTE(&p, (AV*)1, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    }
    if (crypt_pkcs11_xs_C_CreateObject(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CreateObject(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CreateObject(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CreateObject(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CreateObject(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CreateObject(object, 1, (AV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(&object_no_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(&object_empty_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(object, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(object, 1, 0, 0, 0) != CKR_OBJECT_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(object, 1, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CopyObject(object, 1, 1, (AV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DestroyObject(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DestroyObject(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DestroyObject(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DestroyObject(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(object, 1, 0, 0) != CKR_OBJECT_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetObjectSize(object, 1, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(object, 1, 0, 0) != CKR_OBJECT_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetAttributeValue(object, 1, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(object, 1, 0, 0) != CKR_OBJECT_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SetAttributeValue(object, 1, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsInit(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsInit(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsInit(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsInit(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsInit(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjects(object, 1, (AV*)1, 0) != CKR_OK) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsFinal(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsFinal(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsFinal(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_FindObjectsFinal(object, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (__action_init((HV*)0, (CK_MECHANISM_PTR)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action_init((HV*)1, (CK_MECHANISM_PTR)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action((__action_call_t)0, 0, (SV*)0, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action((__action_call_t)1, 0, (SV*)0, (SV*)0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (__action((__action_call_t)1, 1, (SV*)0, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action((__action_call_t)1, 1, (SV*)1, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action_update((__action_update_call_t)0, 0, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action_update((__action_update_call_t)1, 0, (SV*)0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (__action_update((__action_update_call_t)1, 1, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action_final((__action_final_call_t)0, 0, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (__action_final((__action_final_call_t)1, 0, (SV*)0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (__action_final((__action_final_call_t)1, 1, (SV*)0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Encrypt(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptFinal(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptFinal(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptFinal(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptFinal(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_EncryptFinal(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Decrypt(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptFinal(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptFinal(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptFinal(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptFinal(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptFinal(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestInit(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestInit(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestInit(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestInit(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestInit(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Digest(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestUpdate(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestUpdate(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestUpdate(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestUpdate(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestUpdate(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(object, 1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestKey(object, 1, 1) != CKR_OK) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestFinal(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestFinal(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestFinal(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestFinal(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestFinal(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Sign(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignUpdate(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignUpdate(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignUpdate(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignUpdate(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignUpdate(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignFinal(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignFinal(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignFinal(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignFinal(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignFinal(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecoverInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignRecover(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_Verify(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyUpdate(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyUpdate(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyUpdate(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyUpdate(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyUpdate(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyFinal(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyFinal(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyFinal(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyFinal(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyFinal(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecoverInit(object, 1, (HV*)1, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_VerifyRecover(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DigestEncryptUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptDigestUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SignEncryptUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DecryptVerifyUpdate(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(&object_no_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(&object_empty_function_list, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(object, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(object, 1, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(object, 1, (HV*)1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKey(object, 1, (HV*)1, (AV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(0, 0, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(&object_no_function_list, 0, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(&object_empty_function_list, 0, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 0, 0, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 1, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 1, (HV*)1, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 1, (HV*)1, (AV*)1, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 1, (HV*)1, (AV*)1, (AV*)1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateKeyPair(object, 1, (HV*)1, (AV*)1, (AV*)1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(0, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(&object_no_function_list, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(&object_empty_function_list, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(object, 0, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(object, 1, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(object, 1, (HV*)1, 0, 0, 0) != CKR_WRAPPING_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(object, 1, (HV*)1, 1, 0, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WrapKey(object, 1, (HV*)1, 1, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(0, 0, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(&object_no_function_list, 0, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(&object_empty_function_list, 0, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 0, 0, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 1, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 1, (HV*)1, 0, 0, 0, 0) != CKR_UNWRAPPING_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 1, (HV*)1, 1, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 1, (HV*)1, 1, (SV*)1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_UnwrapKey(object, 1, (HV*)1, 1, (SV*)1, (AV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(0, 0, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(&object_no_function_list, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(&object_empty_function_list, 0, 0, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(object, 0, 0, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(object, 1, 0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(object, 1, (HV*)1, 0, 0, 0) != CKR_KEY_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(object, 1, (HV*)1, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_DeriveKey(object, 1, (HV*)1, 1, (AV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SeedRandom(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SeedRandom(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SeedRandom(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SeedRandom(object, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_SeedRandom(object, 1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(0, 0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(&object_no_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(&object_empty_function_list, 0, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(object, 0, 0, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(object, 1, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GenerateRandom(object, 1, (SV*)1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetFunctionStatus(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetFunctionStatus(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetFunctionStatus(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_GetFunctionStatus(object, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CancelFunction(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CancelFunction(&object_no_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CancelFunction(&object_empty_function_list, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_CancelFunction(object, 0) != CKR_SESSION_HANDLE_INVALID) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(0, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(&object_no_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(&object_empty_function_list, 0, 0) != CKR_GENERAL_ERROR) { return __LINE__; }
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(object, 0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    object->info.cryptokiVersion.minor = 0;
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(object, 0, (SV*)1) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    object->info.cryptokiVersion.major = 1;
    if (crypt_pkcs11_xs_C_WaitForSlotEvent(object, 0, (SV*)1) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    __test_devel_cover_calloc_always_fail = 1;
    if (crypt_pkcs11_ck_version_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_new("")) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_new("")) { return __LINE__; }
    __test_devel_cover_calloc_always_fail = 0;

    if (crypt_pkcs11_ck_version_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_toBytes(0)) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_toBytes(0)) { return __LINE__; }

    if (crypt_pkcs11_ck_version_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_fromBytes(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_fromBytes(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_fromBytes(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_fromBytes(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }

    if (crypt_pkcs11_ck_version_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_fromBytes(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_fromBytes(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_fromBytes(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_fromBytes(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }

    if (crypt_pkcs11_ck_version_get_major(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_set_major(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_get_minor(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_set_minor(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_get_mechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_set_mechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_get_pParameter(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_set_pParameter(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_hashAlg(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_hashAlg(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_mgf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_mgf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_source(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_source(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_pSourceData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_pSourceData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_hashAlg(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_hashAlg(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_mgf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_mgf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_sLen(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_sLen(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pSharedData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_publicKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_publicKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_kdf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pOtherInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_hPrivateData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData2(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_publicKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_publicKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_isSender(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_isSender(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pRandomB(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pRandomB(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_get_ulEffectiveBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_set_ulEffectiveBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_get_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_set_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_get_ulEffectiveBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_set_ulEffectiveBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_get_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_set_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_get_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_set_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_pIv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_pIv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_get_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_set_ulWordsize(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_get_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_set_ulRounds(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPrimeP(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pBaseG(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pSubprimeQ(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldWrappedX(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPublicData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewRandomA(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pInitVector(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pInitVector(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pSalt(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pSalt(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_ulIteration(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_ulIteration(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_set_bBC(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_set_pX(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_set_pClientRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_set_pServerRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_set_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_get_pVersion(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_set_pVersion(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVClient(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVServer(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulMacSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulKeySizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulIVSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_bIsExport(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_pReturnedKeyMaterial(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pLabel(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pLabel(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pOutput(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pOutput(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_get_pClientRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_set_pClientRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_get_pServerRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_set_pServerRandom(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_pVersion(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_pVersion(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pLabel(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pLabel(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pOutput(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pOutput(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_hMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_hMacSecret(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_hKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_hKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_pIV(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_pIV(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_DigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulMacSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulMacSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulKeySizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulKeySizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulIVSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulIVSizeInBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulSequenceNumber(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulSequenceNumber(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_bIsExport(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_bIsExport(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_RandomInfo(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_pReturnedKeyMaterial(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_certificateHandle(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_certificateHandle(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pSigningMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pSigningMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pDigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pDigestMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pContentType(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pContentType(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pRequestedAttributes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pRequestedAttributes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pRequiredAttributes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pRequiredAttributes(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_get_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_set_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_saltSource(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_saltSource(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pSaltSourceData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pSaltSourceData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_iterations(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_iterations(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_prf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_prf(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPrfData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPrfData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPassword(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_get_type(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_set_type(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_get_pValue(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_set_pValue(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_get_pParams(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_set_pParams(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_get_ulCount(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_set_ulCount(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_get_pParams(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_set_pParams(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_get_ulCount(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_set_ulCount(0, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_pMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_pMechanism(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_hKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_hKey(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_pSeed(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_get_ulCounterBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_set_ulCounterBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_get_cb(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_set_cb(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_pIv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_pIv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_ulIvBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_ulIvBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_pAAD(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_pAAD(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_ulTagBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_ulTagBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_get_pNonce(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_set_pNonce(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_get_pAAD(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_set_pAAD(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_get_ulCounterBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_set_ulCounterBits(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_get_cb(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_set_cb(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_iv(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_pData(0, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }

    if (crypt_pkcs11_ck_version_get_major(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_set_major(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_get_minor(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_version_set_minor(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_get_mechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_set_mechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_get_pParameter(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_mechanism_set_pParameter(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_hashAlg(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_hashAlg(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_mgf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_mgf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_source(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_source(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_get_pSourceData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_oaep_params_set_pSourceData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_hashAlg(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_hashAlg(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_mgf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_mgf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_get_sLen(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rsa_pkcs_pss_params_set_sLen(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh1_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_get_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecdh2_derive_params_set_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pSharedData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_get_publicKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ecmqv_derive_params_set_publicKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh1_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_get_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_dh2_derive_params_set_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_kdf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pOtherInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_hPrivateData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_pPublicData2(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_get_publicKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_x9_42_mqv_derive_params_set_publicKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_isSender(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_isSender(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pRandomB(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pRandomB(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kea_derive_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_get_ulEffectiveBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_set_ulEffectiveBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_get_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_cbc_params_set_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_get_ulEffectiveBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc2_mac_general_params_set_ulEffectiveBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_get_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_set_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_get_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_params_set_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_get_pIv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_cbc_params_set_pIv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_get_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_set_ulWordsize(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_get_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_rc5_mac_general_params_set_ulRounds(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_get_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_des_cbc_encrypt_data_params_set_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_get_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_cbc_encrypt_data_params_set_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pPrimeP(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pPrimeP(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pBaseG(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pBaseG(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_get_pSubprimeQ(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_private_wrap_params_set_pSubprimeQ(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldWrappedX(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldWrappedX(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pOldRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pOldRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewPublicData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_get_pNewRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_skipjack_relayx_params_set_pNewRandomA(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pInitVector(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pInitVector(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_pSalt(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_pSalt(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_get_ulIteration(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pbe_params_set_ulIteration(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_fromBytes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_get_bBC(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_set_bBC(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_get_pX(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_wrap_set_oaep_params_set_pX(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_get_pClientRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_set_pClientRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_get_pServerRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_random_data_set_pServerRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_get_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_set_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_get_pVersion(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_master_key_derive_params_set_pVersion(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hClientKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hClientKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_hServerKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_hServerKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVClient(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVClient(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_get_pIVServer(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_out_set_pIVServer(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulMacSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulMacSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulKeySizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulKeySizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_ulIVSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_ulIVSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_bIsExport(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_bIsExport(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_set_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_ssl3_key_mat_params_get_pReturnedKeyMaterial(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pLabel(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pLabel(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_get_pOutput(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_tls_prf_params_set_pOutput(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_get_pClientRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_set_pClientRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_get_pServerRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_random_data_set_pServerRandom(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_get_pVersion(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_master_key_derive_params_set_pVersion(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pLabel(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pLabel(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_get_pOutput(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_prf_params_set_pOutput(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_hMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_hMacSecret(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_hKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_hKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_get_pIV(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_out_set_pIV(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_DigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulMacSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulMacSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulKeySizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulKeySizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulIVSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulIVSizeInBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_ulSequenceNumber(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_ulSequenceNumber(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_bIsExport(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_bIsExport(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_set_RandomInfo(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_wtls_key_mat_params_get_pReturnedKeyMaterial(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_certificateHandle(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_certificateHandle(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pSigningMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pSigningMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pDigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pDigestMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pContentType(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pContentType(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pRequestedAttributes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pRequestedAttributes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_get_pRequiredAttributes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_cms_sig_params_set_pRequiredAttributes(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_get_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_key_derivation_string_data_set_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_saltSource(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_saltSource(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pSaltSourceData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pSaltSourceData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_iterations(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_iterations(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_prf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_prf(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPrfData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPrfData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_get_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_pkcs5_pbkd2_params_set_pPassword(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_get_type(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_set_type(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_get_pValue(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_param_set_pValue(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_get_pParams(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_set_pParams(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_get_ulCount(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_params_set_ulCount(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_get_pParams(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_set_pParams(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_get_ulCount(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_otp_signature_info_set_ulCount(1, 0) != CKR_FUNCTION_NOT_SUPPORTED) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_pMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_pMechanism(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_hKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_hKey(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_get_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_kip_params_set_pSeed(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_get_ulCounterBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_set_ulCounterBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_get_cb(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ctr_params_set_cb(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_pIv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_pIv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_ulIvBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_ulIvBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_pAAD(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_pAAD(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_get_ulTagBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_gcm_params_set_ulTagBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_get_pNonce(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_set_pNonce(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_get_pAAD(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aes_ccm_params_set_pAAD(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_get_ulCounterBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_set_ulCounterBits(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_get_cb(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_ctr_params_set_cb(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_get_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_set_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_iv(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_get_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }
    if (crypt_pkcs11_ck_aria_cbc_encrypt_data_params_set_pData(1, 0) != CKR_ARGUMENTS_BAD) { return __LINE__; }

    crypt_pkcs11_ck_version_DESTROY(0);
    crypt_pkcs11_ck_mechanism_DESTROY(0);
    crypt_pkcs11_ck_rsa_pkcs_oaep_params_DESTROY(0);
    crypt_pkcs11_ck_rsa_pkcs_pss_params_DESTROY(0);
    crypt_pkcs11_ck_ecdh1_derive_params_DESTROY(0);
    crypt_pkcs11_ck_ecdh2_derive_params_DESTROY(0);
    crypt_pkcs11_ck_ecmqv_derive_params_DESTROY(0);
    crypt_pkcs11_ck_x9_42_dh1_derive_params_DESTROY(0);
    crypt_pkcs11_ck_x9_42_dh2_derive_params_DESTROY(0);
    crypt_pkcs11_ck_x9_42_mqv_derive_params_DESTROY(0);
    crypt_pkcs11_ck_kea_derive_params_DESTROY(0);
    crypt_pkcs11_ck_rc2_cbc_params_DESTROY(0);
    crypt_pkcs11_ck_rc2_mac_general_params_DESTROY(0);
    crypt_pkcs11_ck_rc5_params_DESTROY(0);
    crypt_pkcs11_ck_rc5_cbc_params_DESTROY(0);
    crypt_pkcs11_ck_rc5_mac_general_params_DESTROY(0);
    crypt_pkcs11_ck_des_cbc_encrypt_data_params_DESTROY(0);
    crypt_pkcs11_ck_aes_cbc_encrypt_data_params_DESTROY(0);
    crypt_pkcs11_ck_skipjack_private_wrap_params_DESTROY(0);
    crypt_pkcs11_ck_skipjack_relayx_params_DESTROY(0);
    crypt_pkcs11_ck_pbe_params_DESTROY(0);
    crypt_pkcs11_ck_key_wrap_set_oaep_params_DESTROY(0);
    crypt_pkcs11_ck_ssl3_random_data_DESTROY(0);
    crypt_pkcs11_ck_ssl3_master_key_derive_params_DESTROY(0);
    crypt_pkcs11_ck_ssl3_key_mat_out_DESTROY(0);
    crypt_pkcs11_ck_ssl3_key_mat_params_DESTROY(0);
    crypt_pkcs11_ck_tls_prf_params_DESTROY(0);
    crypt_pkcs11_ck_wtls_random_data_DESTROY(0);
    crypt_pkcs11_ck_wtls_master_key_derive_params_DESTROY(0);
    crypt_pkcs11_ck_wtls_prf_params_DESTROY(0);
    crypt_pkcs11_ck_wtls_key_mat_out_DESTROY(0);
    crypt_pkcs11_ck_wtls_key_mat_params_DESTROY(0);
    crypt_pkcs11_ck_cms_sig_params_DESTROY(0);
    crypt_pkcs11_ck_key_derivation_string_data_DESTROY(0);
    crypt_pkcs11_ck_pkcs5_pbkd2_params_DESTROY(0);
    crypt_pkcs11_ck_otp_param_DESTROY(0);
    crypt_pkcs11_ck_otp_params_DESTROY(0);
    crypt_pkcs11_ck_otp_signature_info_DESTROY(0);
    crypt_pkcs11_ck_kip_params_DESTROY(0);
    crypt_pkcs11_ck_aes_ctr_params_DESTROY(0);
    crypt_pkcs11_ck_aes_gcm_params_DESTROY(0);
    crypt_pkcs11_ck_aes_ccm_params_DESTROY(0);
    crypt_pkcs11_ck_camellia_ctr_params_DESTROY(0);
    crypt_pkcs11_ck_camellia_cbc_encrypt_data_params_DESTROY(0);
    crypt_pkcs11_ck_aria_cbc_encrypt_data_params_DESTROY(0);

    {
        SV* from = sv_2mortal(newSVpvn(" ", 1));
        SV* to = sv_2mortal(newSVpvn("", 0));
        if (__action(__test_action_call, 1, from, to) != CKR_GENERAL_ERROR) { return __LINE__; }
        if (__action_final(__test_action_final_call, 1, to) != CKR_GENERAL_ERROR) { return __LINE__; }
        if (__action_final(__test_action_final_call, 1, from) != CKR_GENERAL_ERROR) { return __LINE__; }
    }

    return 0;
}

static CK_RV __test_action_call(CK_SESSION_HANDLE a, CK_BYTE_PTR b, CK_ULONG c, CK_BYTE_PTR d, CK_ULONG_PTR e) {
    return CKR_OK;
}

static CK_RV __test_action_final_call(CK_SESSION_HANDLE a, CK_BYTE_PTR b, CK_ULONG_PTR c) {
    if (b) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_Initialize(CK_VOID_PTR pInitArgs) {
    return CKR_OK;
}

static CK_RV __test_C_Finalize(CK_VOID_PTR pReserved) {
    return CKR_OK;
}

static CK_RV __test_C_GetInfo(CK_INFO_PTR pInfo) {
    if (pInfo) {
        pInfo->cryptokiVersion.major = 2;
        pInfo->cryptokiVersion.minor = 30;
    }
    return CKR_OK;
}

static CK_RV __test_C_GetSlotList(CK_BBOOL tokenPresent, CK_SLOT_ID_PTR pSlotList, CK_ULONG_PTR pulCount) {
    if (__test_devel_cover_C_GetSlotList) {
        *pulCount = 1;
        if (pSlotList) {
            return CKR_GENERAL_ERROR;
        }
    }
    return CKR_OK;
}

static CK_RV __test_C_GetSlotInfo(CK_SLOT_ID slotID, CK_SLOT_INFO_PTR pInfo) {
    return CKR_OK;
}

static CK_RV __test_C_GetTokenInfo(CK_SLOT_ID slotID, CK_TOKEN_INFO_PTR pInfo) {
    return CKR_OK;
}

static CK_RV __test_C_GetMechanismList(CK_SLOT_ID slotID, CK_MECHANISM_TYPE_PTR pMechanismList, CK_ULONG_PTR pulCount) {
    if (__test_devel_cover_C_GetMechanismList) {
        *pulCount = 1;
        if (pMechanismList) {
            return CKR_GENERAL_ERROR;
        }
    }
    return CKR_OK;
}

static CK_RV __test_C_GetMechanismInfo(CK_SLOT_ID slotID, CK_MECHANISM_TYPE type, CK_MECHANISM_INFO_PTR pInfo) {
    return CKR_OK;
}

static CK_RV __test_C_InitToken(CK_SLOT_ID slotID, CK_UTF8CHAR_PTR pPin, CK_ULONG ulPinLen, CK_UTF8CHAR_PTR pLabel) {
    return CKR_OK;
}

static CK_RV __test_C_InitPIN(CK_SESSION_HANDLE hSession, CK_UTF8CHAR_PTR pPin, CK_ULONG ulPinLen) {
    return CKR_OK;
}

static CK_RV __test_C_SetPIN(CK_SESSION_HANDLE hSession, CK_UTF8CHAR_PTR pOldPin, CK_ULONG ulOldLen, CK_UTF8CHAR_PTR pNewPin, CK_ULONG ulNewLen) {
    return CKR_OK;
}

static CK_RV __test_C_OpenSession(CK_SLOT_ID slotID, CK_FLAGS flags, CK_VOID_PTR pApplication, CK_NOTIFY Notify, CK_SESSION_HANDLE_PTR phSession) {
    if (slotID == 9999) {
        return CKR_GENERAL_ERROR;
    }
    if (Notify) {
        Notify(1, 1, pApplication);
    }
    return CKR_OK;
}

static CK_RV __test_C_CloseSession(CK_SESSION_HANDLE hSession) {
    return CKR_OK;
}

static CK_RV __test_C_CloseAllSessions(CK_SLOT_ID slotID) {
    return CKR_OK;
}

static CK_RV __test_C_GetSessionInfo(CK_SESSION_HANDLE hSession, CK_SESSION_INFO_PTR pInfo) {
    return CKR_OK;
}

static CK_RV __test_C_GetOperationState(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pOperationState, CK_ULONG_PTR pulOperationStateLen) {
    if (hSession == 9999) {
        return CKR_OK;
    }
    if (__test_devel_cover_C_GetOperationState == 1) {
        return CKR_GENERAL_ERROR;
    }
    *pulOperationStateLen = 1;
    if (__test_devel_cover_C_GetOperationState == 2 && pOperationState) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_SetOperationState(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pOperationState, CK_ULONG ulOperationStateLen, CK_OBJECT_HANDLE hEncryptionKey, CK_OBJECT_HANDLE hAuthenticationKey) {
    return CKR_OK;
}

static CK_RV __test_C_Login(CK_SESSION_HANDLE hSession, CK_USER_TYPE userType, CK_UTF8CHAR_PTR pPin, CK_ULONG ulPinLen) {
    return CKR_OK;
}

static CK_RV __test_C_Logout(CK_SESSION_HANDLE hSession) {
    return CKR_OK;
}

static CK_RV __test_C_CreateObject(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR phObject) {
    return CKR_OK;
}

static CK_RV __test_C_CopyObject(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR phNewObject) {
    return CKR_OK;
}

static CK_RV __test_C_DestroyObject(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject) {
    return CKR_OK;
}

static CK_RV __test_C_GetObjectSize(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, CK_ULONG_PTR pulSize) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_GetAttributeValue(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount) {
    return CKR_OK;
}

static CK_RV __test_C_SetAttributeValue(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount) {
    return CKR_OK;
}

static CK_RV __test_C_FindObjectsInit(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount) {
    return CKR_OK;
}

static CK_RV __test_C_FindObjects(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE_PTR phObject, CK_ULONG ulMaxObjectCount, CK_ULONG_PTR pulObjectCount) {
    CK_ULONG i;

    for (i = 0; i < ulMaxObjectCount; i++) {
        pulObjectCount[i] = 1;
    }

    return CKR_OK;
}

static CK_RV __test_C_FindObjectsFinal(CK_SESSION_HANDLE hSession) {
    return CKR_OK;
}

static CK_RV __test_C_EncryptInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_Encrypt(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen, CK_BYTE_PTR pEncryptedData, CK_ULONG_PTR pulEncryptedDataLen) {
    return CKR_OK;
}

static CK_RV __test_C_EncryptUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen, CK_BYTE_PTR pEncryptedPart, CK_ULONG_PTR pulEncryptedPartLen) {
    if (!pEncryptedPart) {
        *pulEncryptedPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_EncryptFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pLastEncryptedPart, CK_ULONG_PTR pulLastEncryptedPartLen) {
    if (!pLastEncryptedPart) {
        *pulLastEncryptedPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DecryptInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_Decrypt(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pEncryptedData, CK_ULONG ulEncryptedDataLen, CK_BYTE_PTR pData, CK_ULONG_PTR pulDataLen) {
    return CKR_OK;
}

static CK_RV __test_C_DecryptUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pEncryptedPart, CK_ULONG ulEncryptedPartLen, CK_BYTE_PTR pPart, CK_ULONG_PTR pulPartLen) {
    if (!pPart) {
        *pulPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DecryptFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pLastPart, CK_ULONG_PTR pulLastPartLen) {
    if (!pLastPart) {
        *pulLastPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DigestInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism) {
    return CKR_OK;
}

static CK_RV __test_C_Digest(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen, CK_BYTE_PTR pDigest, CK_ULONG_PTR pulDigestLen) {
    return CKR_OK;
}

static CK_RV __test_C_DigestUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen) {
    return CKR_OK;
}

static CK_RV __test_C_DigestKey(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_DigestFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pDigest, CK_ULONG_PTR pulDigestLen) {
    return CKR_OK;
}

static CK_RV __test_C_SignInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_Sign(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen, CK_BYTE_PTR pSignature, CK_ULONG_PTR pulSignatureLen) {
    return CKR_OK;
}

static CK_RV __test_C_SignUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen) {
    return CKR_OK;
}

static CK_RV __test_C_SignFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSignature, CK_ULONG_PTR pulSignatureLen) {
    return CKR_OK;
}

static CK_RV __test_C_SignRecoverInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_SignRecover(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen, CK_BYTE_PTR pSignature, CK_ULONG_PTR pulSignatureLen) {
    if (!pSignature) {
        *pulSignatureLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_VerifyInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_Verify(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen, CK_BYTE_PTR pSignature, CK_ULONG ulSignatureLen) {
    return CKR_OK;
}

static CK_RV __test_C_VerifyUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen) {
    return CKR_OK;
}

static CK_RV __test_C_VerifyFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSignature, CK_ULONG ulSignatureLen) {
    return CKR_OK;
}

static CK_RV __test_C_VerifyRecoverInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hKey) {
    return CKR_OK;
}

static CK_RV __test_C_VerifyRecover(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSignature, CK_ULONG ulSignatureLen, CK_BYTE_PTR pData, CK_ULONG_PTR pulDataLen) {
    if (!pData) {
        *pulDataLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DigestEncryptUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen, CK_BYTE_PTR pEncryptedPart, CK_ULONG_PTR pulEncryptedPartLen) {
    if (!pEncryptedPart) {
        *pulEncryptedPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DecryptDigestUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pEncryptedPart, CK_ULONG ulEncryptedPartLen, CK_BYTE_PTR pPart, CK_ULONG_PTR pulPartLen) {
    if (!pPart) {
        *pulPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_SignEncryptUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart, CK_ULONG ulPartLen, CK_BYTE_PTR pEncryptedPart, CK_ULONG_PTR pulEncryptedPartLen) {
    if (!pEncryptedPart) {
        *pulEncryptedPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_DecryptVerifyUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pEncryptedPart, CK_ULONG ulEncryptedPartLen, CK_BYTE_PTR pPart, CK_ULONG_PTR pulPartLen) {
    if (!pPart) {
        *pulPartLen = 1;
    }
    return CKR_OK;
}

static CK_RV __test_C_GenerateKey(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR phKey) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_GenerateKeyPair(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_ATTRIBUTE_PTR pPublicKeyTemplate, CK_ULONG ulPublicKeyAttributeCount, CK_ATTRIBUTE_PTR pPrivateKeyTemplate, CK_ULONG ulPrivateKeyAttributeCount, CK_OBJECT_HANDLE_PTR phPublicKey, CK_OBJECT_HANDLE_PTR phPrivateKey) {
    return CKR_OK;
}

static CK_RV __test_C_WrapKey(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hWrappingKey, CK_OBJECT_HANDLE hKey, CK_BYTE_PTR pWrappedKey, CK_ULONG_PTR pulWrappedKeyLen) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_UnwrapKey(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hUnwrappingKey, CK_BYTE_PTR pWrappedKey, CK_ULONG ulWrappedKeyLen, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulAttributeCount, CK_OBJECT_HANDLE_PTR phKey) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_DeriveKey(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism, CK_OBJECT_HANDLE hBaseKey, CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulAttributeCount, CK_OBJECT_HANDLE_PTR phKey) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_SeedRandom(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSeed, CK_ULONG ulSeedLen) {
    return CKR_OK;
}

static CK_RV __test_C_GenerateRandom(CK_SESSION_HANDLE hSession, CK_BYTE_PTR RandomData, CK_ULONG ulRandomLen) {
    if (hSession == 9999) {
        return CKR_GENERAL_ERROR;
    }
    return CKR_OK;
}

static CK_RV __test_C_GetFunctionStatus(CK_SESSION_HANDLE hSession) {
    return CKR_OK;
}

static CK_RV __test_C_CancelFunction(CK_SESSION_HANDLE hSession) {
    return CKR_OK;
}

static CK_RV __test_C_WaitForSlotEvent(CK_FLAGS flags, CK_SLOT_ID_PTR pSlot, CK_VOID_PTR pRserved) {
    return CKR_OK;
}

static CK_RV __test_C_GetFunctionList(CK_FUNCTION_LIST_PTR_PTR ppFunctionList) {
    static CK_FUNCTION_LIST function_list = {
        {
            2,
            30
        },
        &__test_C_Initialize,
        &__test_C_Finalize,
        &__test_C_GetInfo,
        &__test_C_GetFunctionList,
        &__test_C_GetSlotList,
        &__test_C_GetSlotInfo,
        &__test_C_GetTokenInfo,
        &__test_C_GetMechanismList,
        &__test_C_GetMechanismInfo,
        &__test_C_InitToken,
        &__test_C_InitPIN,
        &__test_C_SetPIN,
        &__test_C_OpenSession,
        &__test_C_CloseSession,
        &__test_C_CloseAllSessions,
        &__test_C_GetSessionInfo,
        &__test_C_GetOperationState,
        &__test_C_SetOperationState,
        &__test_C_Login,
        &__test_C_Logout,
        &__test_C_CreateObject,
        &__test_C_CopyObject,
        &__test_C_DestroyObject,
        &__test_C_GetObjectSize,
        &__test_C_GetAttributeValue,
        &__test_C_SetAttributeValue,
        &__test_C_FindObjectsInit,
        &__test_C_FindObjects,
        &__test_C_FindObjectsFinal,
        &__test_C_EncryptInit,
        &__test_C_Encrypt,
        &__test_C_EncryptUpdate,
        &__test_C_EncryptFinal,
        &__test_C_DecryptInit,
        &__test_C_Decrypt,
        &__test_C_DecryptUpdate,
        &__test_C_DecryptFinal,
        &__test_C_DigestInit,
        &__test_C_Digest,
        &__test_C_DigestUpdate,
        &__test_C_DigestKey,
        &__test_C_DigestFinal,
        &__test_C_SignInit,
        &__test_C_Sign,
        &__test_C_SignUpdate,
        &__test_C_SignFinal,
        &__test_C_SignRecoverInit,
        &__test_C_SignRecover,
        &__test_C_VerifyInit,
        &__test_C_Verify,
        &__test_C_VerifyUpdate,
        &__test_C_VerifyFinal,
        &__test_C_VerifyRecoverInit,
        &__test_C_VerifyRecover,
        &__test_C_DigestEncryptUpdate,
        &__test_C_DecryptDigestUpdate,
        &__test_C_SignEncryptUpdate,
        &__test_C_DecryptVerifyUpdate,
        &__test_C_GenerateKey,
        &__test_C_GenerateKeyPair,
        &__test_C_WrapKey,
        &__test_C_UnwrapKey,
        &__test_C_DeriveKey,
        &__test_C_SeedRandom,
        &__test_C_GenerateRandom,
        &__test_C_GetFunctionStatus,
        &__test_C_CancelFunction,
        &__test_C_WaitForSlotEvent
    };
    *ppFunctionList = &function_list;
    return CKR_OK;
}

static CK_RV __test_C_GetFunctionList_NO_FLIST(CK_FUNCTION_LIST_PTR_PTR ppFunctionList) {
    return CKR_GENERAL_ERROR;
}

CK_RV crypt_pkcs11_xs_test_devel_cover_check_pTemplate(AV* pTemplate, int allow_undef_pValue) {
    CK_ULONG count;
    return __check_pTemplate(pTemplate, &count, allow_undef_pValue);
}

CK_RV crypt_pkcs11_xs_test_devel_cover_create_CK_ATTRIBUTE(AV* pTemplate, CK_ULONG count, int allow_undef_pValue) {
    CK_ATTRIBUTE_PTR attr = 0;
    CK_RV rv;
    rv = __create_CK_ATTRIBUTE(&attr, pTemplate, count, allow_undef_pValue);
    Safefree(attr);
    return rv;
}

CK_RV crypt_pkcs11_xs_test_devel_cover_action_init(HV* pMechanism) {
    CK_MECHANISM mech = { 0, 0 };
    return __action_init(pMechanism, &mech);
}

#endif
