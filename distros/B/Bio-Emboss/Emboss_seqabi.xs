#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seqabi		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseqabi.c: automatically generated

AjBool
ajSeqABITest (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

AjBool
ajSeqABIReadSeq (fp, baseO, numBases, nseq)
       AjPFile fp
       ajlong baseO
       ajlong numBases
       AjPStr& nseq
    OUTPUT:
       RETVAL
       nseq

AjBool
ajSeqABIMachineName (fp, machine)
       AjPFile fp
       AjPStr& machine
    OUTPUT:
       RETVAL
       machine

ajint
ajSeqABIGetNData (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetNBase (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

void
ajSeqABIGetData (fp, Offset, numPoints, trace)
       AjPFile fp
       const ajlong* Offset
       ajlong numPoints
       AjPInt2d trace
    OUTPUT:
       trace

void
ajSeqABIGetBasePosition (fp, numBases, basePositions)
       AjPFile fp
       ajlong numBases
       AjPShort& basePositions
    OUTPUT:
       basePositions

void
ajSeqABIGetSignal (fp, fwo_, sigC, sigA, sigG, sigT)
       AjPFile fp
       ajlong fwo_
       ajshort& sigC
       ajshort& sigA
       ajshort& sigG
       ajshort& sigT
    OUTPUT:
       sigC
       sigA
       sigG
       sigT

float
ajSeqABIGetBaseSpace (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetBaseOffset (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetBasePosOffset (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetFWO (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetPrimerOffset (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

ajint
ajSeqABIGetPrimerPosition (fp)
       AjPFile fp
    OUTPUT:
       RETVAL

AjBool
ajSeqABIGetTraceOffset (fp, Offset)
       AjPFile fp
       ajlong & Offset
    OUTPUT:
       RETVAL
       Offset

AjBool
ajSeqABISampleName (fp, sample)
       AjPFile fp
       AjPStr& sample
    OUTPUT:
       RETVAL
       sample

