#include "champlain-perl.h"


MODULE = Champlain  PACKAGE = Champlain  PREFIX = champlain_


BOOT:
#include "register.xsh"
#include "boot.xsh"


guint 
MAJOR_VERSION ()
	CODE:
		RETVAL = CHAMPLAIN_MAJOR_VERSION;
	
	OUTPUT:
		RETVAL


guint 
MINOR_VERSION ()
	CODE:
		RETVAL = CHAMPLAIN_MINOR_VERSION;
	
	OUTPUT:
		RETVAL


guint 
MICRO_VERSION ()
	CODE:
		RETVAL = CHAMPLAIN_MICRO_VERSION;
	
	OUTPUT:
		RETVAL


void
GET_VERSION_INFO (class)
	PPCODE:
		EXTEND (SP, 3);
		PUSHs (sv_2mortal (newSViv (CHAMPLAIN_MAJOR_VERSION)));
		PUSHs (sv_2mortal (newSViv (CHAMPLAIN_MINOR_VERSION)));
		PUSHs (sv_2mortal (newSViv (CHAMPLAIN_MICRO_VERSION)));
		PERL_UNUSED_VAR (ax);


gboolean
CHECK_VERSION (class, int major, int minor, int micro)
	CODE:
		RETVAL = CHAMPLAIN_CHECK_VERSION (major, minor, micro);

	OUTPUT:
		RETVAL


gboolean
HAS_MEMPHIS ()
	CODE:
#ifdef CHAMPLAINPERL_MEMPHIS
		RETVAL = TRUE;
#else
		RETVAL = FALSE;
#endif

	OUTPUT:
		RETVAL
