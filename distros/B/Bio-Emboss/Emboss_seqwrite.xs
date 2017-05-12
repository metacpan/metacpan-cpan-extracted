#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seqwrite		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseqwrite.c: automatically generated

AjBool
ajSeqoutOpen (seqout)
       AjPSeqout seqout
    OUTPUT:
       RETVAL
       seqout

void
ajSeqoutClear (seqout)
       AjPSeqout seqout

void
ajSeqoutTrace (seqout)
       const AjPSeqout seqout

AjPSeqout
ajSeqoutNew ()
    OUTPUT:
       RETVAL

AjPSeqout
ajSeqoutNewFile (file)
       AjPFile file
    OUTPUT:
       RETVAL

void
ajSeqoutDel (Pseqout)
       AjPSeqout& Pseqout
    OUTPUT:
       Pseqout

void
ajSeqoutWriteSeq (outseq, seq)
       AjPSeqout outseq
       const AjPSeq seq

void
ajSeqoutWriteSet (outseq, seq)
       AjPSeqout outseq
       const AjPSeqset seq

void
ajSeqoutClose (seqout)
       AjPSeqout seqout

AjBool
ajSeqoutOpenFilename (seqout, name)
       AjPSeqout seqout
       const AjPStr name
    OUTPUT:
       RETVAL

AjPSeqout
ajSeqoutNewFormatC (txt)
       const char* txt
    OUTPUT:
       RETVAL

AjPSeqout
ajSeqoutNewFormatS (str)
       const AjPStr str
    OUTPUT:
       RETVAL

void
ajSeqoutDumpSwisslike (outseq, seq, prefix)
       AjPSeqout outseq
       const AjPStr seq
       const char * prefix
    OUTPUT:
       outseq

void
ajSeqoutClearUsa (seqout, usa)
       AjPSeqout seqout
       const AjPStr usa

AjBool
ajSeqoutSetFormatC (seqout, txt)
       AjPSeqout seqout
       const char * txt
    OUTPUT:
       RETVAL

AjBool
ajSeqoutSetFormatS (seqout, str)
       AjPSeqout seqout
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqoutSetNameDefaultC (seqout, multi, txt)
       AjPSeqout seqout
       AjBool multi
       const char* txt
    OUTPUT:
       RETVAL
       seqout

AjBool
ajSeqoutSetNameDefaultS (seqout, multi, str)
       AjPSeqout seqout
       AjBool multi
       const AjPStr str
    OUTPUT:
       RETVAL
       seqout

void
ajSeqoutPrintFormat (outf, full)
       AjPFile outf
       AjBool full

void
ajSeqoutGetBasecount (seqout, bases)
       const AjPSeqout seqout
       ajuint& bases
    OUTPUT:
       bases

ajint
ajSeqoutGetCheckgcg (seqout)
       const AjPSeqout seqout
    OUTPUT:
       RETVAL

void
ajSeqoutExit ()

AjBool
ajSeqoutstrGetFormatDefault (Pformat)
       AjPStr& Pformat
    OUTPUT:
       RETVAL
       Pformat

AjBool
ajSeqoutstrIsFormatExists (format)
       const AjPStr format
    OUTPUT:
       RETVAL

AjBool
ajSeqoutstrIsFormatSingle (format)
       const AjPStr format
    OUTPUT:
       RETVAL

