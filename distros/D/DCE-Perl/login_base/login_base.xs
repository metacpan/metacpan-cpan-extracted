#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dce/sec_login.h>
#ifdef HPUX
#include <dce/sec_login_base.h>
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static long
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'a':
	break;
    case 'b':
	if (strEQ(name, "base_v0_0_included"))
#ifdef sec_login_base_v0_0_included
	    return sec_login_base_v0_0_included;
#else
	    goto not_there;
#endif
	break;
    case 'c':
	if (strEQ(name, "credentials_private"))
#ifdef sec_login_credentials_private
	    return sec_login_credentials_private;
#else
	    goto not_there;
#endif
	break;
    case 'd':
	if (strEQ(name, "default_handle"))
#ifdef sec_login_default_handle
	    return sec_login_default_handle;
#else
	    goto not_there;
#endif
	break;
    case 'e':
	if (strEQ(name, "external_tgt"))
#ifdef sec_login_external_tgt
	    return sec_login_external_tgt;
#else
	    goto not_there;
#endif
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	if (strEQ(name, "inherit_pag"))
#ifdef sec_login_inherit_pag
	    return sec_login_inherit_pag;
#else
	    goto not_there;
#endif
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	if (strEQ(name, "machine_princ"))
#ifdef sec_login_machine_princ
	    return sec_login_machine_princ;
#else
	    goto not_there;
#endif
	break;
    case 'n':
	if (strEQ(name, "no_flags"))
#ifdef sec_login_no_flags
	    return sec_login_no_flags;
#else
	    goto not_there;
#endif
	break;
    case 'o':
	break;
    case 'p':
	if (strEQ(name, "proxy_cred"))
#ifdef sec_login_proxy_cred
	    return sec_login_proxy_cred;
#else
	    goto not_there;
#endif
	break;
    case 'q':
	break;
    case 'r':
	if (strEQ(name, "remote_gid"))
#ifdef sec_login_remote_gid
	    return sec_login_remote_gid;
#else
	    goto not_there;
#endif
	if (strEQ(name, "remote_uid"))
#ifdef sec_login_remote_uid
	    return sec_login_remote_uid;
#else
	    goto not_there;
#endif
	break;
    case 's':
	break;
    case 't':
	if (strEQ(name, "tkt_allow_postdate"))
#ifdef sec_login_tkt_allow_postdate
	    return sec_login_tkt_allow_postdate;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_forwardable"))
#ifdef sec_login_tkt_forwardable
	    return sec_login_tkt_forwardable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_lifetime"))
#ifdef sec_login_tkt_lifetime
	    return sec_login_tkt_lifetime;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_postdated"))
#ifdef sec_login_tkt_postdated
	    return sec_login_tkt_postdated;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_proxiable"))
#ifdef sec_login_tkt_proxiable
	    return sec_login_tkt_proxiable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_renewable"))
#ifdef sec_login_tkt_renewable
	    return sec_login_tkt_renewable;
#else
	    goto not_there;
#endif
	if (strEQ(name, "tkt_renewable_ok"))
#ifdef sec_login_tkt_renewable_ok
	    return sec_login_tkt_renewable_ok;
#else
	    goto not_there;
#endif
	break;
    case 'u':
	break;
    case 'v':
	if (strEQ(name, "v0_0_included"))
#ifdef sec_login_v0_0_included
	    return sec_login_v0_0_included;
#else
	    goto not_there;
#endif
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


MODULE = DCE::login_base		PACKAGE = DCE::login_base		PREFIX = sec_login_


double
constant(name,arg)
	char *		name
	int		arg

