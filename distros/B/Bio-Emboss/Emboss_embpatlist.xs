#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embpatlist		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embpatlist.c: automatically generated

void
embPatlistSeqSearch (ftable, seq, plist, reverse)
       AjPFeattable ftable
       const AjPSeq seq
       AjPPatlistSeq plist
       AjBool reverse
    OUTPUT:
       ftable

void
embPatlistRegexSearch (ftable, seq, plist, reverse)
       AjPFeattable ftable
       const AjPSeq seq
       AjPPatlistRegex plist
       AjBool reverse
    OUTPUT:
       ftable

void
embPatternRegexSearch (ftable, seq, pat, reverse)
       AjPFeattable ftable
       const AjPSeq seq
       const AjPPatternRegex pat
       AjBool reverse
    OUTPUT:
       ftable

void
embPatternSeqSearch (ftable, seq, pat, reverse)
       AjPFeattable ftable
       const AjPSeq seq
       const AjPPatternSeq pat
       AjBool reverse
    OUTPUT:
       ftable

AjBool
embPatternSeqCompile (pat)
       AjPPatternSeq pat
    OUTPUT:
       RETVAL
       pat

