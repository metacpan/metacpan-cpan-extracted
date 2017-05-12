/*
 * Copyright 2001 by the Massachusetts Institute of Technology.
 * All Rights Reserved.
 *
 * Export of this software from the United States of America may
 *   require a specific license from the United States Government.
 *   It is the responsibility of any person or organization contemplating
 *   export to obtain such a license before exporting.
 * 
 * WITHIN THAT CONSTRAINT, permission to use, copy, modify, and
 * distribute this software and its documentation for any purpose and
 * without fee is hereby granted, provided that the above copyright
 * notice appear in all copies and that both that copyright notice and
 * this permission notice appear in supporting documentation, and that
 * the name of M.I.T. not be used in advertising or publicity pertaining
 * to distribution of the software without specific, written prior
 * permission.  Furthermore if you modify this software you must label
 * your software as modified software and not distribute it in such a
 * fashion that it might be confused with the original M.I.T. software.
 * M.I.T. makes no representations about the suitability of
 * this software for any purpose.  It is provided "as is" without express
 * or implied warranty.
 *
 * $Id: admin.h,v 1.7 2006/12/28 18:23:25 ajk Exp $
 *
 * Header file for Perl interface to libkadm5clnt
 *
 * The file admin.h from the MIT Kerberos 5 distribution does not get
 * installed by default and it depends on other header files that
 * don't get installed.  This file contains only what we need from
 * admin.h, kadm_err.h, and k5-int.h.
 */

#if !defined(USE_KADM5_API_VERSION)
#define USE_KADM5_API_VERSION 2
#endif

/* only what we need from k5-int.h */

/*
 * Note --- these structures cannot be modified without changing the
 * database version number in libkdb.a, but should be expandable by
 * adding new tl_data types.
 */
typedef struct _krb5_tl_data {
    struct _krb5_tl_data* tl_data_next;		/* NOT saved */
    krb5_int16 		  tl_data_type;		
    krb5_int16		  tl_data_length;	
    krb5_octet 	        * tl_data_contents;	
} krb5_tl_data;

/* 
 * If this ever changes up the version number and make the arrays be as
 * big as necessary.
 *
 * Currently the first type is the enctype and the second is the salt type.
 */
typedef struct _krb5_key_data {
    krb5_int16 		  key_data_ver;		/* Version */
    krb5_int16		  key_data_kvno;	/* Key Version */
    krb5_int16		  key_data_type[2];	/* Array of types */
    krb5_int16		  key_data_length[2];	/* Array of lengths */
    krb5_octet 	        * key_data_contents[2];	/* Array of pointers */
} krb5_key_data;

/* only what we need from admin.h */

#define KADM5_ADMIN_SERVICE	"kadmin/admin"
#define KADM5_CHANGEPW_SERVICE	"kadmin/changepw"
#define KADM5_HIST_PRINCIPAL	"kadmin/history"

typedef	char	*kadm5_policy_t;
typedef long	 kadm5_ret_t;

/*
 * Succsessful return code
 */
#define KADM5_OK	0

/*
 * Field masks
 */

/* kadm5_principal_ent_t */
#define KADM5_PRINCIPAL		0x000001
#define KADM5_PRINC_EXPIRE_TIME	0x000002
#define KADM5_PW_EXPIRATION	0x000004
#define KADM5_LAST_PWD_CHANGE	0x000008
#define KADM5_ATTRIBUTES	0x000010
#define KADM5_MAX_LIFE		0x000020
#define KADM5_MOD_TIME		0x000040
#define KADM5_MOD_NAME		0x000080
#define KADM5_KVNO		0x000100
#define KADM5_MKVNO		0x000200
#define KADM5_AUX_ATTRIBUTES	0x000400
#define KADM5_POLICY		0x000800
#define KADM5_POLICY_CLR	0x001000
/* version 2 masks */
#define KADM5_MAX_RLIFE		0x002000
#define KADM5_LAST_SUCCESS	0x004000
#define KADM5_LAST_FAILED	0x008000
#define KADM5_FAIL_AUTH_COUNT	0x010000
#define KADM5_KEY_DATA		0x020000
#define KADM5_TL_DATA		0x040000
/* all but KEY_DATA and TL_DATA */
#define KADM5_PRINCIPAL_NORMAL_MASK 0x01ffff

/* kadm5_policy_ent_t */
#define KADM5_PW_MAX_LIFE	0x004000
#define KADM5_PW_MIN_LIFE	0x008000
#define KADM5_PW_MIN_LENGTH	0x010000
#define KADM5_PW_MIN_CLASSES	0x020000
#define KADM5_PW_HISTORY_NUM	0x040000
#define KADM5_REF_COUNT		0x080000

/* kadm5_config_params */
#define KADM5_CONFIG_REALM		0x000001
#define KADM5_CONFIG_DBNAME		0x000002
#define KADM5_CONFIG_MKEY_NAME		0x000004
#define KADM5_CONFIG_MAX_LIFE		0x000008
#define KADM5_CONFIG_MAX_RLIFE		0x000010
#define KADM5_CONFIG_EXPIRATION		0x000020
#define KADM5_CONFIG_FLAGS		0x000040
#define KADM5_CONFIG_ADMIN_KEYTAB	0x000080
#define KADM5_CONFIG_STASH_FILE		0x000100
#define KADM5_CONFIG_ENCTYPE		0x000200
#define KADM5_CONFIG_ADBNAME		0x000400
#define KADM5_CONFIG_ADB_LOCKFILE	0x000800
#ifndef KRB5_PLUGIN_NO_HANDLE    /* hack to test for 1.5 */
#define KADM5_CONFIG_PROFILE		0x001000
#endif
#define KADM5_CONFIG_ACL_FILE		0x002000
#define KADM5_CONFIG_KADMIND_PORT	0x004000
#define KADM5_CONFIG_ENCTYPES		0x008000
#define KADM5_CONFIG_ADMIN_SERVER	0x010000
#define KADM5_CONFIG_DICT_FILE		0x020000
#define KADM5_CONFIG_MKEY_FROM_KBD	0x040000
#define KADM5_CONFIG_KPASSWD_PORT	0x080000
#define KADM5_CONFIG_OLD_AUTH_GSSAPI	0x100000
#define KADM5_CONFIG_NO_AUTH		0x200000
#define KADM5_CONFIG_AUTH_NOFALLBACK	0x400000
/*
 * permission bits
 */
#define KADM5_PRIV_GET		0x01
#define KADM5_PRIV_ADD		0x02
#define KADM5_PRIV_MODIFY	0x04
#define KADM5_PRIV_DELETE	0x08

/*
 * API versioning constants
 */
#define KADM5_MASK_BITS		0xffffff00

#define KADM5_STRUCT_VERSION_MASK	0x12345600
#define KADM5_STRUCT_VERSION_1	(KADM5_STRUCT_VERSION_MASK|0x01)
#define KADM5_STRUCT_VERSION	KADM5_STRUCT_VERSION_1

#define KADM5_API_VERSION_MASK	0x12345700
#define KADM5_API_VERSION_1	(KADM5_API_VERSION_MASK|0x01)
#define KADM5_API_VERSION_2	(KADM5_API_VERSION_MASK|0x02)

typedef struct _kadm5_principal_ent_t_v2 {
	krb5_principal	principal;
	krb5_timestamp	princ_expire_time;
	krb5_timestamp	last_pwd_change;
	krb5_timestamp	pw_expiration;
	krb5_deltat	max_life;
	krb5_principal	mod_name;
	krb5_timestamp	mod_date;
	krb5_flags	attributes;
	krb5_kvno	kvno;
	krb5_kvno	mkvno;
	char		*policy;
	long		aux_attributes;

	/* version 2 fields */
	krb5_deltat max_renewable_life;
        krb5_timestamp last_success;
        krb5_timestamp last_failed;
        krb5_kvno fail_auth_count;
	krb5_int16 n_key_data;
	krb5_int16 n_tl_data;
        krb5_tl_data *tl_data;
	krb5_key_data *key_data;
} kadm5_principal_ent_rec_v2, *kadm5_principal_ent_t_v2;

typedef struct _kadm5_principal_ent_t_v1 {
	krb5_principal	principal;
	krb5_timestamp	princ_expire_time;
	krb5_timestamp	last_pwd_change;
	krb5_timestamp	pw_expiration;
	krb5_deltat	max_life;
	krb5_principal	mod_name;
	krb5_timestamp	mod_date;
	krb5_flags	attributes;
	krb5_kvno	kvno;
	krb5_kvno	mkvno;
	char		*policy;
	long		aux_attributes;
} kadm5_principal_ent_rec_v1, *kadm5_principal_ent_t_v1;

#if USE_KADM5_API_VERSION == 1
typedef struct _kadm5_principal_ent_t_v1
     kadm5_principal_ent_rec, *kadm5_principal_ent_t;
#else
typedef struct _kadm5_principal_ent_t_v2
     kadm5_principal_ent_rec, *kadm5_principal_ent_t;
#endif

typedef struct _kadm5_policy_ent_t {
	char		*policy;
	long		pw_min_life;
	long		pw_max_life;
	long		pw_min_length;
	long		pw_min_classes;
	long		pw_history_num;
	long		policy_refcnt;
} kadm5_policy_ent_rec, *kadm5_policy_ent_t;

typedef struct __krb5_key_salt_tuple {
	krb5_enctype	ks_enctype;
	krb5_int32	ks_salttype;
} krb5_key_salt_tuple;

/*
 * Data structure returned by kadm5_get_config_params()
 */
typedef struct _kadm5_config_params {
	long			 mask;
	char			*realm;
#ifndef KRB5_PLUGIN_NO_HANDLE    /* hack to test for 1.5 */
	char			*profile;
#endif
	int			 kadmind_port;
	int			 kpasswd_port;
	
	char			*admin_server;
	
	char			*dbname;
	char			*admin_dbname;
	char			*admin_lockfile;
	char			*admin_keytab;
	char			*acl_file;
	char			*dict_file;
	
	int			 mkey_from_kbd;
	char			*stash_file;
	char			*mkey_name;
	krb5_enctype		 enctype;
	krb5_deltat		 max_life;
	krb5_deltat		 max_rlife;
	krb5_timestamp		 expiration;
	krb5_flags		 flags;
	krb5_key_salt_tuple	*keysalts;
	krb5_int32		 num_keysalts;
} kadm5_config_params;

/* Salt types */
#define KRB5_KDB_SALTTYPE_NORMAL	0
#define KRB5_KDB_SALTTYPE_V4		1
#define KRB5_KDB_SALTTYPE_NOREALM	2
#define KRB5_KDB_SALTTYPE_ONLYREALM	3
#define KRB5_KDB_SALTTYPE_SPECIAL	4
#define KRB5_KDB_SALTTYPE_AFS3		5

/* Database attributes */
#define	KRB5_KDB_DISALLOW_POSTDATED	0x00000001
#define	KRB5_KDB_DISALLOW_FORWARDABLE	0x00000002
#define	KRB5_KDB_DISALLOW_TGT_BASED	0x00000004
#define	KRB5_KDB_DISALLOW_RENEWABLE	0x00000008
#define	KRB5_KDB_DISALLOW_PROXIABLE	0x00000010
#define	KRB5_KDB_DISALLOW_DUP_SKEY	0x00000020
#define	KRB5_KDB_DISALLOW_ALL_TIX	0x00000040
#define	KRB5_KDB_REQUIRES_PRE_AUTH	0x00000080
#define KRB5_KDB_REQUIRES_HW_AUTH	0x00000100
#define	KRB5_KDB_REQUIRES_PWCHANGE	0x00000200
#define KRB5_KDB_DISALLOW_SVR		0x00001000
#define KRB5_KDB_PWCHANGE_SERVICE	0x00002000
#define KRB5_KDB_SUPPORT_DESMD5         0x00004000
#define	KRB5_KDB_NEW_PRINC		0x00008000

/* Error table values */
#define KADM5_FAILURE                            (43787520L)
#define KADM5_AUTH_GET                           (43787521L)
#define KADM5_AUTH_ADD                           (43787522L)
#define KADM5_AUTH_MODIFY                        (43787523L)
#define KADM5_AUTH_DELETE                        (43787524L)
#define KADM5_AUTH_INSUFFICIENT                  (43787525L)
#define KADM5_BAD_DB                             (43787526L)
#define KADM5_DUP                                (43787527L)
#define KADM5_RPC_ERROR                          (43787528L)
#define KADM5_NO_SRV                             (43787529L)
#define KADM5_BAD_HIST_KEY                       (43787530L)
#define KADM5_NOT_INIT                           (43787531L)
#define KADM5_UNK_PRINC                          (43787532L)
#define KADM5_UNK_POLICY                         (43787533L)
#define KADM5_BAD_MASK                           (43787534L)
#define KADM5_BAD_CLASS                          (43787535L)
#define KADM5_BAD_LENGTH                         (43787536L)
#define KADM5_BAD_POLICY                         (43787537L)
#define KADM5_BAD_PRINCIPAL                      (43787538L)
#define KADM5_BAD_AUX_ATTR                       (43787539L)
#define KADM5_BAD_HISTORY                        (43787540L)
#define KADM5_BAD_MIN_PASS_LIFE                  (43787541L)
#define KADM5_PASS_Q_TOOSHORT                    (43787542L)
#define KADM5_PASS_Q_CLASS                       (43787543L)
#define KADM5_PASS_Q_DICT                        (43787544L)
#define KADM5_PASS_REUSE                         (43787545L)
#define KADM5_PASS_TOOSOON                       (43787546L)
#define KADM5_POLICY_REF                         (43787547L)
#define KADM5_INIT                               (43787548L)
#define KADM5_BAD_PASSWORD                       (43787549L)
#define KADM5_PROTECT_PRINCIPAL                  (43787550L)
#define KADM5_BAD_SERVER_HANDLE                  (43787551L)
#define KADM5_BAD_STRUCT_VERSION                 (43787552L)
#define KADM5_OLD_STRUCT_VERSION                 (43787553L)
#define KADM5_NEW_STRUCT_VERSION                 (43787554L)
#define KADM5_BAD_API_VERSION                    (43787555L)
#define KADM5_OLD_LIB_API_VERSION                (43787556L)
#define KADM5_OLD_SERVER_API_VERSION             (43787557L)
#define KADM5_NEW_LIB_API_VERSION                (43787558L)
#define KADM5_NEW_SERVER_API_VERSION             (43787559L)
#define KADM5_SECURE_PRINC_MISSING               (43787560L)
#define KADM5_NO_RENAME_SALT                     (43787561L)
#define KADM5_BAD_CLIENT_PARAMS                  (43787562L)
#define KADM5_BAD_SERVER_PARAMS                  (43787563L)
#define KADM5_AUTH_LIST                          (43787564L)
#define KADM5_AUTH_CHANGEPW                      (43787565L)
#define KADM5_GSS_ERROR                          (43787566L)
#define KADM5_BAD_TL_TYPE                        (43787567L)
#define KADM5_MISSING_CONF_PARAMS                (43787568L)
#define KADM5_BAD_SERVER_NAME                    (43787569L)
#define KADM5_AUTH_SETKEY                        (43787570L)
#define KADM5_SETKEY_DUP_ENCTYPES                (43787571L)
#define KADM5_SETV4KEY_INVAL_ENCTYPE             (43787572L)
#define KADM5_SETKEY3_ETYPE_MISMATCH             (43787573L)
#define KADM5_MISSING_KRB5_CONF_PARAMS           (43787574L)
#define KADM5_XDR_FAILURE                        (43787575L)
