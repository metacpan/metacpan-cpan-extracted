#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embnmer		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embnmer.c: automatically generated

ajulong
embNmerNuc2int (seq, wordsize, offset, otherflag)
       const char * seq
       ajint wordsize
       ajint offset
       AjBool & otherflag
    OUTPUT:
       RETVAL
       otherflag

ajint
embNmerInt2nuc (seq, wordsize, value)
       AjPStr & seq
       ajint wordsize
       ajulong value
    OUTPUT:
       RETVAL
       seq

ajulong
embNmerProt2int (seq, wordsize, offset, otherflag, ignorebz)
       const char * seq
       ajint wordsize
       ajint offset
       AjBool & otherflag
       AjBool ignorebz
    OUTPUT:
       RETVAL
       otherflag

ajint
embNmerInt2prot (seq, wordsize, value, ignorebz)
       AjPStr & seq
       ajint wordsize
       ajulong value
       AjBool ignorebz
    OUTPUT:
       RETVAL
       seq

AjBool
embNmerGetNoElements (no_elements, word, seqisnuc, ignorebz)
       ajulong& no_elements
       ajint word
       AjBool seqisnuc
       AjBool ignorebz
    OUTPUT:
       RETVAL
       no_elements

