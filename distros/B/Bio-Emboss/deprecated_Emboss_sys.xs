#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_sys_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajsys.c: automatically generated

void
ajSysBasename (s)
       AjPStr& s

char
ajSysItoC (v)
       ajint v
    OUTPUT:
       RETVAL

unsigned char
ajSysItoUC (v)
       ajint v
    OUTPUT:
       RETVAL

AjBool
ajSysWhich (s)
       AjPStr& s
    OUTPUT:
       RETVAL

void
ajSystem (cl)
       const AjPStr cl

AjBool
ajSysUnlink (s)
       const AjPStr s
    OUTPUT:
       RETVAL

AjBool
ajSysArglist (cmdline, pgm, arglist)
       const AjPStr cmdline
       char*& pgm
       char**& arglist
    OUTPUT:
       RETVAL
       pgm
       arglist

void
ajSysArgListFree (arglist)
       char**& arglist
    OUTPUT:
       arglist

FILE*
ajSysFdopen (filedes, mode)
       ajint filedes
       const char * mode
    OUTPUT:
       RETVAL

char*
ajSysStrdup (s)
       const char * s
    OUTPUT:
       RETVAL

AjBool
ajSysIsRegular (s)
       const char * s
    OUTPUT:
       RETVAL

AjBool
ajSysIsDirectory (s)
       const char * s
    OUTPUT:
       RETVAL

char*
ajSysStrtok (s, t)
       const char * s
       const char * t
    OUTPUT:
       RETVAL

char*
ajSysStrtokR (s, t, ptrptr, buf)
       char & s
       const char * t
       const char *& ptrptr
       AjPStr & buf
    OUTPUT:
       RETVAL
       ptrptr
       buf

char*
ajSysFgets (buf, size, fp)
       char & buf
       int size
       FILE * fp
    OUTPUT:
       RETVAL
       buf

FILE*
ajSysFopen (name, flags)
       const char * name
       const char* flags
    OUTPUT:
       RETVAL

