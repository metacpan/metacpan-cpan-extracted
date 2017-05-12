#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embread		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embread.c: automatically generated

AjBool
embReadAminoDataDoubleC (s, a, fill)
       const char* s
       double*& a
       double fill
    OUTPUT:
       RETVAL
       a

AjBool
embReadAminoDataFloatC (s, a, fill)
       const char* s
       float*& a
       float fill
    OUTPUT:
       RETVAL
       a

AjBool
embReadAminoDataIntC (s, a, fill)
       const char* s
       ajint*& a
       ajint fill
    OUTPUT:
       RETVAL
       a

