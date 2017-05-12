#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_feat		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajfeat.c: automatically generated

AjBool
ajFeattabOutOpen (thys, ufo)
       AjPFeattabOut thys
       const AjPStr ufo
    OUTPUT:
       RETVAL

AjPFile
ajFeattabOutFile (thys)
       const AjPFeattabOut thys
    OUTPUT:
       RETVAL

AjPStr
ajFeattabOutFilename (thys)
       const AjPFeattabOut thys
    OUTPUT:
       RETVAL

AjBool
ajFeattabOutIsOpen (thys)
       const AjPFeattabOut thys
    OUTPUT:
       RETVAL

AjBool
ajFeattabOutIsLocal (thys)
       const AjPFeattabOut thys
    OUTPUT:
       RETVAL

AjBool
ajFeattabOutSet (thys, ufo)
       AjPFeattabOut thys
       const AjPStr ufo
    OUTPUT:
       RETVAL

AjPFeattabIn
ajFeattabInNew ()
    OUTPUT:
       RETVAL

AjPFeattabIn
ajFeattabInNewSS (fmt, name, type)
       const AjPStr fmt
       const AjPStr name
       const char* type
    OUTPUT:
       RETVAL

AjPFeattabIn
ajFeattabInNewSSF (fmt, name, type, buff)
       const AjPStr fmt
       const AjPStr name
       const char* type
       AjPFileBuff buff
    OUTPUT:
       RETVAL

AjPFeattabOut
ajFeattabOutNew ()
    OUTPUT:
       RETVAL

void
ajFeattabOutSetBasename (thys, basename)
       AjPFeattabOut thys
       const AjPStr basename

AjPFeattabOut
ajFeattabOutNewSSF (fmt, name, type, file)
       const AjPStr fmt
       const AjPStr name
       const char* type
       AjPFile file
    OUTPUT:
       RETVAL

AjPFeattable
ajFeatRead (ftin)
       AjPFeattabIn ftin
    OUTPUT:
       RETVAL

AjPFeature
ajFeatNew (thys, source, type, Start, End, score, strand, frame)
       AjPFeattable thys
       const AjPStr source
       const AjPStr type
       ajint Start
       ajint End
       float score
       char strand
       ajint frame
    OUTPUT:
       RETVAL

AjPFeature
ajFeatNewII (thys, Start, End)
       AjPFeattable thys
       ajint Start
       ajint End
    OUTPUT:
       RETVAL

AjPFeature
ajFeatNewIIRev (thys, Start, End)
       AjPFeattable thys
       ajint Start
       ajint End
    OUTPUT:
       RETVAL

AjPFeature
ajFeatNewProt (thys, source, type, Start, End, score)
       AjPFeattable thys
       const AjPStr source
       const AjPStr type
       ajint Start
       ajint End
       float score
    OUTPUT:
       RETVAL

void
ajFeattabInDel (pthis)
       AjPFeattabIn& pthis
    OUTPUT:
       pthis

void
ajFeattableDel (pthis)
       AjPFeattable& pthis
    OUTPUT:
       pthis

void
ajFeatDel (pthis)
       AjPFeature& pthis
    OUTPUT:
       pthis

AjBool
ajFeatUfoWrite (thys, featout, ufo)
       const AjPFeattable thys
       AjPFeattabOut featout
       const AjPStr ufo
    OUTPUT:
       RETVAL

AjBool
ajFeattableWrite (thys, ufo)
       AjPFeattable thys
       const AjPStr ufo
    OUTPUT:
       RETVAL
       thys

void
ajFeatSortByType (Feattab)
       AjPFeattable Feattab

void
ajFeatSortByStart (Feattab)
       AjPFeattable Feattab

void
ajFeatSortByEnd (Feattab)
       AjPFeattable Feattab

void
ajFeattableAdd (thys, feature)
       AjPFeattable thys
       AjPFeature feature

void
ajFeattableClear (thys)
       AjPFeattable thys

AjBool
ajFeatOutFormatDefault (pformat)
       AjPStr& pformat
    OUTPUT:
       RETVAL
       pformat

AjBool
ajFeatWrite (ftout, features)
       AjPFeattabOut ftout
       const AjPFeattable features
    OUTPUT:
       RETVAL

AjBool
ajFeattableWriteGff (Feattab, file)
       const AjPFeattable Feattab
       AjPFile file
    OUTPUT:
       RETVAL

AjBool
ajFeattableWriteDdbj (thys, file)
       const AjPFeattable thys
       AjPFile file
    OUTPUT:
       RETVAL

AjBool
ajFeattableWriteEmbl (thys, file)
       const AjPFeattable thys
       AjPFile file
    OUTPUT:
       RETVAL

AjBool
ajFeattableWriteGenbank (thys, file)
       const AjPFeattable thys
       AjPFile file
    OUTPUT:
       RETVAL

AjBool
ajFeattableWriteSwiss (thys, file)
       const AjPFeattable thys
       AjPFile file
    OUTPUT:
       RETVAL

AjBool
ajFeattableWritePir (thys, file)
       const AjPFeattable thys
       AjPFile file
    OUTPUT:
       RETVAL

const AjPStr
ajFeattableGetName (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

const char*
ajFeattableGetTypeC (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

const AjPStr
ajFeattableGetTypeS (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

AjBool
ajFeattableIsNuc (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

AjBool
ajFeattableIsProt (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

ajint
ajFeattableBegin (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

ajint
ajFeattableEnd (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

ajint
ajFeattableLen (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

ajint
ajFeattableSize (thys)
       const AjPFeattable thys
    OUTPUT:
       RETVAL

void
ajFeattabInClear (thys)
       AjPFeattabIn thys

AjBool
ajFeatLocToSeq (seq, line, res, usa)
       const AjPStr seq
       const AjPStr line
       AjPStr& res
       const AjPStr usa
    OUTPUT:
       RETVAL
       res

ajuint
ajFeatGetLocs (str, cds, type)
       const AjPStr str
       AjPStr*& cds
       const char* type
    OUTPUT:
       RETVAL
       cds

AjBool
ajFeatGetNote (thys, name, val)
       const AjPFeature thys
       const AjPStr name
       AjPStr& val
    OUTPUT:
       RETVAL
       val

AjBool
ajFeatGetNoteC (thys, name, val)
       const AjPFeature thys
       const char* name
       AjPStr& val
    OUTPUT:
       RETVAL
       val

AjBool
ajFeatGetNoteCI (thys, name, count, val)
       const AjPFeature thys
       const char* name
       ajint count
       AjPStr& val
    OUTPUT:
       RETVAL
       val

AjBool
ajFeatGetNoteI (thys, name, count, val)
       const AjPFeature thys
       const AjPStr name
       ajint count
       AjPStr& val
    OUTPUT:
       RETVAL
       val

AjBool
ajFeatGetTag (thys, name, num, val)
       const AjPFeature thys
       const AjPStr name
       ajint num
       AjPStr& val
    OUTPUT:
       RETVAL
       val

const AjPStr
ajFeatGetType (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

const AjPStr
ajFeatGetSource (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

ajuint
ajFeatGetStart (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

char
ajFeatGetStrand (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

ajuint
ajFeatGetEnd (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

ajuint
ajFeatGetLength (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

float
ajFeatGetScore (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

AjBool
ajFeatGetForward (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

ajint
ajFeatGetFrame (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

ajuint
ajFeatGetTrans (str, cds)
       const AjPStr str
       AjPStr*& cds
    OUTPUT:
       RETVAL
       cds

void
ajFeatTest ()

void
ajFeatSetDescApp (thys, desc)
       AjPFeature thys
       const AjPStr desc

void
ajFeatSetDesc (thys, desc)
       AjPFeature thys
       const AjPStr desc

void
ajFeatSetScore (thys, score)
       AjPFeature thys
       float score

void
ajFeatSetStrand (thys, rev)
       AjPFeature thys
       AjBool rev

AjBool
ajFeattabInSetType (thys, type)
       AjPFeattabIn thys
       const AjPStr type
    OUTPUT:
       RETVAL

AjBool
ajFeattabInSetTypeC (thys, type)
       AjPFeattabIn thys
       const char* type
    OUTPUT:
       RETVAL

AjBool
ajFeattabOutSetType (thys, type)
       AjPFeattabOut thys
       const AjPStr type
    OUTPUT:
       RETVAL

AjBool
ajFeattabOutSetTypeC (thys, type)
       AjPFeattabOut thys
       const char* type
    OUTPUT:
       RETVAL

AjBool
ajFeatTagSetC (thys, tag, value)
       AjPFeature thys
       const char* tag
       const AjPStr value
    OUTPUT:
       RETVAL

AjBool
ajFeatTagSet (thys, tag, value)
       AjPFeature thys
       const AjPStr tag
       const AjPStr value
    OUTPUT:
       RETVAL

AjBool
ajFeatTagAddCC (thys, tag, value)
       AjPFeature thys
       const char* tag
       const char* value
    OUTPUT:
       RETVAL

AjBool
ajFeatTagAddC (thys, tag, value)
       AjPFeature thys
       const char* tag
       const AjPStr value
    OUTPUT:
       RETVAL

AjBool
ajFeatTagAdd (thys, tag, value)
       AjPFeature thys
       const AjPStr tag
       const AjPStr value
    OUTPUT:
       RETVAL

AjPFeattable
ajFeattableNew (name)
       const AjPStr name
    OUTPUT:
       RETVAL

AjPFeattable
ajFeatUfoRead (featin, ufo)
       AjPFeattabIn featin
       const AjPStr ufo
    OUTPUT:
       RETVAL

void
ajFeattableSetNuc (thys)
       AjPFeattable thys

void
ajFeattableSetProt (thys)
       AjPFeattable thys

void
ajFeattableReverse (thys)
       AjPFeattable thys

void
ajFeatReverse (thys, ilen)
       AjPFeature thys
       ajint ilen

void
ajFeattableSetRange (thys, fbegin, fend)
       AjPFeattable thys
       ajint fbegin
       ajint fend

AjPFeattable
ajFeattableNewDna (name)
       const AjPStr name
    OUTPUT:
       RETVAL

AjPFeattable
ajFeattableNewSeq (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjPFeattable
ajFeattableNewProt (name)
       const AjPStr name
    OUTPUT:
       RETVAL

AjPFeattable
ajFeattableCopy (orig)
       const AjPFeattable orig
    OUTPUT:
       RETVAL

AjPFeature
ajFeatCopy (orig)
       const AjPFeature orig
    OUTPUT:
       RETVAL

void
ajFeatTrace (thys)
       const AjPFeature thys

void
ajFeatTagTrace (thys)
       const AjPFeature thys

AjIList
ajFeatTagIter (thys)
       const AjPFeature thys
    OUTPUT:
       RETVAL

AjBool
ajFeatTagval (iter, tagnam, tagval)
       AjIList iter
       AjPStr& tagnam
       AjPStr& tagval
    OUTPUT:
       RETVAL
       tagnam
       tagval

void
ajFeattableTrace (thys)
       const AjPFeattable thys

void
ajFeatExit ()

void
ajFeatUnused ()

AjBool
ajFeatIsLocal (gf)
       const AjPFeature gf
    OUTPUT:
       RETVAL

AjBool
ajFeatIsLocalRange (gf, start, end)
       const AjPFeature gf
       ajuint start
       ajuint end
    OUTPUT:
       RETVAL

AjBool
ajFeatIsChild (gf)
       const AjPFeature gf
    OUTPUT:
       RETVAL

AjBool
ajFeatIsMultiple (gf)
       const AjPFeature gf
    OUTPUT:
       RETVAL

AjBool
ajFeatIsCompMult (gf)
       const AjPFeature gf
    OUTPUT:
       RETVAL

void
ajFeattabOutDel (thys)
       AjPFeattabOut & thys
    OUTPUT:
       thys

ajuint
ajFeattablePos (thys, ipos)
       const AjPFeattable thys
       ajint ipos
    OUTPUT:
       RETVAL

ajuint
ajFeattablePosI (thys, imin, ipos)
       const AjPFeattable thys
       ajuint imin
       ajint ipos
    OUTPUT:
       RETVAL

ajuint
ajFeattablePosII (ilen, imin, ipos)
       ajuint ilen
       ajuint imin
       ajint ipos
    OUTPUT:
       RETVAL

AjBool
ajFeattableTrimOff (thys, ioffset, ilen)
       AjPFeattable thys
       ajuint ioffset
       ajuint ilen
    OUTPUT:
       RETVAL

AjBool
ajFeatTrimOffRange (ft, ioffset, begin, end, dobegin, doend)
       AjPFeature ft
       ajuint ioffset
       ajuint begin
       ajuint end
       AjBool dobegin
       AjBool doend
    OUTPUT:
       RETVAL

void
ajFeatDefName (thys, setname)
       AjPFeattable thys
       const AjPStr setname
    OUTPUT:
       thys

void
ajFeatPrintFormat (outf, full)
       AjPFile outf
       AjBool full

AjBool
ajFeatLocMark (seq, line)
       AjPStr& seq
       const AjPStr line
    OUTPUT:
       RETVAL
       seq

AjPFeattable
ajFeattableCopyLimit (orig, limit)
       const AjPFeattable orig
       ajint limit
    OUTPUT:
       RETVAL

void
ajFeattabOutClear (thys)
       AjPFeattabOut & thys
    OUTPUT:
       thys

