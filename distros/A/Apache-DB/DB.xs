#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#define SIGINT 2
#endif

static void my_init_debugger()
{
    dTHR;
    Perl_init_debugger(aTHX);
}

static Sighandler_t ApacheSIGINT = NULL;

MODULE = Apache::DB		PACKAGE = Apache::DB		

PROTOTYPES: DISABLE

BOOT:
    ApacheSIGINT = rsignal_state(whichsig("INT"));

int
init_debugger()

    CODE:
    if (!PL_perldb) {
	PL_perldb = PERLDB_ALL;
	my_init_debugger();
	RETVAL = TRUE;
    }
    else 
	RETVAL = FALSE;

    OUTPUT:
    RETVAL

MODULE = Apache::DB            PACKAGE = DB

void
ApacheSIGINT(...)

    CODE:
#if ((PERL_REVISION == 5) && (PERL_VERSION >= 10) && (PERL_VERSION <= 30)) && defined(HAS_SIGACTION) && defined(SA_SIGINFO)
    if (ApacheSIGINT) (*ApacheSIGINT)(SIGINT, NULL, NULL); 
#else 
    if (ApacheSIGINT) (*ApacheSIGINT)(SIGINT);
#endif 
