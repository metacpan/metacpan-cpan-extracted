#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_table		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajtable.c: automatically generated

void
ajTableTrace (table)
       const AjPTable table

void*
ajTablePut (table, key, value)
       AjPTable table
       char* key
       char* value
    OUTPUT:
       RETVAL
       value

void*
ajTableRemove (table, key)
       AjPTable table
       const char* key
    OUTPUT:
       RETVAL

ajuint
ajTableToarray (table, keyarray, valarray)
       const AjPTable table
       void**& keyarray
       void**& valarray
    OUTPUT:
       RETVAL
       keyarray
       valarray

void
ajTableFree (Ptable)
       AjPTable& Ptable
    OUTPUT:
       Ptable

void
ajTableExit ()

AjPTable
ajTableNewLen (size)
       ajuint size
    OUTPUT:
       RETVAL

void*
ajTableFetch (table, key)
       const AjPTable table
       const char* key
    OUTPUT:
       RETVAL

const void*
ajTableFetchKey (table, key)
       const AjPTable table
       const char* key
    OUTPUT:
       RETVAL

ajuint
ajTableGetLength (table)
       const AjPTable table
    OUTPUT:
       RETVAL

void*
ajTableRemoveKey (table, key, truekey)
       AjPTable table
       const char* key
       void*& truekey
    OUTPUT:
       RETVAL
       truekey

AjPTable
ajTablestrNew ()
    OUTPUT:
       RETVAL

AjPTable
ajTablestrNewCase ()
    OUTPUT:
       RETVAL

AjPTable
ajTablestrNewCaseLen (size)
       ajuint size
    OUTPUT:
       RETVAL

AjPTable
ajTablestrNewLen (size)
       ajuint size
    OUTPUT:
       RETVAL

ajint
ajTablestrCmp (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajint
ajTablestrCmpCase (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajuint
ajTablestrHash (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajuint
ajTablestrHashCase (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

void
ajTablestrPrint (table)
       const AjPTable table

void
ajTablestrTrace (table)
       const AjPTable table

void
ajTablestrFree (Ptable)
       AjPTable& Ptable
    OUTPUT:
       Ptable

void
ajTablestrFreeKey (Ptable)
       AjPTable& Ptable
    OUTPUT:
       Ptable

AjPTable
ajTablecharNew ()
    OUTPUT:
       RETVAL

AjPTable
ajTablecharNewCase ()
    OUTPUT:
       RETVAL

AjPTable
ajTablecharNewCaseLen (size)
       ajuint size
    OUTPUT:
       RETVAL

AjPTable
ajTablecharNewLen (size)
       ajuint size
    OUTPUT:
       RETVAL

ajint
ajTablecharCmp (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajint
ajTablecharCmpCase (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajuint
ajTablecharHash (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajuint
ajTablecharHashCase (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

void
ajTablecharPrint (table)
       const AjPTable table

