#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_pat		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajpat.c: automatically generated

AjPPatternSeq
ajPatternSeqNewList (plist, name, pat, mismatch)
       AjPPatlistSeq plist
       const AjPStr name
       const AjPStr pat
       ajuint mismatch
    OUTPUT:
       RETVAL

AjPPatternRegex
ajPatternRegexNewList (plist, name, pat)
       AjPPatlistRegex plist
       const AjPStr name
       const AjPStr pat
    OUTPUT:
       RETVAL

void
ajPatternRegexDel (pthys)
       AjPPatternRegex& pthys
    OUTPUT:
       pthys

void
ajPatternSeqDel (pthys)
       AjPPatternSeq& pthys
    OUTPUT:
       pthys

const AjPStr
ajPatternSeqGetName (thys)
       const AjPPatternSeq thys
    OUTPUT:
       RETVAL

const AjPStr
ajPatternRegexGetName (thys)
       const AjPPatternRegex thys
    OUTPUT:
       RETVAL

const AjPStr
ajPatternSeqGetPattern (thys)
       const AjPPatternSeq thys
    OUTPUT:
       RETVAL

const AjPStr
ajPatternRegexGetPattern (thys)
       const AjPPatternRegex thys
    OUTPUT:
       RETVAL

AjPPatComp
ajPatternSeqGetCompiled (thys)
       const AjPPatternSeq thys
    OUTPUT:
       RETVAL

AjPRegexp
ajPatternRegexGetCompiled (thys)
       const AjPPatternRegex thys
    OUTPUT:
       RETVAL

ajuint
ajPatternRegexGetType (thys)
       const AjPPatternRegex thys
    OUTPUT:
       RETVAL

ajuint
ajPatternSeqGetMismatch (thys)
       const AjPPatternSeq thys
    OUTPUT:
       RETVAL

void
ajPatternSeqSetCompiled (thys, pat)
       AjPPatternSeq thys
       char* pat
    OUTPUT:
       pat

void
ajPatternRegexSetCompiled (thys, pat)
       AjPPatternRegex thys
       AjPRegexp pat

void
ajPatternSeqDebug (pat)
       const AjPPatternSeq pat

void
ajPatternRegexDebug (pat)
       const AjPPatternRegex pat

AjPPatlistRegex
ajPatlistRegexNew ()
    OUTPUT:
       RETVAL

AjPPatlistSeq
ajPatlistSeqNew ()
    OUTPUT:
       RETVAL

AjPPatlistSeq
ajPatlistSeqNewType (type)
       AjBool type
    OUTPUT:
       RETVAL

void
ajPatlistRegexDel (pthys)
       AjPPatlistRegex& pthys
    OUTPUT:
       pthys

void
ajPatlistSeqDel (pthys)
       AjPPatlistSeq& pthys
    OUTPUT:
       pthys

AjPPatlistSeq
ajPatlistSeqRead (patspec, patname, fmt, protein, mismatches)
       const AjPStr patspec
       const AjPStr patname
       const AjPStr fmt
       AjBool protein
       ajuint mismatches
    OUTPUT:
       RETVAL

AjPPatlistRegex
ajPatlistRegexRead (patspec, patname, fmt, type, upper, lower)
       const AjPStr patspec
       const AjPStr patname
       const AjPStr fmt
       ajuint type
       AjBool upper
       AjBool lower
    OUTPUT:
       RETVAL

ajuint
ajPatlistSeqGetSize (thys)
       const AjPPatlistSeq thys
    OUTPUT:
       RETVAL

ajuint
ajPatlistRegexGetSize (thys)
       const AjPPatlistRegex thys
    OUTPUT:
       RETVAL

AjBool
ajPatlistSeqGetNext (thys, pattern)
       AjPPatlistSeq thys
       AjPPatternSeq& pattern
    OUTPUT:
       RETVAL
       pattern

AjBool
ajPatlistRegexGetNext (thys, pattern)
       AjPPatlistRegex thys
       AjPPatternRegex& pattern
    OUTPUT:
       RETVAL
       pattern

void
ajPatlistRegexRewind (thys)
       AjPPatlistRegex thys

void
ajPatlistSeqRewind (thys)
       AjPPatlistSeq thys

void
ajPatlistRegexRemoveCurrent (thys)
       AjPPatlistRegex thys

void
ajPatlistSeqRemoveCurrent (thys)
       AjPPatlistSeq thys

void
ajPatlistAddSeq (thys, pat)
       AjPPatlistSeq thys
       AjPPatternSeq pat

void
ajPatlistAddRegex (thys, pat)
       AjPPatlistRegex thys
       AjPPatternRegex pat

ajuint
ajPatternRegexType (type)
       const AjPStr type
    OUTPUT:
       RETVAL

ajuint
ajPatlistRegexDoc (plist, pdoc)
       AjPPatlistRegex plist
       AjPStr& pdoc
    OUTPUT:
       RETVAL
       pdoc

ajuint
ajPatlistSeqDoc (plist, pdoc)
       AjPPatlistSeq plist
       AjPStr& pdoc
    OUTPUT:
       RETVAL
       pdoc

AjBool
ajPatternSeqGetProtein (thys)
       const AjPPatternSeq thys
    OUTPUT:
       RETVAL

AjPPatlistRegex
ajPatlistRegexNewType (type)
       ajuint type
    OUTPUT:
       RETVAL

AjPPatComp
ajPatCompNew ()
    OUTPUT:
       RETVAL

void
ajPatCompDel (pthys)
       AjPPatComp& pthys
    OUTPUT:
       pthys

