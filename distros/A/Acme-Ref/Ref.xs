#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Acme::Ref		PACKAGE = Acme::Ref		

SV *
_deref(int ref)
    CODE:
        if (ref) {
            SV *r = (SV *) ref;
            if (SvTYPE(r)>0) {
                RETVAL = newRV_inc(r);
            }
            else {
                RETVAL = &PL_sv_undef;
            }
        }
        else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL
