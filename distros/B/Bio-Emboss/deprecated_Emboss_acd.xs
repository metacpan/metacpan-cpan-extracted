#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_acd_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajacd.h: automatically generated

AjBool
ajAcdDebug ()
    OUTPUT:
       RETVAL

AjBool
ajAcdDebugIsSet ()
    OUTPUT:
       RETVAL


AjBool
ajAcdFilter ()
    OUTPUT:
       RETVAL


AjPPhyloState
ajAcdGetDiscretestatesI (token, num)
       const char *token
       ajint num
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetListI (token, num)
       const char *token
       ajint num
    OUTPUT:
       RETVAL

AjPStr
ajAcdGetSelectI (token, num)
       const char *token
       ajint num
    OUTPUT:
       RETVAL

AjPSeqset
ajAcdGetSeqsetallI (token, num)
       const char *token
       ajint num
    OUTPUT:
       RETVAL


AjPPhyloTree
ajAcdGetTreeI (token, num)
       const char *token
       ajint num
    OUTPUT:
       RETVAL


const char*
ajAcdProgram ()
    OUTPUT:
       RETVAL

void
ajAcdProgramS (pgm)
       AjPStr& pgm
    OUTPUT:
       pgm


AjBool
ajAcdStdout ()
    OUTPUT:
       RETVAL

const AjPStr
ajAcdValue (token)
       const char* token
    OUTPUT:
       RETVAL

