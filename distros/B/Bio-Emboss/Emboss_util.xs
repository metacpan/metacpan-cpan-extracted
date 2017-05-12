#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_util		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajutil.c: automatically generated

void
ajExit ()

void
ajExitBad ()

void
ajExitAbort ()

void
ajUtilCatch ()

void
ajReset ()

void
ajByteRevInt (ival)
       ajint& ival
    OUTPUT:
       ival

void
ajByteRevLen2 (sval)
       short& sval
    OUTPUT:
       sval

void
ajByteRevLen4 (ival)
       ajint& ival
    OUTPUT:
       ival

void
ajByteRevLen8 (lval)
       ajlong& lval
    OUTPUT:
       lval

void
ajByteRevLong (lval)
       ajlong& lval
    OUTPUT:
       lval

void
ajByteRevShort (sval)
       short& sval
    OUTPUT:
       sval

void
ajByteRevUint (ival)
       ajuint& ival
    OUTPUT:
       ival

AjBool
ajUtilGetBigendian ()
    OUTPUT:
       RETVAL

AjBool
ajUtilGetUid (Puid)
       AjPStr& Puid
    OUTPUT:
       RETVAL
       Puid

void
ajUtilLoginfo ()

