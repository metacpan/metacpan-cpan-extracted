#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_tree		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajtree.c: automatically generated

AjPTree
ajTreeNew ()
    OUTPUT:
       RETVAL

AjPTree
ajTreestrNew ()
    OUTPUT:
       RETVAL

AjPTree
ajTreestrCopy (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

AjPTree
ajTreeCopy (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

ajuint
ajTreeLength (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

ajuint
ajTreestrLength (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

void
ajTreeFree (pthis)
       AjPTree& pthis
    OUTPUT:
       pthis

void
ajTreestrFree (pthis)
       AjPTree& pthis
    OUTPUT:
       pthis

void
ajTreeDel (pthis)
       AjPTree& pthis
    OUTPUT:
       pthis

void
ajTreestrDel (pthis)
       AjPTree& pthis
    OUTPUT:
       pthis

ajuint
ajTreeToArray (thys, array)
       const AjPTree thys
       void**& array
    OUTPUT:
       RETVAL
       array

ajuint
ajTreestrToArray (thys, array)
       const AjPTree thys
       AjPStr*& array
    OUTPUT:
       RETVAL
       array

void
ajTreeDummyFunction ()

AjBool
ajTreeAddData (thys, data)
       AjPTree thys
       char* data
    OUTPUT:
       RETVAL

AjPTree
ajTreeAddNode (thys)
       AjPTree thys
    OUTPUT:
       RETVAL

AjPTree
ajTreeAddSubNode (thys)
       AjPTree thys
    OUTPUT:
       RETVAL

void
ajTreeTrace (thys)
       const AjPTree thys

void
ajTreeExit ()

AjBool
ajTreestrAddData (thys, data)
       AjPTree thys
       AjPStr data
    OUTPUT:
       RETVAL

void
ajTreestrTrace (thys)
       const AjPTree thys

AjPTree
ajTreeFollow (thys, parent)
       const AjPTree thys
       const AjPTree parent
    OUTPUT:
       RETVAL

AjPTree
ajTreeNext (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

AjPTree
ajTreePrev (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

AjPTree
ajTreeDown (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

AjPTree
ajTreeUp (thys)
       const AjPTree thys
    OUTPUT:
       RETVAL

