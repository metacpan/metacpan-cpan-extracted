#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_table_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajtable.c: automatically generated

void*
ajTableGet (table, key)
       const AjPTable table
       const char* key
    OUTPUT:
       RETVAL

const void*
ajTableKey (table, key)
       const AjPTable table
       const char* key
    OUTPUT:
       RETVAL

void
ajStrTableTrace (table)
       const AjPTable table

ajint
ajTableLength (table)
       const AjPTable table
    OUTPUT:
       RETVAL

AjPTable
ajStrTableNewCaseC (hint)
       ajint hint
    OUTPUT:
       RETVAL

AjPTable
ajStrTableNewCase (hint)
       ajint hint
    OUTPUT:
       RETVAL

AjPTable
ajStrTableNewC (hint)
       ajint hint
    OUTPUT:
       RETVAL

AjPTable
ajStrTableNew (hint)
       ajint hint
    OUTPUT:
       RETVAL

ajuint
ajStrTableHashCaseC (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajuint
ajStrTableHashCase (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajuint
ajStrTableHashC (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajuint
ajStrTableHash (key, hashsize)
       const char* key
       ajuint hashsize
    OUTPUT:
       RETVAL

ajint
ajStrTableCmpCaseC (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajint
ajStrTableCmpCase (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajint
ajStrTableCmpC (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

ajint
ajStrTableCmp (x, y)
       const char* x
       const char* y
    OUTPUT:
       RETVAL

void
ajStrTablePrint (table)
       const AjPTable table

void
ajStrTablePrintC (table)
       const AjPTable table

void
ajStrTableFree (ptable)
       AjPTable& ptable
    OUTPUT:
       ptable

