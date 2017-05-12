#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seqtype		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseqtype.c: automatically generated

AjBool
ajSeqTypeCheckS (pthys, type_name)
       AjPStr& pthys
       const AjPStr type_name
    OUTPUT:
       RETVAL
       pthys

AjBool
ajSeqTypeCheckIn (thys, seqin)
       AjPSeq thys
       const AjPSeqin seqin
    OUTPUT:
       RETVAL

char
ajSeqTypeNucS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeDnaS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeRnaS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeGapdnaS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeGaprnaS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeGapnucS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeAnyprotS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeProtS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

char
ajSeqTypeGapanyS (thys)
       const AjPStr thys
    OUTPUT:
       RETVAL

void
ajSeqGap (thys, gapc, padc)
       AjPSeq thys
       char gapc
       char padc

void
ajSeqGapLen (thys, gapc, padc, ilen)
       AjPSeq thys
       char gapc
       char padc
       ajint ilen

void
ajSeqGapS (seq, gapc)
       AjPStr& seq
       char gapc
    OUTPUT:
       seq

void
ajSeqSetNuc (thys)
       AjPSeq thys

void
ajSeqSetProt (thys)
       AjPSeq thys

void
ajSeqsetSetNuc (thys)
       AjPSeqset thys

void
ajSeqsetSetProt (thys)
       AjPSeqset thys

void
ajSeqType (thys)
       AjPSeq thys

void
ajSeqPrintType (outf, full)
       AjPFile outf
       AjBool full

AjBool
ajSeqTypeIsProt (type_name)
       const AjPStr type_name
    OUTPUT:
       RETVAL

AjBool
ajSeqTypeIsNuc (type_name)
       const AjPStr type_name
    OUTPUT:
       RETVAL

AjBool
ajSeqTypeIsAny (type_name)
       const AjPStr type_name
    OUTPUT:
       RETVAL

AjBool
ajSeqTypeSummary (type_name, Ptype, gaps)
       const AjPStr type_name
       AjPStr& Ptype
       AjBool& gaps
    OUTPUT:
       RETVAL
       Ptype
       gaps

void
ajSeqTypeExit ()

void
ajSeqTypeUnused ()

