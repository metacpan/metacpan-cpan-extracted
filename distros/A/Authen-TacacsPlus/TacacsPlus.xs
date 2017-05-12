#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <string.h>
#include "tacpluslib/tacplus_client.h"
#include "tacpluslib/tac_plus.h"

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
	if (strEQ(name, "TAC_PLUS_AUTHEN_TYPE_ASCII"))
	    return TAC_PLUS_AUTHEN_TYPE_ASCII;
	else if (strEQ(name, "TAC_PLUS_AUTHEN_TYPE_PAP"))
	    return TAC_PLUS_AUTHEN_TYPE_PAP;
	else if (strEQ(name, "TAC_PLUS_AUTHEN_TYPE_CHAP"))
	    return TAC_PLUS_AUTHEN_TYPE_CHAP;
	else if (strEQ(name, "TAC_PLUS_AUTHEN_TYPE_ARAP"))
	    return TAC_PLUS_AUTHEN_TYPE_ARAP;
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

//not_there:
//   errno = ENOENT;
//    return 0;
}


MODULE = Authen::TacacsPlus		PACKAGE = Authen::TacacsPlus		


double
constant(name,arg)
	char *		name
	int		arg


int
init_tac_session (host_name,port_name,key,timeout)
	char* host_name
	char* port_name
	char* key
	int timeout
	OUTPUT:
	RETVAL

int
make_auth (username, password, authen_type)
	char* username
	char* password
	int authen_type
	CODE:
	STRLEN user_len;
	STRLEN password_len;
        username = (char *)SvPV(ST(0),user_len);
        password = (char *)SvPV(ST(1),password_len);
	RETVAL = make_auth(username, user_len, 
			   password, password_len, 
			   authen_type);
	OUTPUT:
	RETVAL

void
deinit_tac_session()


char *                                                               
errmsg()                                                     
    CODE:  
     RETVAL = tac_err;     
    OUTPUT:
     RETVAL

