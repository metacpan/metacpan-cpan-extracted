#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_report		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajreport.c: automatically generated

void
ajReportDel (pthys)
       AjPReport& pthys
    OUTPUT:
       pthys

AjBool
ajReportOpen (thys, name)
       AjPReport thys
       const AjPStr name
    OUTPUT:
       RETVAL

AjBool
ajReportFormatDefault (pformat)
       AjPStr& pformat
    OUTPUT:
       RETVAL
       pformat

AjBool
ajReportFindFormat (format, iformat)
       const AjPStr format
       ajint& iformat
    OUTPUT:
       RETVAL
       iformat

AjBool
ajReportSetTags (thys, taglist)
       AjPReport thys
       const AjPStr taglist
    OUTPUT:
       RETVAL

AjBool
ajReportValid (thys)
       AjPReport thys
    OUTPUT:
       RETVAL

AjPReport
ajReportNew ()
    OUTPUT:
       RETVAL

AjBool
ajReportWrite (thys, ftable, seq)
       AjPReport thys
       const AjPFeattable ftable
       const AjPSeq seq
    OUTPUT:
       RETVAL

void
ajReportClose (thys)
       AjPReport thys

ajint
ajReportLists (thys, types, names, prints, sizes)
       const AjPReport thys
       AjPStr*& types
       AjPStr*& names
       AjPStr*& prints
       ajuint*& sizes
    OUTPUT:
       RETVAL
       types
       names
       prints
       sizes

void
ajReportWriteHeader (thys, ftable, seq)
       AjPReport thys
       const AjPFeattable ftable
       const AjPSeq seq

void
ajReportWriteTail (thys, ftable, seq)
       AjPReport thys
       const AjPFeattable ftable
       const AjPSeq seq

void
ajReportSetHeader (thys, header)
       AjPReport thys
       const AjPStr header

void
ajReportSetHeaderC (thys, header)
       AjPReport thys
       const char* header

void
ajReportSetSubHeader (thys, header)
       AjPReport thys
       const AjPStr header

void
ajReportSetSubHeaderC (thys, header)
       AjPReport thys
       const char* header

void
ajReportSetTail (thys, tail)
       AjPReport thys
       const AjPStr tail

void
ajReportSetTailC (thys, tail)
       AjPReport thys
       const char* tail

void
ajReportSetSubTail (thys, tail)
       AjPReport thys
       const AjPStr tail

void
ajReportSetSubTailC (thys, tail)
       AjPReport thys
       const char* tail

void
ajReportSetType (thys, ftable, seq)
       AjPReport thys
       const AjPFeattable ftable
       const AjPSeq seq

const AjPStr
ajReportSeqName (thys, seq)
       const AjPReport thys
       const AjPSeq seq
    OUTPUT:
       RETVAL

void
ajReportFileAdd (thys, file, type)
       AjPReport thys
       AjPFile file
       const AjPStr type

void
ajReportPrintFormat (outf, full)
       AjPFile outf
       AjBool full

void
ajReportDummyFunction ()

void
ajReportExit ()

void
ajReportAppendHeader (thys, header)
       AjPReport thys
       const AjPStr header

void
ajReportAppendHeaderC (thys, header)
       AjPReport thys
       const char* header

void
ajReportAppendSubHeader (thys, header)
       AjPReport thys
       const AjPStr header

void
ajReportAppendSubHeaderC (thys, header)
       AjPReport thys
       const char* header

void
ajReportAppendTail (thys, tail)
       AjPReport thys
       const AjPStr tail

void
ajReportAppendTailC (thys, tail)
       AjPReport thys
       const char* tail

void
ajReportAppendSubTail (thys, tail)
       AjPReport thys
       const AjPStr tail

void
ajReportAppendSubTailC (thys, tail)
       AjPReport thys
       const char* tail

