#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seqread		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseqread.c: automatically generated

AjPSeqin
ajSeqinNew ()
    OUTPUT:
       RETVAL

void
ajSeqinDel (pthis)
       AjPSeqin& pthis
    OUTPUT:
       pthis

void
ajSeqinUsa (pthis, Usa)
       AjPSeqin& pthis
       const AjPStr Usa
    OUTPUT:
       pthis

void
ajSeqinSetNuc (seqin)
       AjPSeqin seqin

void
ajSeqinSetProt (seqin)
       AjPSeqin seqin

void
ajSeqinSetRange (seqin, ibegin, iend)
       AjPSeqin seqin
       ajint ibegin
       ajint iend

AjBool
ajSeqAllRead (thys, seqin)
       AjPSeq thys
       AjPSeqin seqin
    OUTPUT:
       RETVAL
       thys

AjPSeqall
ajSeqallFile (usa)
       const AjPStr usa
    OUTPUT:
       RETVAL

AjBool
ajSeqallNext (seqall, retseq)
       AjPSeqall seqall
       AjPSeq& retseq
    OUTPUT:
       RETVAL
       retseq

void
ajSeqinClearPos (thys)
       AjPSeqin thys

void
ajSeqinClear (thys)
       AjPSeqin thys
    OUTPUT:
       thys

AjBool
ajSeqRead (thys, seqin)
       AjPSeq thys
       AjPSeqin seqin
    OUTPUT:
       RETVAL
       thys

AjBool
ajSeqsetRead (thys, seqin)
       AjPSeqset thys
       AjPSeqin seqin
    OUTPUT:
       RETVAL
       thys

AjBool
ajSeqsetallRead (thys, seqin)
       AjPList thys
       AjPSeqin seqin
    OUTPUT:
       RETVAL
       thys

ajint
ajSeqsetFromList (thys, list)
       AjPSeqset thys
       const AjPList list
    OUTPUT:
       RETVAL
       thys

ajint
ajSeqsetFromPair (thys, seqa, seqb)
       AjPSeqset thys
       const AjPSeq seqa
       const AjPSeq seqb
    OUTPUT:
       RETVAL
       thys

ajint
ajSeqsetApp (thys, seq)
       AjPSeqset thys
       const AjPSeq seq
    OUTPUT:
       RETVAL
       thys

void
ajSeqPrintInFormat (outf, full)
       AjPFile outf
       AjBool full

AjBool
ajSeqFormatTest (format)
       const AjPStr format
    OUTPUT:
       RETVAL

AjPSeqQuery
ajSeqQueryNew ()
    OUTPUT:
       RETVAL

void
ajSeqQueryDel (pthis)
       AjPSeqQuery& pthis
    OUTPUT:
       pthis

void
ajSeqQueryClear (thys)
       AjPSeqQuery thys

AjBool
ajSeqQueryWild (qry)
       AjPSeqQuery qry
    OUTPUT:
       RETVAL

void
ajSeqQueryStarclear (qry)
       AjPSeqQuery qry

AjBool
ajSeqQueryIs (qry)
       const AjPSeqQuery qry
    OUTPUT:
       RETVAL

void
ajSeqQueryTrace (thys)
       const AjPSeqQuery thys

AjBool
ajSeqParseFasta (instr, id, acc, sv, desc)
       const AjPStr instr
       AjPStr& id
       AjPStr& acc
       AjPStr& sv
       AjPStr& desc
    OUTPUT:
       RETVAL
       id
       acc
       sv
       desc

AjBool
ajSeqParseNcbi (instr, id, acc, sv, gi, db, desc)
       const AjPStr instr
       AjPStr& id
       AjPStr& acc
       AjPStr& sv
       AjPStr& gi
       AjPStr& db
       AjPStr& desc
    OUTPUT:
       RETVAL
       id
       acc
       sv
       gi
       db
       desc

AjBool
ajSeqGetFromUsa (thys, protein, seq)
       const AjPStr thys
       AjBool protein
       AjPSeq& seq
    OUTPUT:
       RETVAL
       seq

AjBool
ajSeqsetGetFromUsa (thys, seq)
       const AjPStr thys
       AjPSeqset& seq
    OUTPUT:
       RETVAL
       seq

void
ajSeqReadExit ()

void
ajSeqinTrace (thys)
       const AjPSeqin thys

