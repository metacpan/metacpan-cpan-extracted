#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seqdb		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseqdb.c: automatically generated

AjBool
ajSeqMethodTest (method)
       const AjPStr method
    OUTPUT:
       RETVAL

SeqPAccess
ajSeqMethod (method)
       const AjPStr method
    OUTPUT:
       RETVAL

AjBool
ajSeqAccessAsis (seqin)
       AjPSeqin seqin
    OUTPUT:
       RETVAL

AjBool
ajSeqAccessFile (seqin)
       AjPSeqin seqin
    OUTPUT:
       RETVAL

AjBool
ajSeqAccessOffset (seqin)
       AjPSeqin seqin
    OUTPUT:
       RETVAL

void
ajSeqPrintAccess (outf, full)
       AjPFile outf
       AjBool full

void
ajSeqDbExit ()

