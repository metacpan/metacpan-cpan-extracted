#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_mem		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajmem.c: automatically generated

void*
ajMemAlloc (nbytes, file, line, nofail)
       size_t nbytes
       const char* file
       ajint line
       AjBool nofail
    OUTPUT:
       RETVAL

void*
ajMemCalloc (count, nbytes, file, line, nofail)
       size_t count
       size_t nbytes
       const char* file
       ajint line
       AjBool nofail
    OUTPUT:
       RETVAL

void*
ajMemCalloc0 (count, nbytes, file, line, nofail)
       size_t count
       size_t nbytes
       const char* file
       ajint line
       AjBool nofail
    OUTPUT:
       RETVAL

void
ajMemFree (ptr)
       void* ptr
    OUTPUT:
       ptr

void*
ajMemResize (ptr, nbytes, file, line, nofail)
       void* ptr
       size_t nbytes
       const char* file
       ajint line
       AjBool nofail
    OUTPUT:
       RETVAL
       ptr

ajint*
ajMemArrB (size)
       size_t size
    OUTPUT:
       RETVAL

ajint*
ajMemArrI (size)
       size_t size
    OUTPUT:
       RETVAL

float*
ajMemArrF (size)
       size_t size
    OUTPUT:
       RETVAL

void
ajMemStat (title)
       const char* title

void
ajMemExit ()

