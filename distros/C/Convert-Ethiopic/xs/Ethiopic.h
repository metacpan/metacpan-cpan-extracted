#ifndef ETHIOPICXS_H
#define ETHIOPICXS_H 1

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


/* lets make XS forward and backwards compatible... */

#ifdef  PERL5004_COMPAT
# define PL_na na
# define PL_sv_yes sv_yes
# define PL_sv_no sv_no
# define PL_sv_undef sv_undef
# define PL_stack_max stack_max
# define PL_stack_sp stack_sp
#endif /* PERL5004_COMPAT */

#include <libeth/langxs.h>
#include <libeth/ettime.h>
#include <libeth/etstdlib.h>
#include <libeth/etctype.h>


typedef HV * Convert__Ethiopic__String;
typedef HV * Convert__Ethiopic__File;
typedef HV * Convert__Ethiopic__System;
typedef HV * Convert__Ethiopic__Number;
typedef HV * Convert__Ethiopic__Date;
typedef HV * Convert__Ethiopic__Char;


enum CalendarSys { ethio, euro };

#endif /* ETHIOPICXS_H */
