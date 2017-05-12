#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_nexus		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajnexus.c: automatically generated

AjPNexus
ajNexusParse (buff)
       AjPFileBuff buff
    OUTPUT:
       RETVAL

AjPNexus
ajNexusNew ()
    OUTPUT:
       RETVAL

void
ajNexusDel (pthys)
       AjPNexus& pthys
    OUTPUT:
       pthys

void
ajNexusTrace (thys)
       const AjPNexus thys

AjPStr*
ajNexusGetTaxa (thys)
       const AjPNexus thys
    OUTPUT:
       RETVAL

ajuint
ajNexusGetNtaxa (thys)
       const AjPNexus thys
    OUTPUT:
       RETVAL

AjPStr*
ajNexusGetSequences (thys)
       AjPNexus thys
    OUTPUT:
       RETVAL

