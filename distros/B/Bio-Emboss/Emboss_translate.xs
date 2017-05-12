#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_translate		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajtranslate.c: automatically generated

void
ajTrnDel (pthis)
       AjPTrn& pthis
    OUTPUT:
       pthis

AjPTrn
ajTrnNewC (filename)
       const char* filename
    OUTPUT:
       RETVAL

AjPTrn
ajTrnNewI (trnFileNameInt)
       ajint trnFileNameInt
    OUTPUT:
       RETVAL

AjPTrn
ajTrnNew (trnFileName)
       const AjPStr trnFileName
    OUTPUT:
       RETVAL

void
ajTrnReadFile (trnObj, trnFile)
       AjPTrn trnObj
       AjPFile trnFile
    OUTPUT:
       trnObj

AjPSeq
ajTrnNewPep (nucleicSeq, frame)
       const AjPSeq nucleicSeq
       ajint frame
    OUTPUT:
       RETVAL

const AjPStr
ajTrnCodon (trnObj, codon)
       const AjPTrn trnObj
       const AjPStr codon
    OUTPUT:
       RETVAL

const AjPStr
ajTrnRevCodon (trnObj, codon)
       const AjPTrn trnObj
       const AjPStr codon
    OUTPUT:
       RETVAL

const AjPStr
ajTrnCodonC (trnObj, codon)
       const AjPTrn trnObj
       const char * codon
    OUTPUT:
       RETVAL

const AjPStr
ajTrnRevCodonC (trnObj, codon)
       const AjPTrn trnObj
       const char * codon
    OUTPUT:
       RETVAL

char
ajTrnCodonK (trnObj, codon)
       const AjPTrn trnObj
       const char * codon
    OUTPUT:
       RETVAL

char
ajTrnRevCodonK (trnObj, codon)
       const AjPTrn trnObj
       const char * codon
    OUTPUT:
       RETVAL

void
ajTrnC (trnObj, str, len, pep)
       const AjPTrn trnObj
       const char * str
       ajint len
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnRevC (trnObj, str, len, pep)
       const AjPTrn trnObj
       const char * str
       ajint len
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnAltRevC (trnObj, str, len, pep)
       const AjPTrn trnObj
       const char * str
       ajint len
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnStr (trnObj, str, pep)
       const AjPTrn trnObj
       const AjPStr str
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnRevStr (trnObj, str, pep)
       const AjPTrn trnObj
       const AjPStr str
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnAltRevStr (trnObj, str, pep)
       const AjPTrn trnObj
       const AjPStr str
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnSeq (trnObj, seq, pep)
       const AjPTrn trnObj
       const AjPSeq seq
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnRevSeq (trnObj, seq, pep)
       const AjPTrn trnObj
       const AjPSeq seq
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnAltRevSeq (trnObj, seq, pep)
       const AjPTrn trnObj
       const AjPSeq seq
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnCFrame (trnObj, seq, len, frame, pep)
       const AjPTrn trnObj
       const char * seq
       ajint len
       ajint frame
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnStrFrame (trnObj, seq, frame, pep)
       const AjPTrn trnObj
       const AjPStr seq
       ajint frame
       AjPStr & pep
    OUTPUT:
       pep

void
ajTrnSeqFrame (trnObj, seq, frame, pep)
       const AjPTrn trnObj
       const AjPSeq seq
       ajint frame
       AjPStr & pep
    OUTPUT:
       pep

AjPSeq
ajTrnSeqFramePep (trnObj, seq, frame)
       const AjPTrn trnObj
       const AjPSeq seq
       ajint frame
    OUTPUT:
       RETVAL

ajint
ajTrnCDangle (trnObj, seq, len, frame, pep)
       const AjPTrn trnObj
       const char * seq
       ajint len
       ajint frame
       AjPStr & pep
    OUTPUT:
       RETVAL
       pep

ajint
ajTrnStrDangle (trnObj, seq, frame, pep)
       const AjPTrn trnObj
       const AjPStr seq
       ajint frame
       AjPStr & pep
    OUTPUT:
       RETVAL
       pep

AjPSeq
ajTrnSeqOrig (trnObj, seq, frame)
       const AjPTrn trnObj
       const AjPSeq seq
       ajint frame
    OUTPUT:
       RETVAL

AjPStr
ajTrnGetTitle (thys)
       const AjPTrn thys
    OUTPUT:
       RETVAL

AjPStr
ajTrnGetFileName (thys)
       const AjPTrn thys
    OUTPUT:
       RETVAL

ajint
ajTrnStartStop (trnObj, codon, aa)
       const AjPTrn trnObj
       const AjPStr codon
       char & aa
    OUTPUT:
       RETVAL
       aa

ajint
ajTrnStartStopC (trnObj, codon, aa)
       const AjPTrn trnObj
       const char * codon
       char & aa
    OUTPUT:
       RETVAL
       aa

const AjPStr
ajTrnName (trnFileNameInt)
       ajint trnFileNameInt
    OUTPUT:
       RETVAL

void
ajTrnExit ()

