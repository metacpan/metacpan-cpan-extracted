#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embword		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embword.c: automatically generated

void
embWordLength (wordlen)
       ajint wordlen

void
embWordClear ()

void
embWordPrintTable (table)
       const AjPTable table

void
embWordPrintTableFI (table, mincount, outf)
       const AjPTable table
       ajint mincount
       AjPFile outf

void
embWordPrintTableF (table, outf)
       const AjPTable table
       AjPFile outf

void
embWordFreeTable (table)
       AjPTable& table
    OUTPUT:
       table

void
embWordMatchListDelete (plist)
       AjPList& plist

void
embWordMatchListPrint (file, list)
       AjPFile file
       const AjPList list

void
embWordMatchListConvToFeat (list, tab1, tab2, seq1, seq2)
       const AjPList list
       AjPFeattable& tab1
       AjPFeattable& tab2
       const AjPSeq seq1
       const AjPSeq seq2

ajint
embWordGetTable (table, seq)
       AjPTable& table
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjPList
embWordBuildMatchTable (seq1MatchTable, seq2, orderit)
       const AjPTable seq1MatchTable
       const AjPSeq seq2
       ajint orderit
    OUTPUT:
       RETVAL

void
embWordMatchMin (matchlist)
       AjPList matchlist

AjBool
embWordMatchIter (iter, start1, start2, len)
       AjIList iter
       ajint& start1
       ajint& start2
       ajint& len
    OUTPUT:
       RETVAL
       start1
       start2
       len

void
embWordUnused ()

void
embWordExit ()

