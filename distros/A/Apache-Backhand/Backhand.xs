/* ====================================================================
 * Copyright (c) 2000 David Lowe.
 *
 * Backhand.xs
 *
 * The XS side of the Apache::Backhand module
 * ==================================================================== */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "magic_c_int.h"

#include "ppport.h"

#include "mod_backhand.h"

MODULE = Apache::Backhand PACKAGE = Apache::Backhand PREFIX = backhand_
PROTOTYPES: ENABLE

int
backhand_MAXSERVERS()
	CODE:
		RETVAL = MAXSERVERS;
	OUTPUT:
		RETVAL

int
backhand_MAXSESSIONSPERSERVER()
	CODE:
		RETVAL = MAXSESSIONSPERSERVER;
	OUTPUT:
		RETVAL

int
backhand_SERVER_TIMEOUT()
	CODE:
		RETVAL = SERVER_TIMEOUT;
	OUTPUT:
		RETVAL

SV *
backhand_load_serverstats()
	PREINIT:
		int i;
		AV *statsa     = newAV();
	CODE:
		for (i = 0; i < MAXSERVERS; i++) {
		    HV *statsh = newHV();

		    hv_store(statsh, "mtime",     5,
                             newSV_magic_c_int((int *)&(serverstats[i].mtime)),
                             0);
		    hv_store(statsh, "arriba",    6,
                             newSV_magic_c_int(&(serverstats[i].arriba)),    0);
		    hv_store(statsh, "aservers",  8,
                             newSV_magic_c_int(&(serverstats[i].aservers)),  0);
		    hv_store(statsh, "nservers",  8,
                             newSV_magic_c_int(&(serverstats[i].nservers)),  0);
		    hv_store(statsh, "load",      4,
                             newSV_magic_c_int(&(serverstats[i].load)),      0);
		    hv_store(statsh, "load_hwm",  8,
                             newSV_magic_c_int(&(serverstats[i].load_hwm)),  0);
		    hv_store(statsh, "cpu",       3,
                             newSV_magic_c_int(&(serverstats[i].cpu)),       0);
                    hv_store(statsh, "ncpu",      4,
                             newSV_magic_c_int(&(serverstats[i].ncpu)),      0);
		    hv_store(statsh, "tmem",      4,
                             newSV_magic_c_int(&(serverstats[i].tmem)),      0);
		    hv_store(statsh, "amem",      4,
                             newSV_magic_c_int(&(serverstats[i].amem)),      0);
		    hv_store(statsh, "numbacked", 9,
                             newSV_magic_c_int(&(serverstats[i].numbacked)), 0);
		    hv_store(statsh, "tatime",    6,
                             newSV_magic_c_int(&(serverstats[i].tatime)),    0);

		    av_push(statsa, newRV((SV *)statsh));
		}
		RETVAL = newRV_noinc((SV *)statsa);
	OUTPUT:
		RETVAL

SV *
backhand_load_personal_arriba()
	CODE:
		RETVAL = newRV(newSV_magic_c_int(&mod_backhand_personal_arriba));
	OUTPUT:
		RETVAL
		
