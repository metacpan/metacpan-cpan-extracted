#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "opie.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = ENOENT;
    return 0;
}


MODULE = Authen::OPIE		PACKAGE = Authen::OPIE		


double
constant(name,arg)
	char *		name
	int		arg

SV*
opie_challenge(name)
	char *		name

	PREINIT:
		struct opie my_opie;
 		char        challenge[OPIE_CHALLENGE_MAX+1];
		int         result;
		SV*	    SV_challenge;
		
	CODE:
		result = opiechallenge(&my_opie, name, challenge);
		if (result != 1) {
			SV_challenge = newSVpv(challenge, strlen(challenge));
			RETVAL = SV_challenge;
		} else {
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL


int
opie_verify(name,response)
	char *		name
	char *		response

	PREINIT:
		struct opie my_opie;
 		char        challenge[OPIE_CHALLENGE_MAX+1];
		int	    result;
		
	CODE:
		result = opiechallenge(&my_opie, name, challenge);
		if (result != 1) {
			RETVAL = opieverify(&my_opie, response);
		} else {
			XSRETURN_UNDEF;
		}
	OUTPUT:
	RETVAL

