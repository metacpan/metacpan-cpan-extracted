#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_fmt		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajfmt.c: automatically generated

void
ajFmtPrint (fmt)
       const char* fmt

void
ajFmtError (fmt)
       const char* fmt

void
ajFmtPrintF (file, fmt)
       AjPFile file
       const char* fmt

void
ajFmtPrintFp (stream, fmt)
       FILE* stream
       const char* fmt

ajint
ajFmtPrintCL (buf, size, fmt)
       char& buf
       ajint size
       const char* fmt
    OUTPUT:
       RETVAL
       buf

AjPStr
ajFmtStr (fmt)
       const char* fmt
    OUTPUT:
       RETVAL

AjPStr
ajFmtPrintS (pthis, fmt)
       AjPStr& pthis
       const char* fmt
    OUTPUT:
       RETVAL
       pthis

AjPStr
ajFmtPrintAppS (pthis, fmt)
       AjPStr& pthis
       const char* fmt
    OUTPUT:
       RETVAL
       pthis

char*
ajFmtString (fmt)
       const char* fmt
    OUTPUT:
       RETVAL

void
ajFmtPrintSplit (outf, str, prefix, len, delim)
       AjPFile outf
       const AjPStr str
       const char * prefix
       ajint len
       const char * delim

ajint
ajFmtScanS (thys, fmt)
       const AjPStr thys
       const char* fmt
    OUTPUT:
       RETVAL

ajint
ajFmtScanC (thys, fmt)
       const char* thys
       const char* fmt
    OUTPUT:
       RETVAL

ajint
ajFmtScanF (thys, fmt)
       AjPFile thys
       const char* fmt
    OUTPUT:
       RETVAL

