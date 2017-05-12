#define PERL_CORE

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static OP *(*PL_ppaddr_bak[OP_max + 1])(pTHX);

OP * aho(pTHX) {
    if (!(PL_op->op_type % 3)) PerlIO_printf(PerlIO_stderr(), "AHO: %d\n", PL_op->op_type);
    return PL_ppaddr_bak[PL_op->op_type](aTHX);
}

MODULE = Acme::NabeAtzz		PACKAGE = Acme::NabeAtzz

PROTOTYPES: ENABLE

void
_setup()
    PROTOTYPE:
    CODE: 
        int i;
        for (i = 0;i < OP_max;i++) {
            PL_ppaddr_bak[i] = PL_ppaddr[i];
            PL_ppaddr[i]     = aho;
        }
