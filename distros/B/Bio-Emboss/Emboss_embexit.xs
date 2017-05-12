#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embexit		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embexit.c: automatically generated

void
embExit ()

void
embExitBad ()

