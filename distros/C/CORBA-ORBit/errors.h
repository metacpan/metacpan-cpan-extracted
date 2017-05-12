#ifndef __PORBIT_ERRORS_H__
#define __PORBIT_ERRORS_H__

#include "porbit-perl.h"
#include <orb/orbit.h>

void porbit_throw (SV *e);
void porbit_init_exceptions (void);
const char *porbit_find_exception (const char *repoid);

void porbit_setup_exception (const char *repoid, const char *pkg,
			     const char *parent);

SV *porbit_system_except (const char *repoid, CORBA_unsigned_long minor, 
			  CORBA_completion_status status);
SV *porbit_user_except (const char *repoid, SV *value);
SV *porbit_builtin_except (CORBA_Environment *ev);



#endif /* __PORBIT_ERRORS_H__ */
