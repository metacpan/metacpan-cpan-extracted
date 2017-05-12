#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef TRUE
#undef FALSE
#undef WORD

#include "smbval/valid.h"
#include "smbval/smblib-priv.h"
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



void *
Valid_User_Connect(server,backup,domain,nonce)
    char *server
    char *backup
    char *domain
    char *nonce
CODE:
    if (!SvPOK (ST(3)) || SvCUR(ST(3)) < 8)
        croak ("nonce muist be preallocated with an 8 character string") ;

    RETVAL = Valid_User_Connect(server, backup, domain, nonce);
OUTPUT:
    RETVAL



int 
Valid_User_Auth(handle,username,password,precrypt=0,domain="")
    void *handle
    char *username
    char *password
    int   precrypt
	char *domain


void 
Valid_User_Disconnect(handle)
    void *handle


int 
SMBlib_errno()
CODE:
        RETVAL = SMBlib_errno ;
OUTPUT:
        RETVAL


int
SMBlib_SMB_Error()
CODE:
        RETVAL = SMBlib_SMB_Error ;
OUTPUT:
        RETVAL
