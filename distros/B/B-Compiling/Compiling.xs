#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

STATIC SV *compiling_sv;

MODULE = B::Compiling  PACKAGE = B::Compiling

PROTOTYPES: DISABLE

void
PL_compiling ()
    PPCODE:
        XPUSHs (compiling_sv);

BOOT:
    {
        HV *cop_stash = gv_stashpv ("B::COP", 0);

        if (!cop_stash) {
            croak ("B doesn't provide B::COP");
        }

        compiling_sv = newRV_noinc (newSViv (PTR2IV (&PL_compiling)));
        sv_bless (compiling_sv, cop_stash);
    }
