#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embshow		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embshow.c: automatically generated

EmbPShow
embShowNew (seq, begin, end, width, length, margin, html, offset)
       const AjPSeq seq
       ajint begin
       ajint end
       ajint width
       ajint length
       ajint margin
       AjBool html
       ajint offset
    OUTPUT:
       RETVAL

void
embShowDel (pthis)
       EmbPShow& pthis
    OUTPUT:
       pthis

void
embShowAddSeq (thys, number, threeletter, upperrange, colour)
       EmbPShow thys
       AjBool number
       AjBool threeletter
       const AjPRange upperrange
       const AjPRange colour

void
embShowAddBlank (thys)
       EmbPShow thys

void
embShowAddTicks (thys)
       EmbPShow thys

void
embShowAddTicknum (thys)
       EmbPShow thys

void
embShowAddComp (thys, number)
       EmbPShow thys
       AjBool number

void
embShowAddTran (thys, trnTable, frame, threeletter, number, regions, orfminsize, lcinterorf, firstorf, lastorf, showframe)
       EmbPShow thys
       const AjPTrn trnTable
       ajint frame
       AjBool threeletter
       AjBool number
       const AjPRange regions
       ajint orfminsize
       AjBool lcinterorf
       AjBool firstorf
       AjBool lastorf
       AjBool showframe

void
embShowAddRE (thys, sense, restrictlist, plasmid, flat)
       EmbPShow thys
       ajint sense
       const AjPList restrictlist
       AjBool plasmid
       AjBool flat

void
embShowAddFT (thys, feat)
       EmbPShow thys
       const AjPFeattable feat

void
embShowAddNote (thys, regions)
       EmbPShow thys
       const AjPRange regions

void
embShowPrint (out, thys)
       AjPFile out
       const EmbPShow thys

void
embShowUpperRange (line, upperrange, pos)
       AjPStr & line
       const AjPRange upperrange
       ajint pos

void
embShowColourRange (line, colour, pos)
       AjPStr & line
       const AjPRange colour
       ajint pos

