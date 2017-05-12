#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_range		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajrange.c: automatically generated

AjPRange
ajRangeNewI (n)
       ajuint n
    OUTPUT:
       RETVAL

AjPRange
ajRangeCopy (src)
       const AjPRange src
    OUTPUT:
       RETVAL

void
ajRangeDel (thys)
       AjPRange & thys
    OUTPUT:
       thys

AjPRange
ajRangeGet (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjPRange
ajRangeGetLimits (str, imin, imax, minsize, size)
       const AjPStr str
       ajuint imin
       ajuint imax
       ajuint minsize
       ajuint size
    OUTPUT:
       RETVAL

AjPRange
ajRangeFile (name)
       const AjPStr name
    OUTPUT:
       RETVAL

AjPRange
ajRangeFileLimits (name, imin, imax, minsize, size)
       const AjPStr name
       ajuint imin
       ajuint imax
       ajuint minsize
       ajuint size
    OUTPUT:
       RETVAL

ajuint
ajRangeNumber (thys)
       const AjPRange thys
    OUTPUT:
       RETVAL

AjBool
ajRangeValues (thys, element, start, end)
       const AjPRange thys
       ajuint element
       ajuint & start
       ajuint & end
    OUTPUT:
       RETVAL
       start
       end

AjBool
ajRangeText (thys, element, text)
       const AjPRange thys
       ajuint element
       AjPStr & text
    OUTPUT:
       RETVAL
       text

AjBool
ajRangeChange (thys, element, start, end)
       AjPRange thys
       ajuint element
       ajuint start
       ajuint end
    OUTPUT:
       RETVAL
       thys

AjBool
ajRangeBegin (thys, begin)
       AjPRange thys
       ajuint begin
    OUTPUT:
       RETVAL

AjBool
ajRangeSeqExtractList (thys, seq, outliststr)
       const AjPRange thys
       const AjPSeq seq
       AjPList outliststr
    OUTPUT:
       RETVAL
       outliststr

AjBool
ajRangeSeqExtract (thys, seq)
       const AjPRange thys
       AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajRangeSeqStuff (thys, seq)
       const AjPRange thys
       AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajRangeSeqMask (thys, maskchar, seq)
       const AjPRange thys
       const AjPStr maskchar
       AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajRangeSeqToLower (thys, seq)
       const AjPRange thys
       AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajRangeStrExtractList (thys, instr, outliststr)
       const AjPRange thys
       const AjPStr instr
       AjPList outliststr
    OUTPUT:
       RETVAL
       outliststr

AjBool
ajRangeStrExtract (thys, instr, outstr)
       const AjPRange thys
       const AjPStr instr
       AjPStr & outstr
    OUTPUT:
       RETVAL
       outstr

AjBool
ajRangeStrStuff (thys, instr, outstr)
       const AjPRange thys
       const AjPStr instr
       AjPStr & outstr
    OUTPUT:
       RETVAL
       outstr

AjBool
ajRangeStrMask (thys, maskchar, str)
       const AjPRange thys
       const AjPStr maskchar
       AjPStr & str
    OUTPUT:
       RETVAL
       str

AjBool
ajRangeStrToLower (thys, str)
       const AjPRange thys
       AjPStr & str
    OUTPUT:
       RETVAL
       str

ajuint
ajRangeOverlapSingle (start, end, pos, length)
       ajuint start
       ajuint end
       ajuint pos
       ajuint length
    OUTPUT:
       RETVAL

ajuint
ajRangeOverlaps (thys, pos, length)
       const AjPRange thys
       ajuint pos
       ajuint length
    OUTPUT:
       RETVAL

AjBool
ajRangeOrdered (thys)
       const AjPRange thys
    OUTPUT:
       RETVAL

AjBool
ajRangeDefault (thys, s)
       const AjPRange thys
       const AjPSeq s
    OUTPUT:
       RETVAL

