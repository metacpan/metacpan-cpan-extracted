#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_call		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajcall.c: automatically generated

void*
ajCall (name)
       const char* name
    OUTPUT:
       RETVAL

void
ajCallExit ()

