/*
 * Copyright (c) 2002 Andrew J. Korty
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $Id: Admin.xs,v 1.23 2007/01/05 23:41:38 ajk Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <krb5.h>
#ifdef HAVE_KDB_H
#define SECURID /* This should not be necessary */
#include <kdb.h>
#endif /* HAVE_KDB_H */
#include <com_err.h>
#ifdef USE_LOCAL_ADMINH
#include "admin.h"
#else
#include <krb5/krb5.h>
#include <kadm5/admin.h>
#endif
#include "ppport.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'E':
        if (strEQ(name, "ENCTYPE_NULL"))
#ifdef ENCTYPE_NULL
            return ENCTYPE_NULL;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES_CBC_CRC"))
#ifdef ENCTYPE_DES_CBC_CRC
            return ENCTYPE_DES_CBC_CRC;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES_CBC_MD4"))
#ifdef ENCTYPE_DES_CBC_MD4
            return ENCTYPE_DES_CBC_MD4;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES_CBC_MD5"))
#ifdef ENCTYPE_DES_CBC_MD5
            return ENCTYPE_DES_CBC_MD5;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES_CBC_RAW"))
#ifdef ENCTYPE_DES_CBC_RAW
            return ENCTYPE_DES_CBC_RAW;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES_HMAC_SHA1"))
#ifdef ENCTYPE_DES_HMAC_SHA1
            return ENCTYPE_DES_HMAC_SHA1;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES3_CBC_RAW"))
#ifdef ENCTYPE_DES3_CBC_RAW
            return ENCTYPE_DES3_CBC_RAW;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES3_CBC_SHA"))
#ifdef ENCTYPE_DES3_CBC_SHA
            return ENCTYPE_DES3_CBC_SHA;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_DES3_CBC_SHA1"))
#ifdef ENCTYPE_DES3_CBC_SHA1
            return ENCTYPE_DES3_CBC_SHA1;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_LOCAL_DES3_HMAC_SHA1"))
#ifdef ENCTYPE_LOCAL_DES3_HMAC_SHA1
            return ENCTYPE_LOCAL_DES3_HMAC_SHA1;
#else
            goto not_there;
#endif
        if (strEQ(name, "ENCTYPE_UNKNOWN"))
#ifdef ENCTYPE_UNKNOWN
            return ENCTYPE_UNKNOWN;
#else
            goto not_there;
#endif
        break;
    case 'K':
        if (strEQ(name, "KADM5_API_VERSION_1"))
#ifdef KADM5_API_VERSION_1
            return KADM5_API_VERSION_1;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_API_VERSION_2"))
#ifdef KADM5_API_VERSION_2
            return KADM5_API_VERSION_2;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_API_VERSION_3"))
#ifdef KADM5_API_VERSION_3
            return KADM5_API_VERSION_3;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_API_VERSION_4"))
#ifdef KADM5_API_VERSION_4
            return KADM5_API_VERSION_4;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_API_VERSION_MASK"))
#ifdef KADM5_API_VERSION_MASK
            return KADM5_API_VERSION_MASK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_ATTRIBUTES"))
#ifdef KADM5_ATTRIBUTES
            return KADM5_ATTRIBUTES;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_ADD"))
#ifdef KADM5_AUTH_ADD
            return KADM5_AUTH_ADD;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_CHANGEPW"))
#ifdef KADM5_AUTH_CHANGEPW
            return KADM5_AUTH_CHANGEPW;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_DELETE"))
#ifdef KADM5_AUTH_DELETE
            return KADM5_AUTH_DELETE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_GET"))
#ifdef KADM5_AUTH_GET
            return KADM5_AUTH_GET;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_INSUFFICIENT"))
#ifdef KADM5_AUTH_INSUFFICIENT
            return KADM5_AUTH_INSUFFICIENT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_LIST"))
#ifdef KADM5_AUTH_LIST
            return KADM5_AUTH_LIST;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_MODIFY"))
#ifdef KADM5_AUTH_MODIFY
            return KADM5_AUTH_MODIFY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUTH_SETKEY"))
#ifdef KADM5_AUTH_SETKEY
            return KADM5_AUTH_SETKEY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_AUX_ATTRIBUTES"))
#ifdef KADM5_AUX_ATTRIBUTES
            return KADM5_AUX_ATTRIBUTES;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_API_VERSION"))
#ifdef KADM5_BAD_API_VERSION
            return KADM5_BAD_API_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_AUX_ATTR"))
#ifdef KADM5_BAD_AUX_ATTR
            return KADM5_BAD_AUX_ATTR;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_CLASS"))
#ifdef KADM5_BAD_CLASS
            return KADM5_BAD_CLASS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_CLIENT_PARAMS"))
#ifdef KADM5_BAD_CLIENT_PARAMS
            return KADM5_BAD_CLIENT_PARAMS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_DB"))
#ifdef KADM5_BAD_DB
            return KADM5_BAD_DB;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_HISTORY"))
#ifdef KADM5_BAD_HISTORY
            return KADM5_BAD_HISTORY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_HIST_KEY"))
#ifdef KADM5_BAD_HIST_KEY
            return KADM5_BAD_HIST_KEY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_LENGTH"))
#ifdef KADM5_BAD_LENGTH
            return KADM5_BAD_LENGTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_MASK"))
#ifdef KADM5_BAD_MASK
            return KADM5_BAD_MASK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_MIN_PASS_LIFE"))
#ifdef KADM5_BAD_MIN_PASS_LIFE
            return KADM5_BAD_MIN_PASS_LIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_PASSWORD"))
#ifdef KADM5_BAD_PASSWORD
            return KADM5_BAD_PASSWORD;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_POLICY"))
#ifdef KADM5_BAD_POLICY
            return KADM5_BAD_POLICY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_PRINCIPAL"))
#ifdef KADM5_BAD_PRINCIPAL
            return KADM5_BAD_PRINCIPAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_SERVER_HANDLE"))
#ifdef KADM5_BAD_SERVER_HANDLE
            return KADM5_BAD_SERVER_HANDLE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_SERVER_NAME"))
#ifdef KADM5_BAD_SERVER_NAME
            return KADM5_BAD_SERVER_NAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_SERVER_PARAMS"))
#ifdef KADM5_BAD_SERVER_PARAMS
            return KADM5_BAD_SERVER_PARAMS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_STRUCT_VERSION"))
#ifdef KADM5_BAD_STRUCT_VERSION
            return KADM5_BAD_STRUCT_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_BAD_TL_TYPE"))
#ifdef KADM5_BAD_TL_TYPE
            return KADM5_BAD_TL_TYPE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ACL_FILE"))
#ifdef KADM5_CONFIG_ACL_FILE
            return KADM5_CONFIG_ACL_FILE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ADBNAME"))
#ifdef KADM5_CONFIG_ADBNAME
            return KADM5_CONFIG_ADBNAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ADB_LOCKFILE"))
#ifdef KADM5_CONFIG_ADB_LOCKFILE
            return KADM5_CONFIG_ADB_LOCKFILE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ADMIN_KEYTAB"))
#ifdef KADM5_CONFIG_ADMIN_KEYTAB
            return KADM5_CONFIG_ADMIN_KEYTAB;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ADMIN_SERVER"))
#ifdef KADM5_CONFIG_ADMIN_SERVER
            return KADM5_CONFIG_ADMIN_SERVER;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_AUTH_NOFALLBACK"))
#ifdef KADM5_CONFIG_AUTH_NOFALLBACK
            return KADM5_CONFIG_AUTH_NOFALLBACK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_DBNAME"))
#ifdef KADM5_CONFIG_DBNAME
            return KADM5_CONFIG_DBNAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_DICT_FILE"))
#ifdef KADM5_CONFIG_DICT_FILE
            return KADM5_CONFIG_DICT_FILE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ENCTYPE"))
#ifdef KADM5_CONFIG_ENCTYPE
            return KADM5_CONFIG_ENCTYPE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_ENCTYPES"))
#ifdef KADM5_CONFIG_ENCTYPES
            return KADM5_CONFIG_ENCTYPES;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_EXPIRATION"))
#ifdef KADM5_CONFIG_EXPIRATION
            return KADM5_CONFIG_EXPIRATION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_FLAGS"))
#ifdef KADM5_CONFIG_FLAGS
            return KADM5_CONFIG_FLAGS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_KADMIND_PORT"))
#ifdef KADM5_CONFIG_KADMIND_PORT
            return KADM5_CONFIG_KADMIND_PORT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_KPASSWD_PORT"))
#ifdef KADM5_CONFIG_KPASSWD_PORT
            return KADM5_CONFIG_KPASSWD_PORT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_MAX_LIFE"))
#ifdef KADM5_CONFIG_MAX_LIFE
            return KADM5_CONFIG_MAX_LIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_MAX_RLIFE"))
#ifdef KADM5_CONFIG_MAX_RLIFE
            return KADM5_CONFIG_MAX_RLIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_MKEY_FROM_KBD"))
#ifdef KADM5_CONFIG_MKEY_FROM_KBD
            return KADM5_CONFIG_MKEY_FROM_KBD;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_MKEY_NAME"))
#ifdef KADM5_CONFIG_MKEY_NAME
            return KADM5_CONFIG_MKEY_NAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_NO_AUTH"))
#ifdef KADM5_CONFIG_NO_AUTH
            return KADM5_CONFIG_NO_AUTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_OLD_AUTH_GSSAPI"))
#ifdef KADM5_CONFIG_OLD_AUTH_GSSAPI
            return KADM5_CONFIG_OLD_AUTH_GSSAPI;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_PROFILE"))
#ifdef KADM5_CONFIG_PROFILE
            return KADM5_CONFIG_PROFILE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_REALM"))
#ifdef KADM5_CONFIG_REALM
            return KADM5_CONFIG_REALM;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_CONFIG_STASH_FILE"))
#ifdef KADM5_CONFIG_STASH_FILE
            return KADM5_CONFIG_STASH_FILE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_DUP"))
#ifdef KADM5_DUP
            return KADM5_DUP;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_FAILURE"))
#ifdef KADM5_FAILURE
            return KADM5_FAILURE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_FAIL_AUTH_COUNT"))
#ifdef KADM5_FAIL_AUTH_COUNT
            return KADM5_FAIL_AUTH_COUNT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_GSS_ERROR"))
#ifdef KADM5_GSS_ERROR
            return KADM5_GSS_ERROR;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_INIT"))
#ifdef KADM5_INIT
            return KADM5_INIT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_KEY_DATA"))
#ifdef KADM5_KEY_DATA
            return KADM5_KEY_DATA;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_KVNO"))
#ifdef KADM5_KVNO
            return KADM5_KVNO;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_LAST_FAILED"))
#ifdef KADM5_LAST_FAILED
            return KADM5_LAST_FAILED;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_LAST_PWD_CHANGE"))
#ifdef KADM5_LAST_PWD_CHANGE
            return KADM5_LAST_PWD_CHANGE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_LAST_SUCCESS"))
#ifdef KADM5_LAST_SUCCESS
            return KADM5_LAST_SUCCESS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MASK_BITS"))
#ifdef KADM5_MASK_BITS
            return KADM5_MASK_BITS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MAX_LIFE"))
#ifdef KADM5_MAX_LIFE
            return KADM5_MAX_LIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MAX_RLIFE"))
#ifdef KADM5_MAX_RLIFE
            return KADM5_MAX_RLIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MISSING_CONF_PARAMS"))
#ifdef KADM5_MISSING_CONF_PARAMS
            return KADM5_MISSING_CONF_PARAMS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MKVNO"))
#ifdef KADM5_MKVNO
            return KADM5_MKVNO;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MOD_NAME"))
#ifdef KADM5_MOD_NAME
            return KADM5_MOD_NAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_MOD_TIME"))
#ifdef KADM5_MOD_TIME
            return KADM5_MOD_TIME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NEW_LIB_API_VERSION"))
#ifdef KADM5_NEW_LIB_API_VERSION
            return KADM5_NEW_LIB_API_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NEW_SERVER_API_VERSION"))
#ifdef KADM5_NEW_SERVER_API_VERSION
            return KADM5_NEW_SERVER_API_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NEW_STRUCT_VERSION"))
#ifdef KADM5_NEW_STRUCT_VERSION
            return KADM5_NEW_STRUCT_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NOT_INIT"))
#ifdef KADM5_NOT_INIT
            return KADM5_NOT_INIT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NO_RENAME_SALT"))
#ifdef KADM5_NO_RENAME_SALT
            return KADM5_NO_RENAME_SALT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_NO_SRV"))
#ifdef KADM5_NO_SRV
            return KADM5_NO_SRV;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_OK"))
#ifdef KADM5_OK
            return KADM5_OK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_OLD_LIB_API_VERSION"))
#ifdef KADM5_OLD_LIB_API_VERSION
            return KADM5_OLD_LIB_API_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_OLD_SERVER_API_VERSION"))
#ifdef KADM5_OLD_SERVER_API_VERSION
            return KADM5_OLD_SERVER_API_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_OLD_STRUCT_VERSION"))
#ifdef KADM5_OLD_STRUCT_VERSION
            return KADM5_OLD_STRUCT_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PASS_Q_CLASS"))
#ifdef KADM5_PASS_Q_CLASS
            return KADM5_PASS_Q_CLASS;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PASS_Q_DICT"))
#ifdef KADM5_PASS_Q_DICT
            return KADM5_PASS_Q_DICT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PASS_Q_TOOSHORT"))
#ifdef KADM5_PASS_Q_TOOSHORT
            return KADM5_PASS_Q_TOOSHORT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PASS_REUSE"))
#ifdef KADM5_PASS_REUSE
            return KADM5_PASS_REUSE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PASS_TOOSOON"))
#ifdef KADM5_PASS_TOOSOON
            return KADM5_PASS_TOOSOON;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_POLICY"))
#ifdef KADM5_POLICY
            return KADM5_POLICY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_POLICY_CLR"))
#ifdef KADM5_POLICY_CLR
            return KADM5_POLICY_CLR;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_POLICY_REF"))
#ifdef KADM5_POLICY_REF
            return KADM5_POLICY_REF;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRINCIPAL"))
#ifdef KADM5_PRINCIPAL
            return KADM5_PRINCIPAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRINCIPAL_NORMAL_MASK"))
#ifdef KADM5_PRINCIPAL_NORMAL_MASK
            return KADM5_PRINCIPAL_NORMAL_MASK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRINC_EXPIRE_TIME"))
#ifdef KADM5_PRINC_EXPIRE_TIME
            return KADM5_PRINC_EXPIRE_TIME;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRIV_ADD"))
#ifdef KADM5_PRIV_ADD
            return KADM5_PRIV_ADD;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRIV_DELETE"))
#ifdef KADM5_PRIV_DELETE
            return KADM5_PRIV_DELETE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRIV_GET"))
#ifdef KADM5_PRIV_GET
            return KADM5_PRIV_GET;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PRIV_MODIFY"))
#ifdef KADM5_PRIV_MODIFY
            return KADM5_PRIV_MODIFY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PROTECT_PRINCIPAL"))
#ifdef KADM5_PROTECT_PRINCIPAL
            return KADM5_PROTECT_PRINCIPAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_EXPIRATION"))
#ifdef KADM5_PW_EXPIRATION
            return KADM5_PW_EXPIRATION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_HISTORY_NUM"))
#ifdef KADM5_PW_HISTORY_NUM
            return KADM5_PW_HISTORY_NUM;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_MAX_LIFE"))
#ifdef KADM5_PW_MAX_LIFE
            return KADM5_PW_MAX_LIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_MIN_CLASSES"))
#ifdef KADM5_PW_MIN_CLASSES
            return KADM5_PW_MIN_CLASSES;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_MIN_LENGTH"))
#ifdef KADM5_PW_MIN_LENGTH
            return KADM5_PW_MIN_LENGTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_MIN_LIFE"))
#ifdef KADM5_PW_MIN_LIFE
            return KADM5_PW_MIN_LIFE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_MAX_FAILURE"))
#ifdef KADM5_PW_MAX_FAILURE
            return KADM5_PW_MAX_FAILURE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_FAILURE_COUNT_INTERVAL"))
#ifdef KADM5_PW_FAILURE_COUNT_INTERVAL
            return KADM5_PW_FAILURE_COUNT_INTERVAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_PW_LOCKOUT_DURATION"))
#ifdef KADM5_PW_LOCKOUT_DURATION
            return KADM5_PW_LOCKOUT_DURATION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_REF_COUNT"))
#ifdef KADM5_REF_COUNT
            return KADM5_REF_COUNT;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_RPC_ERROR"))
#ifdef KADM5_RPC_ERROR
            return KADM5_RPC_ERROR;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_SECURE_PRINC_MISSING"))
#ifdef KADM5_SECURE_PRINC_MISSING
            return KADM5_SECURE_PRINC_MISSING;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_SETKEY3_ETYPE_MISMATCH"))
#ifdef KADM5_SETKEY3_ETYPE_MISMATCH
            return KADM5_SETKEY3_ETYPE_MISMATCH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_SETKEY_DUP_ENCTYPES"))
#ifdef KADM5_SETKEY_DUP_ENCTYPES
            return KADM5_SETKEY_DUP_ENCTYPES;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_SETV4KEY_INVAL_ENCTYPE"))
#ifdef KADM5_SETV4KEY_INVAL_ENCTYPE
            return KADM5_SETV4KEY_INVAL_ENCTYPE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_STRUCT_VERSION"))
#ifdef KADM5_STRUCT_VERSION
            return KADM5_STRUCT_VERSION;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_STRUCT_VERSION_1"))
#ifdef KADM5_STRUCT_VERSION_1
            return KADM5_STRUCT_VERSION_1;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_STRUCT_VERSION_MASK"))
#ifdef KADM5_STRUCT_VERSION_MASK
            return KADM5_STRUCT_VERSION_MASK;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_TL_DATA"))
#ifdef KADM5_TL_DATA
            return KADM5_TL_DATA;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_UNK_POLICY"))
#ifdef KADM5_UNK_POLICY
            return KADM5_UNK_POLICY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KADM5_UNK_PRINC"))
#ifdef KADM5_UNK_PRINC
            return KADM5_UNK_PRINC;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_ALL_TIX"))
#ifdef KRB5_KDB_DISALLOW_ALL_TIX
            return KRB5_KDB_DISALLOW_ALL_TIX;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_DUP_SKEY"))
#ifdef KRB5_KDB_DISALLOW_DUP_SKEY
            return KRB5_KDB_DISALLOW_DUP_SKEY;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_FORWARDABLE"))
#ifdef KRB5_KDB_DISALLOW_FORWARDABLE
            return KRB5_KDB_DISALLOW_FORWARDABLE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_POSTDATED"))
#ifdef KRB5_KDB_DISALLOW_POSTDATED
            return KRB5_KDB_DISALLOW_POSTDATED;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_PROXIABLE"))
#ifdef KRB5_KDB_DISALLOW_PROXIABLE
            return KRB5_KDB_DISALLOW_PROXIABLE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_RENEWABLE"))
#ifdef KRB5_KDB_DISALLOW_RENEWABLE
            return KRB5_KDB_DISALLOW_RENEWABLE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_SVR"))
#ifdef KRB5_KDB_DISALLOW_SVR
            return KRB5_KDB_DISALLOW_SVR;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_DISALLOW_TGT_BASED"))
#ifdef KRB5_KDB_DISALLOW_TGT_BASED
            return KRB5_KDB_DISALLOW_TGT_BASED;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_NEW_PRINC"))
#ifdef KRB5_KDB_NEW_PRINC
            return KRB5_KDB_NEW_PRINC;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_REQUIRES_HW_AUTH"))
#ifdef KRB5_KDB_REQUIRES_HW_AUTH
            return KRB5_KDB_REQUIRES_HW_AUTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_REQUIRES_PRE_AUTH"))
#ifdef KRB5_KDB_REQUIRES_PRE_AUTH
            return KRB5_KDB_REQUIRES_PRE_AUTH;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_REQUIRES_PWCHANGE"))
#ifdef KRB5_KDB_REQUIRES_PWCHANGE
            return KRB5_KDB_REQUIRES_PWCHANGE;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_AFS3"))
#ifdef KRB5_KDB_SALTTYPE_AFS3
            return KRB5_KDB_SALTTYPE_AFS3;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_NOREALM"))
#ifdef KRB5_KDB_SALTTYPE_NOREALM
            return KRB5_KDB_SALTTYPE_NOREALM;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_NORMAL"))
#ifdef KRB5_KDB_SALTTYPE_NORMAL
            return KRB5_KDB_SALTTYPE_NORMAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_ONLYREALM"))
#ifdef KRB5_KDB_SALTTYPE_ONLYREALM
            return KRB5_KDB_SALTTYPE_ONLYREALM;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_SPECIAL"))
#ifdef KRB5_KDB_SALTTYPE_SPECIAL
            return KRB5_KDB_SALTTYPE_SPECIAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SALTTYPE_V4"))
#ifdef KRB5_KDB_SALTTYPE_V4
            return KRB5_KDB_SALTTYPE_V4;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_SUPPORT_DESMD5"))
#ifdef KRB5_KDB_SUPPORT_DESMD5
            return KRB5_KDB_SUPPORT_DESMD5;
#else
            goto not_there;
#endif
        if (strEQ(name, "KRB5_KDB_ACCESS_ERROR"))
#ifdef KRB5_KDB_ACCESS_ERROR
            return KRB5_KDB_ACCESS_ERROR;
#else
            goto not_there;
#endif
        break;
    }
    errno = EINVAL;
    return 0;

 not_there:
    errno = ENOENT;
    return 0;
}

static kadm5_ret_t err;

#ifdef KADM5_API_VERSION_3
/* krb5 1.8+ requires a context argument for init_with_* functions */
static krb5_context context = NULL;
#endif

/*
 * Some Kerberos data objects contain others, so we don't always want
 * to free an object when the Perl program is done with it.  For
 * example, kadm5_principal_ent_rec contains a couple of
 * krb5_principals, but we don't necessarily want them freed when the
 * SVs referring to them go out of scope because we still have the
 * kadm5_principal_ent_rec pointing to them.
 *
 * Authen::Krb5 solves this by remembering every independently created
 * object so that no contained objects are freed.  Unfortunately, this
 * approach causes all child objects to become invalid once the parent
 * is destroyed.  So instead, create meta-structures containing, in
 * addition to the Kerberos data itself, pointers to SVs to which we
 * return references.  We account for the parent's dependency on the
 * child in the reference count of the SV.  When it's time to destroy
 * a parent object, we decrease the reference counts, and we don't use
 * the Kerberos free functions.
 *
 * The policy and principal methods keep track of the mask in the
 * meta-struct so the user doesn't have to.  They assume that if the
 * user set the value, it should be changed.
 */

struct kadm5_policy_mit {
    kadm5_policy_ent_rec policy;
    long                 mask;
};

struct kadm5_principal_mit {
    kadm5_principal_ent_rec   kadm5_princ;
    SV                      **key_data;
    SV                       *krb5_princ;
    SV                       *krb5_princ_mod;
    long                      mask;
};

/* for zeroing structs */

static struct kadm5_policy_mit    kadm5_policy_mit_init;
static struct kadm5_principal_mit kadm5_principal_mit_init;
static kadm5_config_params        kadm5_config_params_init;
static krb5_key_data              krb5_key_data_init;

typedef kadm5_config_params        *Authen__Krb5__Admin__Config;
typedef krb5_ccache                 Authen__Krb5__Ccache;
typedef krb5_key_data              *Authen__Krb5__Admin__Key;
typedef krb5_keyblock              *Authen__Krb5__Keyblock;
typedef krb5_principal              Authen__Krb5__Principal;
typedef struct kadm5_policy_mit    *Authen__Krb5__Admin__Policy;
typedef struct kadm5_principal_mit *Authen__Krb5__Admin__Principal;
typedef void                       *Authen__Krb5__Admin;

/*
 * The Authen::Krb5::Admin object is just the void * returned by the
 * init functions, init_with_{creds,password,skey}, which are this
 * package's constructors.
 */

MODULE = Authen::Krb5::Admin    PACKAGE = Authen::Krb5::Admin   PREFIX = kadm5_

double
constant(name, arg)
    char    *name
    int  arg

void
kadm5_chpass_principal(handle, princ, pw)
    Authen::Krb5::Admin      handle
    Authen::Krb5::Principal  princ
    char                    *pw
  CODE:
    err = kadm5_chpass_principal(handle, princ, pw);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_create_policy(handle, policy)
    Authen::Krb5::Admin         handle
    Authen::Krb5::Admin::Policy policy
  CODE:
    err = kadm5_create_policy(handle, &policy->policy, policy->mask);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_create_principal(handle, princ, pw = "")
    Authen::Krb5::Admin             handle
    Authen::Krb5::Admin::Principal  princ
    char                           *pw
  CODE:
    err = kadm5_create_principal(handle, &princ->kadm5_princ,
      princ->mask & ~(KADM5_POLICY_CLR | KADM5_FAIL_AUTH_COUNT), pw);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_delete_policy(handle, name)
    Authen::Krb5::Admin  handle
    char                *name
  CODE:
    err = kadm5_delete_policy(handle, name);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_delete_principal(handle, princ)
    Authen::Krb5::Admin     handle
    Authen::Krb5::Principal princ
  CODE:
    err = kadm5_delete_principal(handle, princ);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_error(e = 0)
    kadm5_ret_t e;
  CODE:
    if (e)
        ST(0) = sv_2mortal(newSVpv((char *)error_message(e), 0));
    else {
        ST(0) = sv_2mortal(newSVpv((char *)error_message(err), 0));
        SvUPGRADE(ST(0), SVt_PVIV);
        SvIVX(ST(0)) = err;
        SvIOK_on(ST(0));
    }

int
kadm5_error_code()
  CODE:
    RETVAL = err;
  OUTPUT:
    RETVAL

Authen::Krb5::Admin::Policy
kadm5_get_policy(handle, name = "default")
    Authen::Krb5::Admin  handle
    char                *name
  CODE:
    New(0, RETVAL, 1, struct kadm5_policy_mit);
    *RETVAL = kadm5_policy_mit_init;
    err = kadm5_get_policy(handle, name, &RETVAL->policy);
    if (err)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

void
kadm5_get_policies(handle, exp = NULL)
    Authen::Krb5::Admin  handle
    char                *exp
  PREINIT:
    char **pols;
    int    count;
    int    i;
  PPCODE:
    err = kadm5_get_policies(handle, exp, &pols, &count);
    if (err)
        XSRETURN_EMPTY;
    EXTEND(sp, count);
    for (i = 0; i < count; i++)
        PUSHs(sv_2mortal(newSVpv(pols[i], 0)));
    kadm5_free_name_list(handle, pols, count);
    XSRETURN(count);

Authen::Krb5::Admin::Principal
kadm5_get_principal(handle, krb5_princ, mask = KADM5_PRINCIPAL_NORMAL_MASK)
    Authen::Krb5::Admin     handle
    Authen::Krb5::Principal krb5_princ
    long                    mask
  PREINIT:
    char *tmp_policy;
    int   i;
    STRLEN len;
  CODE:
    New(0, RETVAL, 1, struct kadm5_principal_mit);  
    *RETVAL = kadm5_principal_mit_init;
    err = kadm5_get_principal(handle, krb5_princ, &RETVAL->kadm5_princ, mask);
    if (err)
        XSRETURN_UNDEF;
    if (RETVAL->kadm5_princ.n_key_data) {
        New(0, RETVAL->key_data, RETVAL->kadm5_princ.n_key_data, SV *);
        for (i = 0; i < RETVAL->kadm5_princ.n_key_data; i++) {
            krb5_key_data *p;
            New(0, p, 1, krb5_key_data);
            Copy(&RETVAL->kadm5_princ.key_data[i], p, 1, krb5_key_data);
            RETVAL->key_data[i] = newSViv(PTR2IV(p));
        }
    }
    RETVAL->krb5_princ = newSViv(PTR2IV(RETVAL->kadm5_princ.principal));
    RETVAL->krb5_princ_mod =
    newSViv(PTR2IV(RETVAL->kadm5_princ.mod_name));

    /*
     * When kadm5_get_principal() builds a kadm5_principal_ent_rec, it
     * malloc()s space for a policy name if the principal is
     * associated with one.  But when we build a
     * kadm5_principal_ent_rec (e.g., with Policy->name()), we use
     * New(), not malloc().  In DESTROY(), we don't want to Safefree()
     * memory not allocated with New(), so here we copy the policy
     * name to memory allocated with New() and free() what we were
     * handed by kadm5_get_principal().
     */

    if (RETVAL->kadm5_princ.policy) {
        len = strlen(RETVAL->kadm5_princ.policy);
        New(0, tmp_policy, len + 1, char);
        Copy(RETVAL->kadm5_princ.policy, tmp_policy, len + 1, char);
        free(RETVAL->kadm5_princ.policy);
        RETVAL->kadm5_princ.policy = tmp_policy;
    }
  OUTPUT:
    RETVAL

void
kadm5_get_principals(handle, exp = NULL)
    Authen::Krb5::Admin  handle
    char                *exp
  PREINIT:
    char **princs;
    int    count;
    int    i;
  PPCODE:
    err = kadm5_get_principals(handle, exp, &princs, &count);
    if (err)
        XSRETURN_EMPTY;
    EXTEND(sp, count);
    for (i = 0; i < count; i++)
        PUSHs(sv_2mortal(newSVpv(princs[i], 0)));
    kadm5_free_name_list(handle, princs, count);
    XSRETURN(count);

void
kadm5_get_privs(handle)
    Authen::Krb5::Admin handle
  PREINIT:
    long privs;
  CODE:
    err = kadm5_get_privs(handle, &privs);
    ST(0) = err ? &PL_sv_undef : sv_2mortal(newSViv(privs));

Authen::Krb5::Admin
kadm5_init_with_creds(CLASS, client, cc, service = KADM5_ADMIN_SERVICE, config = NULL, struct_version = KADM5_STRUCT_VERSION, api_version = KADM5_API_VERSION_2)
    char                        *CLASS
    char                        *client
    Authen::Krb5::Ccache         cc
    char                        *service
    Authen::Krb5::Admin::Config  config
    krb5_ui_4                    struct_version
    krb5_ui_4                    api_version
  CODE:
#ifdef KRB5_PLUGIN_NO_HANDLE    /* hack to test for 1.5 */
#ifdef KADM5_API_VERSION_3
    if (!context) {
        err = krb5_init_context(&context);
        if (err) die("Unable to initialize context");
    }
    err = kadm5_init_with_creds(context, client, cc, service, config,
      struct_version, api_version, NULL, &RETVAL);
#else
    err = kadm5_init_with_creds(client, cc, service, config, struct_version,
      api_version, NULL, &RETVAL);
#endif
#else
    err = kadm5_init_with_creds(client, cc, service, config, struct_version,
      api_version, &RETVAL);
#endif
    if (err)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

Authen::Krb5::Admin
kadm5_init_with_password(CLASS, client, pw = NULL, service = KADM5_ADMIN_SERVICE, config = NULL, struct_version = KADM5_STRUCT_VERSION, api_version = KADM5_API_VERSION_2)
    char                        *CLASS
    char                        *client
    char                        *pw
    char                        *service
    Authen::Krb5::Admin::Config  config
    krb5_ui_4                    struct_version
    krb5_ui_4                    api_version
  CODE:
#ifdef KRB5_PLUGIN_NO_HANDLE    /* hack to test for 1.5 */
#ifdef KADM5_API_VERSION_3
    if (!context) {
        err = krb5_init_context(&context);
        if (err) die("Unable to initialize context");
    }
    err = kadm5_init_with_password(context, client, pw, service,
      config, struct_version, api_version, NULL, &RETVAL);
#else
    err = kadm5_init_with_password(client, pw, service, config, struct_version,
      api_version, NULL, &RETVAL);
#endif
#else
    err = kadm5_init_with_password(client, pw, service, config, struct_version,
      api_version, &RETVAL);
#endif
    if (err)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

Authen::Krb5::Admin
kadm5_init_with_skey(CLASS, client, keytab = NULL, service = KADM5_ADMIN_SERVICE, config = NULL, struct_version = KADM5_STRUCT_VERSION, api_version = KADM5_API_VERSION_2)
    char                        *CLASS
    char                        *client
    char                        *keytab
    char                        *service
    Authen::Krb5::Admin::Config  config
    krb5_ui_4                    struct_version
    krb5_ui_4                    api_version
  CODE:
#ifdef KRB5_PLUGIN_NO_HANDLE    /* hack to test for 1.5 */
#ifdef KADM5_API_VERSION_3
    if (!context) {
        err = krb5_init_context(&context);
        if (err) die("Unable to initialize context");
    }
    err = kadm5_init_with_skey(context, client, keytab, service,
      config, struct_version, api_version, NULL, &RETVAL);
#else
    err = kadm5_init_with_skey(client, keytab, service, config, struct_version,
      api_version, NULL, &RETVAL);
#endif
#else
    err = kadm5_init_with_skey(client, keytab, service, config, struct_version,
      api_version, &RETVAL);
#endif
    if (err)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

void
kadm5_modify_policy(handle, policy)
    Authen::Krb5::Admin         handle
    Authen::Krb5::Admin::Policy policy
  CODE:
    err = kadm5_modify_policy(handle, &policy->policy,
      policy->mask & ~KADM5_POLICY);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_modify_principal(handle, princ)
    Authen::Krb5::Admin            handle
    Authen::Krb5::Admin::Principal princ
  CODE:
    err = kadm5_modify_principal(handle, &princ->kadm5_princ,
        princ->mask & ~KADM5_PRINCIPAL);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
kadm5_randkey_principal(handle, princ)
    Authen::Krb5::Admin     handle
    Authen::Krb5::Principal princ
  PREINIT:
    krb5_keyblock *keys;
    int            count, i;
  PPCODE:
    err = kadm5_randkey_principal(handle, princ, &keys, &count);
    if (err)
        XSRETURN_EMPTY;
    EXTEND(sp, count);
    for (i = 0; i < count; i++) {
        ST(i) = sv_newmortal();
        sv_setref_pv(ST(i), "Authen::Krb5::Keyblock", &keys[i]);
    }
    XSRETURN(count);

void
kadm5_rename_principal(handle, source, target)
    Authen::Krb5::Admin     handle
    Authen::Krb5::Principal source
    Authen::Krb5::Principal target
  CODE:
    err = kadm5_rename_principal(handle, source, target);
    if (err)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
DESTROY(handle)
    Authen::Krb5::Admin handle
  CODE:
    err = kadm5_destroy(handle);
    if (err)    
        XSRETURN_UNDEF;
    XSRETURN_YES;

 # 
 # kadm5_config_params class
 # 

MODULE = Authen::Krb5::Admin    PACKAGE = Authen::Krb5::Admin::Config

Authen::Krb5::Admin::Config
new(CLASS)
    char *CLASS
  CODE:
    New(0, RETVAL, 1, kadm5_config_params);
    *RETVAL = kadm5_config_params_init;
  OUTPUT:
    RETVAL

char *
admin_server(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  PREINIT:
    STRLEN len;
  CODE:
    if (items > 1) {
        char *admin_server;
        admin_server = SvPV(ST(1), len);
        if (config->admin_server) {
            Safefree(config->admin_server);
            config->admin_server = NULL;
        }
        New(0, config->admin_server, len + 1, char);
        Copy(admin_server, config->admin_server, len + 1, char);
        config->mask |= KADM5_CONFIG_ADMIN_SERVER;
    }
    ST(0) = config->admin_server
      ? sv_2mortal(newSVpv(config->admin_server, 0))
      : &PL_sv_undef;

long
kadmind_port(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        config->kadmind_port = SvIV(ST(1));
        config->mask |= KADM5_CONFIG_KADMIND_PORT;
    }
    RETVAL = config->kadmind_port;
  OUTPUT:
    RETVAL

long
kpasswd_port(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        config->kpasswd_port = SvIV(ST(1));
        config->mask |= KADM5_CONFIG_KPASSWD_PORT;
    }
    RETVAL = config->kpasswd_port;
  OUTPUT:
    RETVAL

long
mask(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        config->mask = SvIV(ST(1));
    RETVAL = config->mask;
  OUTPUT:
    RETVAL

#ifdef KADM5_CONFIG_PROFILE
char *
profile(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  PREINIT:
    STRLEN len;
  CODE:
    if (items > 1) {
        char *profile;
        profile = SvPV(ST(1), len);
        if (config->profile) {
            Safefree(config->profile);
            config->profile = NULL;
        }
        New(0, config->profile, len + 1, char);
        Copy(profile, config->profile, len + 1, char);
        config->mask |= KADM5_CONFIG_PROFILE;
    }
    ST(0) = config->profile
      ? sv_2mortal(newSVpv(config->profile, 0))
      : &PL_sv_undef;

#endif

char *
realm(config, ...)
    Authen::Krb5::Admin::Config config
  PROTOTYPE: $;$
  PREINIT:
    STRLEN len;
  CODE:
    if (items > 1) {
        char *realm;
        realm = SvPV(ST(1), len);
        if (config->realm) {
            Safefree(config->realm);
            config->realm = NULL;
        }
        New(0, config->realm, len + 1, char);
        Copy(realm, config->realm, len + 1, char);
        config->mask |= KADM5_CONFIG_REALM;
    }
    ST(0) = config->realm
      ? sv_2mortal(newSVpv(config->realm, 0))
      : &PL_sv_undef;

void
DESTROY(config)
    Authen::Krb5::Admin::Config config
  CODE:
    if (config) {
#ifdef KADM5_CONFIG_PROFILE
        if (config->profile)
            Safefree(config->profile);
#endif
        if (config->dbname)
            Safefree(config->dbname);
        if (config->mkey_name)
            Safefree(config->mkey_name);
        if (config->stash_file)
            Safefree(config->stash_file);
        if (config->keysalts)
            Safefree(config->keysalts);
        if (config->admin_server)
            Safefree(config->admin_server);
/* admin_keytab was removed in API_VERSION 4 */
#ifndef KADM5_API_VERSION_4
        if (config->admin_keytab)
            Safefree(config->admin_keytab);
#endif
        if (config->dict_file)
            Safefree(config->dict_file);
        if (config->acl_file)
            Safefree(config->acl_file);
        if (config->realm)
            Safefree(config->realm);
#ifndef KADM5_API_VERSION_3
        if (config->admin_dbname)
            Safefree(config->admin_dbname);
        if (config->admin_lockfile)
            Safefree(config->admin_lockfile);
#endif

    }
    Safefree(config);

 # 
 # krb5_key_data class--for key data returned by get_principal
 # 

MODULE = Authen::Krb5::Admin    PACKAGE = Authen::Krb5::Admin::Key

Authen::Krb5::Admin::Key
new(CLASS)
    char *CLASS
  CODE:
    New(0, RETVAL, 1, krb5_key_data);
    *RETVAL = krb5_key_data_init;
  OUTPUT:
    RETVAL

krb5_octet *
_contents(key, ...)
    Authen::Krb5::Admin::Key key
  ALIAS:
    key_contents = 0
    salt_contents = 1
  PROTOTYPE: $;$
  CODE:
    if (key->key_data_ver > ix) {
        if (items > 1) {
            if (key->key_data_contents[ix]) {
                memset(key->key_data_contents[ix], 0,
                  key->key_data_length[ix]);
                Safefree(key->key_data_contents[ix]);
            }
            New(0, key->key_data_contents[ix], key->key_data_length[ix],
              krb5_octet);
            Copy(INT2PTR(void *, SvIV(ST(1))), key->key_data_contents[ix],
              key->key_data_length[ix], krb5_octet);
        }
        ST(0) = key->key_data_contents[ix]
          ? sv_2mortal(newSVpv(key->key_data_contents[ix],
            key->key_data_length[ix]))
          : &PL_sv_undef;
    } else
        ST(0) = &PL_sv_undef;

krb5_int16
_type(key, ...)
    Authen::Krb5::Admin::Key key
  ALIAS:
    enc_type = 0
    key_type = 0
    salt_type = 1
  PROTOTYPE: $;$
  CODE:
    if (key->key_data_ver > ix) {
        if (items > 1)
            key->key_data_type[ix] = SvIV(ST(1));
        RETVAL = key->key_data_type[ix];
    } else {
        RETVAL = -1;
    }
  OUTPUT:
    RETVAL

krb5_int16
kvno(key, ...)
    Authen::Krb5::Admin::Key key
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        key->key_data_kvno = SvIV(ST(1));
    RETVAL = key->key_data_kvno;
  OUTPUT:
    RETVAL

krb5_int16
ver(key, ...)
    Authen::Krb5::Admin::Key key
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        key->key_data_ver = SvIV(ST(1));
    RETVAL = key->key_data_ver;
  OUTPUT:
    RETVAL

void
DESTROY(key)
    Authen::Krb5::Admin::Key    key
  PREINIT:
    int i, n;
  CODE:
    n = key->key_data_ver == 1 ? 1 : 2;
    for (i = 0; i < n; i++)
        if (key->key_data_contents[i]) {
            memset(key->key_data_contents[i], 0, key->key_data_length[i]);
            Safefree(key->key_data_contents[i]);
        }
    Safefree(key);

 # 
 # kadm5_policy_ent_rec class--uses kadm5_policy_mit meta-struct
 # 

MODULE = Authen::Krb5::Admin    PACKAGE = Authen::Krb5::Admin::Policy

Authen::Krb5::Admin::Policy
new(CLASS)
    char *CLASS
  CODE:
    New(0, RETVAL, 1, struct kadm5_policy_mit);
    *RETVAL = kadm5_policy_mit_init;
  OUTPUT:
    RETVAL

long
mask(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        policy->mask = SvIV(ST(1));
    RETVAL = policy->mask;
  OUTPUT:
    RETVAL

void
name(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  PREINIT:
    STRLEN len;
  CODE:
    if (items > 1) {
        char *source;
        source = SvPV(ST(1), len);
        if (policy->policy.policy) {
            Safefree(policy->policy.policy);
            policy->policy.policy = NULL;
        }
        New(0, policy->policy.policy, len + 1, char);
        Copy(source, policy->policy.policy, len + 1, char);
        policy->mask |= KADM5_POLICY;
    }
    ST(0) = policy->policy.policy
      ? sv_2mortal(newSVpv(policy->policy.policy, 0))
      : &PL_sv_undef;

long
pw_history_num(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_history_num = SvIV(ST(1));
        policy->mask |= KADM5_PW_HISTORY_NUM;
    }
    RETVAL = policy->policy.pw_history_num;
  OUTPUT:
    RETVAL

long
pw_max_life(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_max_life = SvIV(ST(1));
        policy->mask |= KADM5_PW_MAX_LIFE;
    }
    RETVAL = policy->policy.pw_max_life;
  OUTPUT:
    RETVAL

#ifdef KADM5_API_VERSION_3 /* new lockout attributes */

krb5_kvno
pw_max_fail(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_max_fail = SvIV(ST(1));
        policy->mask |= KADM5_PW_MAX_FAILURE;
    }
    RETVAL = policy->policy.pw_max_fail;
  OUTPUT:
    RETVAL

krb5_deltat
pw_failcnt_interval(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_failcnt_interval = SvIV(ST(1));
        policy->mask |= KADM5_PW_FAILURE_COUNT_INTERVAL;
    }
    RETVAL = policy->policy.pw_failcnt_interval;
  OUTPUT:
    RETVAL

krb5_deltat
pw_lockout_duration(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_lockout_duration = SvIV(ST(1));
        policy->mask |= KADM5_PW_LOCKOUT_DURATION;
    }
    RETVAL = policy->policy.pw_lockout_duration;
  OUTPUT:
    RETVAL

#endif /* KADM5_API_VERSION_3 - lockout attributes */

long
pw_min_classes(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_min_classes = SvIV(ST(1));
        policy->mask |= KADM5_PW_MIN_CLASSES;
    }
    RETVAL = policy->policy.pw_min_classes;
  OUTPUT:
    RETVAL

long
pw_min_length(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_min_length = SvIV(ST(1));
        policy->mask |= KADM5_PW_MIN_LENGTH;
    }
    RETVAL = policy->policy.pw_min_length;
  OUTPUT:
    RETVAL

long
pw_min_life(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        policy->policy.pw_min_life = SvIV(ST(1));
        policy->mask |= KADM5_PW_MIN_LIFE;
    }
    RETVAL = policy->policy.pw_min_life;
  OUTPUT:
    RETVAL

long
policy_refcnt(policy, ...)
    Authen::Krb5::Admin::Policy policy
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        policy->policy.policy_refcnt = SvIV(ST(1));
    RETVAL = policy->policy.policy_refcnt;
  OUTPUT:
    RETVAL

void
DESTROY(policy)
    Authen::Krb5::Admin::Policy policy
  CODE:
    if (policy->policy.policy) {
        Safefree(policy->policy.policy);
        policy->policy.policy = NULL;
    }
    Safefree(policy);

 # 
 # kadm5_principal_ent_rec class--uses kadm5_principal_mit meta-struct
 # 

MODULE = Authen::Krb5::Admin    PACKAGE = Authen::Krb5::Admin::Principal

Authen::Krb5::Admin::Principal
new(CLASS)
    char *CLASS
  CODE:
    New(0, RETVAL, 1, struct kadm5_principal_mit);
    *RETVAL = kadm5_principal_mit_init;
    if (!RETVAL)
        XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

krb5_flags
attributes(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.attributes = SvIV(ST(1));
        princ->mask |= KADM5_ATTRIBUTES;
    }
    RETVAL = princ->kadm5_princ.attributes;
  OUTPUT:
    RETVAL

long
aux_attributes(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.aux_attributes = SvIV(ST(1));
    RETVAL = princ->kadm5_princ.aux_attributes;
  OUTPUT:
    RETVAL

krb5_kvno
fail_auth_count(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.fail_auth_count = SvIV(ST(1));
        princ->mask |= KADM5_FAIL_AUTH_COUNT;
    }
    RETVAL = princ->kadm5_princ.fail_auth_count;
  OUTPUT:
    RETVAL

void
key_data(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  PREINIT:
    SV  **p;
    int   n;
  PPCODE:
    n = princ->kadm5_princ.n_key_data;
    if (items > 1) {
        for (p = princ->key_data; n--; p++)
            SvREFCNT_dec(*p);
        Renew(princ->key_data, items - 1, SV *);
        Renew(princ->kadm5_princ.key_data, items - 1, krb5_key_data);
        for (n = 0; n < items - 1; n++) {
            krb5_key_data *p;
            New(0, p, 1, krb5_key_data);
            Copy(INT2PTR(void *, SvIV(SvRV(ST(n + 1)))), p, 1, krb5_key_data);
            princ->key_data[n] = newSViv(PTR2IV(p));
            Copy(p, &princ->kadm5_princ.key_data[n], 1, krb5_key_data);
        }
        princ->kadm5_princ.n_key_data = items - 1;
        princ->mask |= KADM5_KEY_DATA;
    }
    n = princ->kadm5_princ.n_key_data;
    if (n > 0) {
        EXTEND(sp, n);
        for (p = princ->key_data; n--; p++)
            PUSHs(sv_2mortal(sv_bless(newRV_inc(*p),
              gv_stashpv("Authen::Krb5::Admin::Key", 0))));
    }

krb5_kvno
kvno(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.kvno = SvUV(ST(1));
        princ->mask |= KADM5_KVNO;
    }
    RETVAL = princ->kadm5_princ.kvno;
  OUTPUT:
    RETVAL

krb5_timestamp
last_failed(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.last_failed = SvIV(ST(1));
    RETVAL = princ->kadm5_princ.last_failed;
  OUTPUT:
    RETVAL

krb5_timestamp
last_pwd_change(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.last_pwd_change = SvIV(ST(1));
    RETVAL = princ->kadm5_princ.last_pwd_change;
  OUTPUT:
    RETVAL

krb5_timestamp
last_success(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.last_success = SvIV(ST(1));
    RETVAL = princ->kadm5_princ.last_success;
  OUTPUT:
    RETVAL

long
mask(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->mask = SvIV(ST(1));
    RETVAL = princ->mask;
  OUTPUT:
    RETVAL

krb5_deltat
max_life(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.max_life = SvIV(ST(1));
        princ->mask |= KADM5_MAX_LIFE;
    }
    RETVAL = princ->kadm5_princ.max_life;
  OUTPUT:
    RETVAL

krb5_deltat
max_renewable_life(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.max_renewable_life = SvIV(ST(1));
        princ->mask |= KADM5_MAX_RLIFE;
    }
    RETVAL = princ->kadm5_princ.max_renewable_life;
  OUTPUT:
    RETVAL

krb5_kvno
mkvno(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.mkvno = SvUV(ST(1));
    RETVAL = princ->kadm5_princ.mkvno;
  OUTPUT:
    RETVAL

krb5_timestamp
mod_date(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1)
        princ->kadm5_princ.mod_date = SvIV(ST(1));
    RETVAL = princ->kadm5_princ.mod_date;
  OUTPUT:
    RETVAL

void
mod_name(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        if (princ->krb5_princ_mod && SvIOK(princ->krb5_princ_mod))
            SvREFCNT_dec(princ->krb5_princ_mod);
        princ->krb5_princ_mod = SvRV(ST(1));
        princ->kadm5_princ.principal =
          INT2PTR(krb5_principal, SvIV(princ->krb5_princ_mod));
        SvREFCNT_inc(princ->krb5_princ_mod);
    }
    ST(0) = sv_2mortal(sv_bless(newRV_inc(princ->krb5_princ_mod),
      gv_stashpv("Authen::Krb5::Principal", 0)));

char *
policy(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  PREINIT:
    STRLEN len;
  CODE:
    if (items > 1) {
        char *policy;
        policy = SvPV(ST(1), len);
        if (princ->kadm5_princ.policy) {
            Safefree(princ->kadm5_princ.policy);
            princ->kadm5_princ.policy = NULL;
        }
        New(0, princ->kadm5_princ.policy, len + 1, char);
        Copy(policy, princ->kadm5_princ.policy, len + 1, char);
        princ->mask |= KADM5_POLICY;
        princ->mask &= ~KADM5_POLICY_CLR;
    }
    ST(0) = princ->kadm5_princ.policy
      ? sv_2mortal(newSVpv(princ->kadm5_princ.policy, 0))
      : &PL_sv_undef;

void
policy_clear(princ)
    Authen::Krb5::Admin::Principal princ
  CODE:
    if (princ->kadm5_princ.policy) {
        Safefree(princ->kadm5_princ.policy);
        princ->kadm5_princ.policy = NULL;
    }
    princ->mask &= ~KADM5_POLICY;
    princ->mask |= KADM5_POLICY_CLR;

krb5_timestamp
princ_expire_time(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.princ_expire_time = SvIV(ST(1));
        princ->mask |= KADM5_PRINC_EXPIRE_TIME;
    }
    RETVAL = princ->kadm5_princ.princ_expire_time;
  OUTPUT:
    RETVAL

void
principal(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        if (princ->krb5_princ && SvIOK(princ->krb5_princ))
            SvREFCNT_dec(princ->krb5_princ);
        princ->krb5_princ = SvRV(ST(1));
        princ->kadm5_princ.principal =
          INT2PTR(krb5_principal, SvIV(princ->krb5_princ));
        SvREFCNT_inc(princ->krb5_princ);
        princ->mask |= KADM5_PRINCIPAL;
    }
    ST(0) = sv_2mortal(sv_bless(newRV_inc(princ->krb5_princ),
      gv_stashpv("Authen::Krb5::Principal", 0)));

krb5_timestamp
pw_expiration(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;$
  CODE:
    if (items > 1) {
        princ->kadm5_princ.pw_expiration = SvIV(ST(1));
        princ->mask |= KADM5_PW_EXPIRATION;
    }
    RETVAL = princ->kadm5_princ.pw_expiration;
  OUTPUT:
    RETVAL

#ifdef HAVE_KDB_H

void
db_args(princ, ...)
    Authen::Krb5::Admin::Principal princ
  PROTOTYPE: $;@
  PREINIT:
    krb5_tl_data *tl, *last_tl;
    krb5_octet **db_args;
    int i;

  PPCODE:
    /* arglist will be items - 1, but the last item should be a NULL. */
    Newxz(db_args, items, krb5_octet *);

    /* pull db args off the stack */
    /* grab the arg stack */
    for (i = 1; i < items; i++) {
        krb5_octet *this_arg;
        STRLEN length = sv_len(ST(i)) + 1;
        /* Perl_croak(aTHX_ "%d", length);*/
        Newxz(this_arg, length, krb5_octet);
        Copy((krb5_octet *)SvPV(ST(i), length), this_arg, length, krb5_octet);
        /* db_args[i - 1] = (krb5_octet *)SvPV_nolen(ST(i)); */
        db_args[i - 1] = this_arg;
    }

    last_tl = NULL;
    tl      = princ->kadm5_princ.tl_data;
    while (tl != NULL) {
        krb5_tl_data *next_tl = tl->tl_data_next;

        /* bail out early for anything but db_args */
        if (tl->tl_data_type != KRB5_TL_DB_ARGS) {
            last_tl = tl;
            tl      = next_tl;
            continue;
        }

        /* otherwise: */

        /* pinched from kdb5.c */
        if (((char *) tl->tl_data_contents)[tl->tl_data_length - 1] != '\0') {
            /* croak */
            Perl_croak(aTHX_ "Unsafe string in principal tail data");
        }
        else {
            SV * tl_out;
            
            tl_out = newSVpv((const char *) tl->tl_data_contents, 0);
            XPUSHs(tl_out);

            /* extend and push the stack with a new mortal SvPV */
            /* mXPUSHp((char *) tl->tl_data_contents, tl->tl_data_length - 1); */
            /* only two hard things in computer science: cache
               expiration, naming things, and off-by-one errors. */

            /* PS that copies the string, right? because i'm about to
               nuke it. */
    
            /* we're only doing surgery if there is something to
               replace these with */
            if (items > 1) {
                /* stitch next record to last record if it exists */
                if (last_tl != NULL) last_tl->tl_data_next = next_tl;
                /* stitch the next one onto if this is the first */
                else if (tl == princ->kadm5_princ.tl_data)
                    princ->kadm5_princ.tl_data = next_tl;

                /* poof */
                free(tl->tl_data_contents);
                free(tl);

            }

            /* set this either way */
            tl = next_tl;
        }
    }

    /* add new db args to tl_data */
    if (items > 1) {
        for (i = 0; i < items - 1; i++) {
            krb5_tl_data *new_tl;

            new_tl = calloc(1, sizeof(*new_tl));
            new_tl->tl_data_type     = KRB5_TL_DB_ARGS;
            new_tl->tl_data_length   = strlen(db_args[i]) + 1;
            new_tl->tl_data_contents = db_args[i];
            new_tl->tl_data_next     = NULL;

            /* append to list */
            if (last_tl != NULL) last_tl->tl_data_next = new_tl;
            else princ->kadm5_princ.tl_data = new_tl;

            /* either way, it becomes the new tail */
            last_tl = new_tl;
        }
    }

    /* explictly get rid of db_args */
    Safefree(db_args);

#endif /* HAVE_KDB_H */

void
DESTROY(princ)
    Authen::Krb5::Admin::Principal princ
  PREINIT:
    SV            **p;
    krb5_key_data  *key;
  CODE:
    if (princ->key_data) {
        for (p = princ->key_data; princ->kadm5_princ.n_key_data--; p++)
            SvREFCNT_dec(*p);
        Safefree(princ->key_data);
    }
    if (princ->krb5_princ && SvIOK(princ->krb5_princ))
        SvREFCNT_dec(princ->krb5_princ);
    if (princ->krb5_princ_mod && SvROK(princ->krb5_princ_mod))
        SvREFCNT_dec(princ->krb5_princ_mod);
    if (princ->kadm5_princ.policy) {
        Safefree(princ->kadm5_princ.policy);
        princ->kadm5_princ.policy = NULL;
    }
    if (princ->kadm5_princ.tl_data) {
        krb5_tl_data *tl;
        while (princ->kadm5_princ.tl_data) {
            tl = princ->kadm5_princ.tl_data->tl_data_next;
            free(princ->kadm5_princ.tl_data->tl_data_contents);
            free(princ->kadm5_princ.tl_data);
            princ->kadm5_princ.tl_data = tl;
        }
    }
    Safefree(princ);
