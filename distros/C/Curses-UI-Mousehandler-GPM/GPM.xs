#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <handler-gpm.h>

MODULE = Curses::UI::Mousehandler::GPM		PACKAGE = Curses::UI::Mousehandler::GPM			

PROTOTYPES: ENABLE

MEVENT*
gpm_get_mouse_event()
	PREINIT:
		MEVENT event;
	CODE:
		RETVAL = gpm_get_mouse_event ( &event );
		ST(0) = sv_newmortal();
		if (RETVAL != NULL) {
			sv_setpvn(ST(0), (char *)RETVAL, sizeof(MEVENT) );
		}


int
gpm_enable()

