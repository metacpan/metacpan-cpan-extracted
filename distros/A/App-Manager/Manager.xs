#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/stat.h>

#define RETURN_BOOL(b) if (b) XSRETURN_YES; else XSRETURN_NO;

MODULE = App::Manager		PACKAGE = App::Manager

PROTOTYPES: ENABLE

char *
LIBTRACER_SO()
  	CODE:
        RETVAL = LIBTRACER_SO;
        OUTPUT:
        RETVAL

char *
LIBDIR()
  	CODE:
        RETVAL = LIBDIR;
        OUTPUT:
        RETVAL

# damn, POSIX doesn't include S_ISLNK!

void
S_ISDIR(mode)
  	int	mode
        PPCODE:
        RETURN_BOOL (S_ISDIR (mode));

void
S_ISREG(mode)
  	int	mode
        PPCODE:
        RETURN_BOOL (S_ISREG (mode));

void
S_ISLNK(mode)
  	int	mode
        PPCODE:
        RETURN_BOOL (S_ISLNK (mode));

void
S_IFMT()
	PPCODE:
        XSRETURN_IV (S_IFMT);

