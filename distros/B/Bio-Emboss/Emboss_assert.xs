#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_assert		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajassert.c: automatically generated

void
assert (e)
       ajint e

