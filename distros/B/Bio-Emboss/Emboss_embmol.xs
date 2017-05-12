#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embmol		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embmol.c: automatically generated

ajint
embMolGetFrags (thys, rno, l)
       const AjPStr thys
       ajint rno
       AjPList& l
    OUTPUT:
       RETVAL
       l

