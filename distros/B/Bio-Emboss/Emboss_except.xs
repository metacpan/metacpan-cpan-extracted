#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_except		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajexcept.c: automatically generated

void
ajExceptRaise (e, file, line)
       const T* e
       const char* file
       ajint line

