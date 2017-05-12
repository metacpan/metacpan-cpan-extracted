#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Config.h"

#include <ctype.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Ctype		PACKAGE = Ctype		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

PROTOTYPES: enable

int
_isALNUM(c)	
     char c;
     CODE:
	RETVAL = ((int) isALNUM(c));
     OUTPUT:
	RETVAL

int
_isalnum(c)
     char c;
     CODE:
	RETVAL = ((int) isalnum(c));
     OUTPUT:
	RETVAL


int
_isALPHA(c)
     char c;
     CODE:
        RETVAL = ((int) isALPHA(c));
     OUTPUT:
	RETVAL

int
_isalpha(c)
     char c;
     CODE:
        RETVAL = ((int) isalpha(c));
     OUTPUT:
        RETVAL

int
_isDIGIT(c)
     char c;
     CODE:
        RETVAL = ((int) isDIGIT(c));
     OUTPUT:
        RETVAL

int
_isdigit(c)
     char c;
     CODE:
        RETVAL = ((int) isdigit(c));
     OUTPUT:
        RETVAL

int
_isLOWER(c)
     char c;
     CODE:
        RETVAL = ((int) isLOWER(c));
     OUTPUT:
        RETVAL

int
_islower(c)
     char c;
     CODE:
        RETVAL = ((int) islower(c));
     OUTPUT:
        RETVAL

int
_isSPACE(c)
     char c;
     CODE:
        RETVAL = ((int) isSPACE(c));
     OUTPUT:
        RETVAL

int
_isspace(c)
     char c;
     CODE:
        RETVAL = ((int) isspace(c));
     OUTPUT:
     	RETVAL

int
_isUPPER(c)
     char c;
     CODE:
     	RETVAL = ((int) isUPPER(c));
     OUTPUT:
     	RETVAL

int
_isupper(c)
     char c;
     CODE:
     	RETVAL = ((int) isupper(c));
     OUTPUT:
     	RETVAL

int
_isXDIGIT(c)
     char c;
     CODE:
     	RETVAL = ((int) isXDIGIT(c));
     OUTPUT:
     	RETVAL

int
_isxdigit(c)
     char c;
     CODE:
     	RETVAL = ((int) isxdigit(c));
     OUTPUT:
     	RETVAL

char
_toLOWER(c)
     char c;
     CODE:
     	RETVAL = ((char) toLOWER((char) c));
     OUTPUT:
     	RETVAL

char
_tolower(c)
     char c;
     CODE:
     	RETVAL = ((char) tolower((char) c));
     OUTPUT:
     	RETVAL

char
_toUPPER(c)
     char c;
     CODE:
     	RETVAL = ((char) toUPPER((char) c));
     OUTPUT:
     	RETVAL

char
_toupper(c)
     char c;
     CODE:
     	RETVAL = ((char) toupper((char) c));
     OUTPUT:
     	RETVAL

