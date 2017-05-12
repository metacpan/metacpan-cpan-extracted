#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embmisc		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embmisc.c: automatically generated

AjBool
embMiscMatchPattern (str, pattern)
       const AjPStr str
       const AjPStr pattern
    OUTPUT:
       RETVAL

