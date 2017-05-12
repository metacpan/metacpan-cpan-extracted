#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

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
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	if (strEQ(name, "NTV_LOGON_ERROR"))
#ifdef NTV_LOGON_ERROR
	    return NTV_LOGON_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NTV_NO_ERROR"))
#ifdef NTV_NO_ERROR
	    return NTV_NO_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NTV_PROTOCOL_ERROR"))
#ifdef NTV_PROTOCOL_ERROR
	    return NTV_PROTOCOL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NTV_SERVER_ERROR"))
#ifdef NTV_SERVER_ERROR
	    return NTV_SERVER_ERROR;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Authen::Smb	PACKAGE = Authen::Smb		


double
constant(name,arg)
	char *		name
	int		arg

int
Valid_User(username, password, server, backup, domain)
	char *		username
	char *		password
	char *		server
	char *		backup
	char *		domain
	OUTPUT:
	RETVAL
