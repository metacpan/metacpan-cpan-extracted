#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dce/rgynbase.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'a':
	if (strEQ(name, "acct_admin_audit"))
#ifdef sec_rgy_acct_admin_audit
	    return sec_rgy_acct_admin_audit;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_admin_client"))
#ifdef sec_rgy_acct_admin_client
	    return sec_rgy_acct_admin_client;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_admin_flags_none"))
#ifdef sec_rgy_acct_admin_flags_none
	    return sec_rgy_acct_admin_flags_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_admin_server"))
#ifdef sec_rgy_acct_admin_server
	    return sec_rgy_acct_admin_server;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_admin_valid"))
#ifdef sec_rgy_acct_admin_valid
	    return sec_rgy_acct_admin_valid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_dup_skey"))
#ifdef sec_rgy_acct_auth_dup_skey
	    return sec_rgy_acct_auth_dup_skey;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_flags_none"))
#ifdef sec_rgy_acct_auth_flags_none
	    return sec_rgy_acct_auth_flags_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_forwardable"))
#ifdef sec_rgy_acct_auth_forwardable
	    return sec_rgy_acct_auth_forwardable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_post_dated"))
#ifdef sec_rgy_acct_auth_post_dated
	    return sec_rgy_acct_auth_post_dated;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_proxiable"))
#ifdef sec_rgy_acct_auth_proxiable
	    return sec_rgy_acct_auth_proxiable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_renewable"))
#ifdef sec_rgy_acct_auth_renewable
	    return sec_rgy_acct_auth_renewable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_auth_tgt"))
#ifdef sec_rgy_acct_auth_tgt
	    return sec_rgy_acct_auth_tgt;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_key_group"))
#ifdef sec_rgy_acct_key_group
	    return sec_rgy_acct_key_group;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_key_last"))
#ifdef sec_rgy_acct_key_last
	    return sec_rgy_acct_key_last;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_key_none"))
#ifdef sec_rgy_acct_key_none
	    return sec_rgy_acct_key_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_key_org"))
#ifdef sec_rgy_acct_key_org
	    return sec_rgy_acct_key_org;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_key_person"))
#ifdef sec_rgy_acct_key_person
	    return sec_rgy_acct_key_person;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_user_flags_none"))
#ifdef sec_rgy_acct_user_flags_none
	    return sec_rgy_acct_user_flags_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "acct_user_passwd_valid"))
#ifdef sec_rgy_acct_user_passwd_valid
	    return sec_rgy_acct_user_passwd_valid;
#else
	    goto not_there;
#endif
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	if (strEQ(name, "domain_group"))
#ifdef sec_rgy_domain_group
	    return sec_rgy_domain_group;
#else
	    goto not_there;
#endif
	if (strEQ(name, "domain_last"))
#ifdef sec_rgy_domain_last
	    return sec_rgy_domain_last;
#else
	    goto not_there;
#endif
	if (strEQ(name, "domain_org"))
#ifdef sec_rgy_domain_org
	    return sec_rgy_domain_org;
#else
	    goto not_there;
#endif
	if (strEQ(name, "domain_person"))
#ifdef sec_rgy_domain_person
	    return sec_rgy_domain_person;
#else
	    goto not_there;
#endif
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	if (strEQ(name, "max_unix_passwd_len"))
#ifdef sec_rgy_max_unix_passwd_len
	    return sec_rgy_max_unix_passwd_len;
#else
	    goto not_there;
#endif
	break;
    case 'n':
	if (strEQ(name, "name_max_len"))
#ifdef sec_rgy_name_max_len
	    return sec_rgy_name_max_len;
#else
	    goto not_there;
#endif
	if (strEQ(name, "name_t_size"))
#ifdef sec_rgy_name_t_size
	    return sec_rgy_name_t_size;
#else
	    goto not_there;
#endif
	if (strEQ(name, "no_override"))
#ifdef sec_rgy_no_override
	    return sec_rgy_no_override;
#else
	    goto not_there;
#endif
	if (strEQ(name, "no_resolve_pname"))
#ifdef sec_rgy_no_resolve_pname
	    return sec_rgy_no_resolve_pname;
#else
	    goto not_there;
#endif
	break;
    case 'o':
	if (strEQ(name, "override"))
#ifdef sec_rgy_override
	    return sec_rgy_override;
#else
	    goto not_there;
#endif
	break;
    case 'p':
	if (strEQ(name, "pgo_flags_none"))
#ifdef sec_rgy_pgo_flags_none
	    return sec_rgy_pgo_flags_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "pgo_is_an_alias"))
#ifdef sec_rgy_pgo_is_an_alias
	    return sec_rgy_pgo_is_an_alias;
#else
	    goto not_there;
#endif
	if (strEQ(name, "pgo_is_required"))
#ifdef sec_rgy_pgo_is_required
	    return sec_rgy_pgo_is_required;
#else
	    goto not_there;
#endif
	if (strEQ(name, "pgo_projlist_ok"))
#ifdef sec_rgy_pgo_projlist_ok
	    return sec_rgy_pgo_projlist_ok;
#else
	    goto not_there;
#endif
	if (strEQ(name, "plcy_pwd_flags_none"))
#ifdef sec_rgy_plcy_pwd_flags_none
	    return sec_rgy_plcy_pwd_flags_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "plcy_pwd_no_spaces"))
#ifdef sec_rgy_plcy_pwd_no_spaces
	    return sec_rgy_plcy_pwd_no_spaces;
#else
	    goto not_there;
#endif
	if (strEQ(name, "plcy_pwd_non_alpha"))
#ifdef sec_rgy_plcy_pwd_non_alpha
	    return sec_rgy_plcy_pwd_non_alpha;
#else
	    goto not_there;
#endif
	if (strEQ(name, "pname_max_len"))
#ifdef sec_rgy_pname_max_len
	    return sec_rgy_pname_max_len;
#else
	    goto not_there;
#endif
	if (strEQ(name, "pname_t_size"))
#ifdef sec_rgy_pname_t_size
	    return sec_rgy_pname_t_size;
#else
	    goto not_there;
#endif
	if (strEQ(name, "prop_auth_cert_unbound"))
#ifdef sec_rgy_prop_auth_cert_unbound
	    return sec_rgy_prop_auth_cert_unbound;
#else
	    goto not_there;
#endif
	if (strEQ(name, "prop_embedded_unix_id"))
#ifdef sec_rgy_prop_embedded_unix_id
	    return sec_rgy_prop_embedded_unix_id;
#else
	    goto not_there;
#endif
	if (strEQ(name, "prop_readonly"))
#ifdef sec_rgy_prop_readonly
	    return sec_rgy_prop_readonly;
#else
	    goto not_there;
#endif
	if (strEQ(name, "prop_shadow_passwd"))
#ifdef sec_rgy_prop_shadow_passwd
	    return sec_rgy_prop_shadow_passwd;
#else
	    goto not_there;
#endif
	if (strEQ(name, "properties_none"))
#ifdef sec_rgy_properties_none
	    return sec_rgy_properties_none;
#else
	    goto not_there;
#endif
	break;
    case 'q':
	if (strEQ(name, "quota_unlimited"))
#ifdef sec_rgy_quota_unlimited
	    return sec_rgy_quota_unlimited;
#else
	    goto not_there;
#endif
	break;
    case 'r':
	if (strEQ(name, "resolve_pname"))
#ifdef sec_rgy_resolve_pname
	    return sec_rgy_resolve_pname;
#else
	    goto not_there;
#endif
	if (strEQ(name, "rgynbase_v0_0_included"))
#ifdef rgynbase_v0_0_included
	    return rgynbase_v0_0_included;
#else
	    goto not_there;
#endif
	break;
    case 's':
	if (strEQ(name, "status_ok"))
#ifdef sec_rgy_status_ok
	    return sec_rgy_status_ok;
#else
	    goto not_there;
#endif
	break;
    case 't':
	break;
    case 'u':
	if (strEQ(name, "uxid_unknown"))
#ifdef sec_rgy_uxid_unknown
	    return sec_rgy_uxid_unknown;
#else
	    goto not_there;
#endif
	break;
    case 'v':
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::rgybase		PACKAGE = DCE::rgybase		PREFIX = sec_rgy_


double
constant(name,arg)
	char *		name
	int		arg

char *
sec_rgy_wildcard_name()

    CODE:
#ifdef sec_rgy_wildcard_name
    RETVAL = sec_rgy_wildcard_name;
#else
    croak("Your vendor has not defined the DCE::rgybase macro sec_rgy_wildcard_name");
#endif

    OUTPUT:
    RETVAL

char *
sec_rgy_wildcard_sid()

    CODE:
#ifdef sec_rgy_wildcard_sid
    RETVAL = sec_rgy_wildcard_sid;
#else
    croak("Your vendor has not defined the DCE::rgybase macro sec_rgy_wildcard_sid");
#endif

    OUTPUT:
    RETVAL

