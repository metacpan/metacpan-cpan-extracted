#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_reg		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajreg.c: automatically generated

AjPRegexp
ajRegComp (exp)
       const AjPStr exp
    OUTPUT:
       RETVAL

AjPRegexp
ajRegCompC (exp)
       const char* exp
    OUTPUT:
       RETVAL

AjPRegexp
ajRegCompCase (exp)
       const AjPStr exp
    OUTPUT:
       RETVAL

AjPRegexp
ajRegCompCaseC (exp)
       const char* exp
    OUTPUT:
       RETVAL

AjBool
ajRegExec (prog, str)
       AjPRegexp prog
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajRegExecC (prog, str)
       AjPRegexp prog
       const char* str
    OUTPUT:
       RETVAL

ajint
ajRegOffset (rp)
       const AjPRegexp rp
    OUTPUT:
       RETVAL

ajint
ajRegOffsetI (rp, isub)
       const AjPRegexp rp
       ajint isub
    OUTPUT:
       RETVAL

ajint
ajRegLenI (rp, isub)
       const AjPRegexp rp
       ajint isub
    OUTPUT:
       RETVAL

AjBool
ajRegPost (rp, post)
       const AjPRegexp rp
       AjPStr& post
    OUTPUT:
       RETVAL
       post

AjBool
ajRegPostC (rp, post)
       const AjPRegexp rp
       const char*& post
    OUTPUT:
       RETVAL
       post

AjBool
ajRegPre (rp, dest)
       const AjPRegexp rp
       AjPStr& dest
    OUTPUT:
       RETVAL
       dest

AjBool
ajRegSubI (rp, isub, dest)
       const AjPRegexp rp
       ajint isub
       AjPStr& dest
    OUTPUT:
       RETVAL
       dest

void
ajRegFree (pexp)
       AjPRegexp& pexp
    OUTPUT:
       pexp

void
ajRegTrace (exp)
       const AjPRegexp exp

void
ajRegExit ()

