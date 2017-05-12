#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_mess		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajmess.c: automatically generated

void
ajMessInvokeDebugger ()

void
ajMessBeep ()

void
ajUser (format)
       const char* format

void
ajMessOut (format)
       const char* format

void
ajMessDump (format)
       const char* format

ajint
ajMessErrorCount ()
    OUTPUT:
       RETVAL

void
ajErr (format)
       const char* format

void
ajDie (format)
       const char* format

void
ajWarn (format)
       const char* format

void
ajMessExitmsg (format)
       const char* format

void
ajMessCrashFL (format)
       const char* format

char*
ajMessCaughtMessage ()
    OUTPUT:
       RETVAL

char*
ajMessSysErrorText ()
    OUTPUT:
       RETVAL

void
ajMessErrorInit (progname)
       const char* progname

void
ajMessSetErr (filename, line_num)
       const char* filename
       ajint line_num

AjBool
ajMessErrorSetFile (errfile)
       const char* errfile
    OUTPUT:
       RETVAL

void
ajMessOutCode (code)
       const char* code

void
ajMessErrorCode (code)
       const char* code

void
ajMessCrashCodeFL (code)
       const char* code

void
ajMessCodesDelete ()

void
ajDebug (fmt)
       const char* fmt

FILE*
ajDebugFile ()
    OUTPUT:
       RETVAL

ajint
ajUserGet (pthis, fmt)
       AjPStr& pthis
       const char* fmt
    OUTPUT:
       RETVAL
       pthis

void
ajMessExit ()

