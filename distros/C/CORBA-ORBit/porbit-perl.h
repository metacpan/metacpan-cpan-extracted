#ifndef __PORBIT_PERL_H__
#define __PORBIT_PERL_H__

/* Both ORBit and Perl like polluting the namespace and defining DEBUG
 */
#include "EXTERN.h"
#undef DEBUG
#include "perl.h"
#undef DEBUG
#include "XSUB.h"

/* Some variables changed names between perl5.004 and perl5.005 */
#ifdef PERL5004_COMPAT
#define PL_na na
#define PL_sv_yes sv_yes
#define PL_sv_no sv_no
#define PL_sv_undef sv_undef
#define PL_stack_max stack_max
#define PL_stack_sp stack_sp

/* this function was added in 5.005, so we provide it in constsub.c */
void newCONSTSUB(HV *stash, char *name, SV *sv);
#endif /* PERL5004_COMPAT */

#endif /* __PORBIT_PERL_H__ */
