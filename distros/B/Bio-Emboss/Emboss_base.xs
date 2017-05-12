#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_base		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajbase.c: automatically generated

const AjPStr
ajBaseCodes (ibase)
       ajint ibase
    OUTPUT:
       RETVAL

ajint
ajAZToInt (c)
       ajint c
    OUTPUT:
       RETVAL

ajint
ajIntToAZ (n)
       ajint n
    OUTPUT:
       RETVAL

char
ajBinToAZ (c)
       ajint c
    OUTPUT:
       RETVAL

ajint
ajAZToBin (c)
       ajint c
    OUTPUT:
       RETVAL

char
ajAZToBinC (c)
       char c
    OUTPUT:
       RETVAL

AjBool
ajBaseInit ()
    OUTPUT:
       RETVAL

AjBool
ajBaseAa1ToAa3 (aa1, aa3)
       char aa1
       AjPStr & aa3
    OUTPUT:
       RETVAL
       aa3

float
ajBaseProb (base1, base2)
       ajint base1
       ajint base2
    OUTPUT:
       RETVAL

void
ajBaseExit ()

AjBool
ajBaseAa3ToAa1 (aa1, aa3)
       char & aa1
       const AjPStr aa3
    OUTPUT:
       RETVAL
       aa1

char
ajBaseComp (base)
       char base
    OUTPUT:
       RETVAL

