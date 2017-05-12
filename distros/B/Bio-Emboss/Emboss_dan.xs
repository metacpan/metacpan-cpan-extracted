#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_dan		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajdan.c: automatically generated

void
ajMeltInit (isdna, savesize)
       AjBool isdna
       ajint savesize

float
ajProbScore (seq1, seq2, len)
       const AjPStr seq1
       const AjPStr seq2
       ajint len
    OUTPUT:
       RETVAL

float
ajMeltEnergy (strand, len, shift, isDNA, maySave, enthalpy, entropy)
       const AjPStr strand
       ajint len
       ajint shift
       AjBool isDNA
       AjBool maySave
       float& enthalpy
       float& entropy
    OUTPUT:
       RETVAL
       enthalpy
       entropy

float
ajTm (strand, len, shift, saltconc, DNAconc, isDNA)
       const AjPStr strand
       ajint len
       ajint shift
       float saltconc
       float DNAconc
       AjBool isDNA
    OUTPUT:
       RETVAL

float
ajMeltGC (strand, len)
       const AjPStr strand
       ajint len
    OUTPUT:
       RETVAL

float
ajMeltEnergy2 (strand, pos, len, isDNA, enthalpy, entropy, saveentr, saveenth, saveener)
       const char * strand
       ajint pos
       ajint len
       AjBool isDNA
       float & enthalpy
       float & entropy
       float *& saveentr
       float *& saveenth
       float *& saveener
    OUTPUT:
       RETVAL
       enthalpy
       entropy
       saveentr
       saveenth
       saveener

float
ajTm2 (strand, pos, len, saltconc, DNAconc, isDNA, saveentr, saveenth, saveener)
       const char* strand
       ajint pos
       ajint len
       float saltconc
       float DNAconc
       AjBool isDNA
       float *& saveentr
       float *& saveenth
       float *& saveener
    OUTPUT:
       RETVAL
       saveentr
       saveenth
       saveener

float
ajProdTm (gc, saltconc, len)
       float gc
       float saltconc
       ajint len
    OUTPUT:
       RETVAL

float
ajAnneal (tmprimer, tmproduct)
       float tmprimer
       float tmproduct
    OUTPUT:
       RETVAL

void
ajMeltExit ()

