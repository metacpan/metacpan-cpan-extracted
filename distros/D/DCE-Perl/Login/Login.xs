#include "../DCE_Perl.h"

#include <dce/sec_login.h>

#ifdef I_PWD
#include <pwd.h>
#endif

/* $Id: Login.xs,v 1.11 1996/11/01 19:24:57 dougm Exp $ */ 

#define BLESS_LOGIN_CONTEXT \
   sv = sv_newmortal(); \
   sv_setref_pv(sv,package,(void*)login_context); \
   XPUSHs(sv); \
   DCESTATUS

MODULE = DCE::Login		PACKAGE = DCE::Login		PREFIX = sec_login_

# this will get a sealed certificate for the principal from the secserver,
# and return a list of ($login_context, $status)

void
sec_login_setup_identity(package = "DCE::Login", principal, flags=sec_login_no_flags)
  char *package
  unsigned_char_p_t	principal
  sec_login_flags_t	flags

  PPCODE:
  {
    sec_login_handle_t	login_context;
    error_status_t	status;
    SV *sv;

    sec_login_setup_identity(principal, flags, &login_context, &status);
    BLESS_LOGIN_CONTEXT;
  }

void
sec_login_get_current_context(package = "DCE::Login")
  char *package

  PPCODE:
  {
    sec_login_handle_t login_context;
    error_status_t	status;
    SV *sv;

    sec_login_get_current_context(&login_context, &status);
    BLESS_LOGIN_CONTEXT;
  }

void
sec_login_validate_identity(login_context, password)
  DCE::Login	login_context
  char *	password  

  PPCODE:
  {
    boolean32	reset_passwd, retval;
    sec_login_auth_src_t	auth_src;
    error_status_t	status;
    sec_passwd_rec_t	passwd;
    
    /* load passwd struct */
    passwd.key.key_type = sec_passwd_plain;
    passwd.key.tagged_union.plain = password;
    passwd.pepper = NULL;
    passwd.version_number = sec_passwd_c_version_none;
                        
    retval = sec_login_validate_identity(login_context, &passwd, 
					 &reset_passwd, &auth_src, &status);
    if(GIMME == G_ARRAY) {
	EXTEND(sp,3);
	PUSHs_iv(retval);
	PUSHs_iv(reset_passwd);
	PUSHs_iv(auth_src);
    }
    DCESTATUS;
  }    

void
sec_login_certify_identity(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    boolean32 retval;
    retval = sec_login_certify_identity(login_context, &status);
    if(GIMME == G_ARRAY)
	XPUSHs_iv(retval);
    DCESTATUS;
  }

void
sec_login_valid_and_cert_ident(login_context, password)
  DCE::Login	login_context
  char *password  

  PPCODE:
  {
    boolean32	reset_passwd, retval;
    sec_login_auth_src_t	auth_src;
    error_status_t	status;
    sec_passwd_rec_t	passwd;
    sec_passwd_str_t    pbuf;

    strncpy((char *)pbuf, password, sec_passwd_str_max_len);
    pbuf[sec_passwd_str_max_len] = '\0';

    /* load passwd struct */
    passwd.key.key_type = sec_passwd_plain;
    passwd.key.tagged_union.plain = (unsigned char *)pbuf;
    passwd.pepper = NULL;
    passwd.version_number = sec_passwd_c_version_none;
            
    retval = sec_login_valid_and_cert_ident(login_context, &passwd, &reset_passwd, &auth_src, &status);
    if(GIMME == G_ARRAY) {
	EXTEND(sp,3);
	PUSHs_iv(retval);
	PUSHs_iv(reset_passwd);
	PUSHs_iv(auth_src);
    }
    DCESTATUS;
  }    

void
sec_login_valid_from_keytable(login_context, keyfile = "")
  DCE::Login	login_context
  char *keyfile

    CODE:
    {
    unsigned32          kvno, asvc = rpc_c_authn_dce_secret;
    boolean32	reset_passwd;
    sec_login_auth_src_t	auth_src;
    error_status_t	status;

    sec_login_valid_from_keytable(login_context, asvc, keyfile, 0, &kvno,
				  &reset_passwd, &auth_src, &status);
    EXTEND(sp,2);
    PUSHs_iv(reset_passwd);
    PUSHs_iv(auth_src);
    DCESTATUS;
  }

void
sec_login_set_context(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    sec_login_set_context(login_context, &status);
    DCESTATUS;
  }

void
sec_login_purge_context(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    sec_login_purge_context(&login_context, &status);
    sv_setref_pv(ST(0), "DCE::Login", (void*)login_context);
    DCESTATUS;
  }

void
sec_login_release_context(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    sec_login_release_context(&login_context, &status);
    sv_setref_pv(ST(0), "DCE::Login", (void*)login_context);
    DCESTATUS;
  }

void
sec_login_DESTROY(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    sec_login_release_context(&login_context, &status);
  }

void
sec_login_get_expiration(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    signed32	identity_expiration;
    error_status_t	status;
    sec_login_get_expiration(login_context, &identity_expiration, &status);
    XPUSHs_iv(identity_expiration);
    DCESTATUS;
  }

void
sec_login_refresh_identity(login_context)
  DCE::Login	login_context

  PPCODE:
  {
    error_status_t	status;
    sec_login_refresh_identity(login_context, &status);
    DCESTATUS;
  }

void
sec_login_import_context(package = "DCE::Login", buf_len, buf)
  char *package;
  unsigned32	buf_len
  char *	buf

  PPCODE:
  {
  sec_login_handle_t	login_context;
  error_status_t	status;
  SV *sv;

  sec_login_import_context(buf_len, buf, &login_context, &status);

  BLESS_LOGIN_CONTEXT;
  }

void
sec_login_export_context(login_context, buf_len)
  DCE::Login	login_context
  unsigned32	buf_len

  PPCODE:
  {
    char *	buf;
    unsigned32	len_used;
    unsigned32	len_needed;
    error_status_t	status;
  
    buf = malloc(buf_len);
    sec_login_export_context(login_context, buf_len, buf, &len_used, &len_needed, &status);

    EXTEND(sp, 3);
    PUSHs_pv(buf); 
    PUSHs_iv(len_used);
    PUSHs_iv(len_needed);
    DCESTATUS;
    free(buf);
  }

void
sec_login_get_pwent(login_context)
  DCE::Login 	login_context

  PPCODE:
  {
    struct passwd *pwd;
    error_status_t 	status;
    HV *hv;

    sec_login_get_pwent(login_context, (sec_login_passwd_t *)&pwd, &status);

    iniHV;
    hv_store(hv, "name", 4, newSVpv(pwd->pw_name,0),0);
    hv_store(hv, "passwd", 6, newSVpv(pwd->pw_passwd,0),0);
    hv_store(hv, "gecos", 5, newSVpv(pwd->pw_gecos,0),0);    
    hv_store(hv, "dir", 3, newSVpv(pwd->pw_dir,0),0);
    hv_store(hv, "shell", 5, newSVpv(pwd->pw_shell,0),0);
    hv_store(hv, "uid", 3, newSViv(pwd->pw_uid),0);
    hv_store(hv, "gid", 3, newSViv(pwd->pw_gid),0);
    /*
#ifdef something...
    hv_store(hv, "class", 5, newSVpv(pwd->pw_class,0),0);
    hv_store(hv, "change", 6, newSViv(pwd->pw_change),0);
    hv_store(hv, "expire", 6, newSViv(pwd->pw_expire),0);
#endif
    */

    XPUSHs(newRV((SV*)hv)); 
    DCESTATUS;
  }


