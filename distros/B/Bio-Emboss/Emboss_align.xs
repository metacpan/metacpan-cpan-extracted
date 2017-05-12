#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_align		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajalign.c: automatically generated

AjBool
ajAlignDefine (thys, seqset)
       AjPAlign thys
       AjPSeqset seqset
    OUTPUT:
       RETVAL

AjBool
ajAlignDefineSS (thys, seqa, seqb)
       AjPAlign thys
       AjPSeq seqa
       AjPSeq seqb
    OUTPUT:
       RETVAL

AjBool
ajAlignDefineCC (thys, seqa, seqb, namea, nameb)
       AjPAlign thys
       const char* seqa
       const char* seqb
       const char* namea
       const char* nameb
    OUTPUT:
       RETVAL

void
ajAlignDel (pthys)
       AjPAlign& pthys
    OUTPUT:
       pthys

void
ajAlignReset (thys)
       AjPAlign thys
    OUTPUT:
       thys

AjBool
ajAlignOpen (thys, name)
       AjPAlign thys
       const AjPStr name
    OUTPUT:
       RETVAL

AjBool
ajAlignFormatDefault (pformat)
       AjPStr& pformat
    OUTPUT:
       RETVAL
       pformat

const char*
ajAlignGetFilename (thys)
       const AjPAlign thys
    OUTPUT:
       RETVAL

const AjPStr
ajAlignGetFormat (thys)
       const AjPAlign thys
    OUTPUT:
       RETVAL

AjBool
ajAlignFindFormat (format, iformat)
       const AjPStr format
       ajint& iformat
    OUTPUT:
       RETVAL
       iformat

AjBool
ajAlignValid (thys)
       AjPAlign thys
    OUTPUT:
       RETVAL

AjPAlign
ajAlignNew ()
    OUTPUT:
       RETVAL

void
ajAlignWrite (thys)
       AjPAlign thys

void
ajAlignClose (thys)
       AjPAlign thys

void
ajAlignWriteHeader (thys)
       AjPAlign thys

void
ajAlignWriteTail (thys)
       AjPAlign thys

void
ajAlignSetHeader (thys, header)
       AjPAlign thys
       const AjPStr header

void
ajAlignSetHeaderC (thys, header)
       AjPAlign thys
       const char* header

void
ajAlignSetHeaderApp (thys, header)
       AjPAlign thys
       const AjPStr header

void
ajAlignSetTail (thys, tail)
       AjPAlign thys
       const AjPStr tail

void
ajAlignSetTailC (thys, tail)
       AjPAlign thys
       const char* tail

void
ajAlignSetTailApp (thys, tail)
       AjPAlign thys
       const AjPStr tail

void
ajAlignSetSubTail (thys, tail)
       AjPAlign thys
       const AjPStr tail

void
ajAlignSetSubTailC (thys, tail)
       AjPAlign thys
       const char* tail

void
ajAlignSetSubTailApp (thys, tail)
       AjPAlign thys
       const AjPStr tail

void
ajAlignSetSubHeader (thys, subheader)
       AjPAlign thys
       const AjPStr subheader

void
ajAlignSetSubHeaderC (thys, subheader)
       AjPAlign thys
       const char* subheader

void
ajAlignSetSubHeaderApp (thys, subheader)
       AjPAlign thys
       const AjPStr subheader

void
ajAlignSetSubHeaderPre (thys, subheader)
       AjPAlign thys
       const AjPStr subheader

void
ajAlignSetMatrixName (thys, matrix)
       AjPAlign thys
       const AjPStr matrix

void
ajAlignSetMatrixNameC (thys, matrix)
       AjPAlign thys
       const char* matrix

void
ajAlignSetMatrixInt (thys, matrix)
       AjPAlign thys
       AjPMatrix matrix

void
ajAlignSetMatrixFloat (thys, matrix)
       AjPAlign thys
       AjPMatrixf matrix

void
ajAlignSetGapI (thys, gappen, extpen)
       AjPAlign thys
       ajint gappen
       ajint extpen

void
ajAlignSetGapR (thys, gappen, extpen)
       AjPAlign thys
       float gappen
       float extpen

void
ajAlignSetScoreI (thys, score)
       AjPAlign thys
       ajint score

void
ajAlignSetScoreL (thys, score)
       AjPAlign thys
       ajlong score

void
ajAlignSetScoreR (thys, score)
       AjPAlign thys
       float score

void
ajAlignSetStats (thys, iali, len, ident, sim, gaps, score)
       AjPAlign thys
       ajint iali
       ajint len
       ajint ident
       ajint sim
       ajint gaps
       const AjPStr score

void
ajAlignSetSubStandard (thys, iali)
       AjPAlign thys
       ajint iali

void
ajAlignSetType (thys)
       AjPAlign thys

void
ajAlignSetExternal (thys, external)
       AjPAlign thys
       AjBool external

AjBool
ajAlignSetRange (thys, start1, end1, len1, off1, start2, end2, len2, off2)
       AjPAlign thys
       ajint start1
       ajint end1
       ajint len1
       ajint off1
       ajint start2
       ajint end2
       ajint len2
       ajint off2
    OUTPUT:
       RETVAL

AjBool
ajAlignSetSubRange (thys, substart1, start1, end1, rev1, len1, substart2, start2, end2, rev2, len2)
       AjPAlign thys
       ajint substart1
       ajint start1
       ajint end1
       AjBool rev1
       ajint len1
       ajint substart2
       ajint start2
       ajint end2
       AjBool rev2
       ajint len2
    OUTPUT:
       RETVAL

void
ajAlignTraceT (thys, title)
       const AjPAlign thys
       const char* title

void
ajAlignTrace (thys)
       const AjPAlign thys

void
ajAlignPrintFormat (outf, full)
       AjPFile outf
       AjBool full

AjBool
ajAlignConsStats (thys, mymatrix, cons, retident, retsim, retgap, retlen)
       const AjPSeqset thys
       AjPMatrix mymatrix
       AjPStr& cons
       ajint& retident
       ajint& retsim
       ajint& retgap
       ajint& retlen
    OUTPUT:
       RETVAL
       mymatrix
       cons
       retident
       retsim
       retgap
       retlen

void
ajAlignExit ()

ajint
ajAlignGetLen (thys)
       const AjPAlign thys
    OUTPUT:
       RETVAL

