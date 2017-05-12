#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_sys		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajsys.c: automatically generated

void
ajSysCanon (state)
       AjBool state

void
ajSysExit ()

AjBool
ajSysArglistBuild (cmdline, Pname, PParglist)
       const AjPStr cmdline
       char*& Pname
       char**& PParglist
    OUTPUT:
       RETVAL
       Pname
       PParglist

void
ajSysArglistFree (PParglist)
       char**& PParglist
    OUTPUT:
       PParglist

char
ajSysCastItoc (v)
       ajint v
    OUTPUT:
       RETVAL

unsigned char
ajSysCastItouc (v)
       ajint v
    OUTPUT:
       RETVAL

AjBool
ajSysFileUnlink (filename)
       const AjPStr filename
    OUTPUT:
       RETVAL

AjBool
ajSysFileWhich (Pfilename)
       AjPStr& Pfilename
    OUTPUT:
       RETVAL
       Pfilename

FILE*
ajSysFuncFdopen (filedes, mode)
       ajint filedes
       const char * mode
    OUTPUT:
       RETVAL

char*
ajSysFuncFgets (buf, size, fp)
       char& buf
       int size
       FILE* fp
    OUTPUT:
       RETVAL
       buf

FILE*
ajSysFuncFopen (name, flags)
       const char * name
       const char* flags
    OUTPUT:
       RETVAL

char*
ajSysFuncStrdup (dupstr)
       const char * dupstr
    OUTPUT:
       RETVAL

char*
ajSysFuncStrtok (srcstr, delimstr)
       const char * srcstr
       const char * delimstr
    OUTPUT:
       RETVAL

char*
ajSysFuncStrtokR (srcstr, delimstr, ptrptr, buf)
       const char & srcstr
       const char * delimstr
       const char *& ptrptr
       AjPStr & buf
    OUTPUT:
       RETVAL
       srcstr
       ptrptr
       buf

void
ajSysSystem (cmdline)
       const AjPStr cmdline

void
ajSysSystemOut (cmdline, outfname)
       const AjPStr cmdline
       const AjPStr outfname

