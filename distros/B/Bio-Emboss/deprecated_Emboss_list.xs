#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_list_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajlist.c: automatically generated

AjPList
ajListNewArgs (x)
       char& x
    OUTPUT:
       RETVAL

AjPList
ajListstrNewArgs (x)
       AjPStr x
    OUTPUT:
       RETVAL

AjPListNode
ajListNodesNew (x)
       char& x
    OUTPUT:
       RETVAL

void
ajListAppend (thys, morenodes)
       AjPList thys
       AjPListNode& morenodes
    OUTPUT:
       morenodes

void
ajListPushApp (thys, x)
       AjPList thys
       char& x

void
ajListstrPushApp (thys, x)
       AjPList thys
       AjPStr x

AjPList
ajListstrCopy (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

AjPList
ajListCopy (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

ajuint
ajListstrClone (thys, newlist)
       const AjPList thys
       AjPList newlist
    OUTPUT:
       RETVAL

AjBool
ajListFirst (thys, x)
       const AjPList thys
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListLast (thys, x)
       const AjPList thys
       void*& x
    OUTPUT:
       RETVAL
       x

ajuint
ajListLength (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

ajuint
ajListstrLength (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

void
ajListDel (pthis)
       AjPList& pthis
    OUTPUT:
       pthis

void
ajListstrDel (pthis)
       AjPList& pthis
    OUTPUT:
       pthis

ajuint
ajListToArray (thys, array)
       const AjPList thys
       void**& array
    OUTPUT:
       RETVAL
       array

ajuint
ajListstrToArray (thys, array)
       const AjPList thys
       AjPStr*& array
    OUTPUT:
       RETVAL
       array

ajuint
ajListstrToArrayApp (thys, array)
       const AjPList thys
       AjPStr*& array
    OUTPUT:
       RETVAL
       array

AjIList
ajListIter (thys)
       AjPList thys
    OUTPUT:
       RETVAL

AjIList
ajListIterRead (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

AjIList
ajListIterBack (thys)
       AjPList thys
    OUTPUT:
       RETVAL

AjIList
ajListIterBackRead (thys)
       const AjPList thys
    OUTPUT:
       RETVAL

AjBool
ajListIterBackDone (iter)
       const AjIList iter
    OUTPUT:
       RETVAL

void
ajListIterFree (iter)
       AjIList& iter
    OUTPUT:
       iter

AjBool
ajListIterMore (iter)
       const AjIList iter
    OUTPUT:
       RETVAL

AjBool
ajListIterBackMore (iter)
       const AjIList iter
    OUTPUT:
       RETVAL

void*
ajListIterNext (iter)
       AjIList iter
    OUTPUT:
       RETVAL

void*
ajListIterBackNext (iter)
       AjIList iter
    OUTPUT:
       RETVAL

void
ajListRemove (iter)
       AjIList iter

void
ajListstrRemove (iter)
       AjIList iter

void
ajListInsert (iter, x)
       AjIList iter
       char& x

void
ajListstrInsert (iter, x)
       AjIList iter
       AjPStr x

void
ajListPushList (thys, pmore)
       AjPList thys
       AjPList& pmore
    OUTPUT:
       pmore

void
ajListstrPushList (thys, pmore)
       AjPList thys
       AjPList& pmore
    OUTPUT:
       pmore

AjBool
ajListPopEnd (thys, x)
       AjPList thys
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListstrPopEnd (thys, x)
       AjPList thys
       AjPStr& x
    OUTPUT:
       RETVAL
       x

