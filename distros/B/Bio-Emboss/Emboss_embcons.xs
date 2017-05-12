#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embcons		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embcons.c: automatically generated

void
embConsCalc (seqset, cmpmatrix, nseqs, mlen, fplural, setcase, identity, gaps, cons)
       const AjPSeqset seqset
       const AjPMatrix cmpmatrix
       ajint nseqs
       ajint mlen
       float fplural
       float setcase
       ajint identity
       AjBool gaps
       AjPStr & cons
    OUTPUT:
       cons

