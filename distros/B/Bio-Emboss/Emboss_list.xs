#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_list		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajlist.c: automatically generated

AjPList
ajListNew ()
    OUTPUT:
       RETVAL

AjPList
ajListstrNew ()
    OUTPUT:
       RETVAL

void
ajListPush (list, x)
       AjPList list
       char* x
    OUTPUT:
       x

void
ajListstrPush (list, x)
       AjPList list
       AjPStr x

void
ajListTrace (list)
       const AjPList list

void
ajListstrTrace (list)
       const AjPList list

AjBool
ajListPop (list, x)
       AjPList list
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListPeek (list, x)
       const AjPList list
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListstrPop (list, Pstr)
       AjPList list
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajListstrPeek (list, Pstr)
       const AjPList list
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

void
ajListReverse (list)
       AjPList list

void
ajListstrReverse (list)
       AjPList list

void
ajListFree (Plist)
       AjPList& Plist
    OUTPUT:
       Plist

void
ajListstrFree (Plist)
       AjPList& Plist
    OUTPUT:
       Plist

AjBool
ajListIterDone (iter)
       const AjIList iter
    OUTPUT:
       RETVAL

void
ajListIterTrace (iter)
       const AjIList iter

void
ajListstrIterTrace (iter)
       const AjIList iter

void
ajListExit ()

void
ajListFreeData (Plist)
       AjPList& Plist
    OUTPUT:
       Plist

AjPList
ajListNewListref (list)
       const AjPList list
    OUTPUT:
       RETVAL

void
ajListPushAppend (list, x)
       AjPList list
       char* x
    OUTPUT:
       x

void
ajListPushlist (list, Plist)
       AjPList list
       AjPList& Plist
    OUTPUT:
       Plist

AjBool
ajListPopLast (list, x)
       AjPList list
       void*& x
    OUTPUT:
       RETVAL
       x

ajuint
ajListGetLength (list)
       const AjPList list
    OUTPUT:
       RETVAL

AjBool
ajListPeekFirst (list, x)
       const AjPList list
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListPeekLast (list, x)
       const AjPList list
       void*& x
    OUTPUT:
       RETVAL
       x

AjBool
ajListPeekNumber (list, ipos, x)
       const AjPList list
       ajuint ipos
       void*& x
    OUTPUT:
       RETVAL
       x

ajuint
ajListToarray (list, array)
       const AjPList list
       void**& array
    OUTPUT:
       RETVAL
       array

void
ajListUnused (array)
       void** array

AjIList
ajListIterNew (list)
       AjPList list
    OUTPUT:
       RETVAL

AjIList
ajListIterNewBack (list)
       AjPList list
    OUTPUT:
       RETVAL

AjIList
ajListIterNewread (list)
       const AjPList list
    OUTPUT:
       RETVAL

AjIList
ajListIterNewreadBack (list)
       const AjPList list
    OUTPUT:
       RETVAL

AjBool
ajListIterDoneBack (iter)
       const AjIList iter
    OUTPUT:
       RETVAL

void
ajListIterDel (iter)
       AjIList& iter
    OUTPUT:
       iter

void*
ajListIterGet (iter)
       AjIList iter
    OUTPUT:
       RETVAL

void*
ajListIterGetBack (iter)
       AjIList iter
    OUTPUT:
       RETVAL

void
ajListIterInsert (iter, x)
       AjIList iter
       char* x
    OUTPUT:
       x

void
ajListIterRemove (iter)
       AjIList iter

AjPList
ajListstrNewList (list)
       const AjPList list
    OUTPUT:
       RETVAL

AjPList
ajListstrNewListref (list)
       const AjPList list
    OUTPUT:
       RETVAL

void
ajListstrPushAppend (list, x)
       AjPList list
       AjPStr x

void
ajListstrPushlist (list, Plist)
       AjPList list
       AjPList& Plist
    OUTPUT:
       Plist

AjBool
ajListstrPopLast (list, Pstr)
       AjPList list
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

ajuint
ajListstrGetLength (list)
       const AjPList list
    OUTPUT:
       RETVAL

ajuint
ajListstrToarray (list, array)
       const AjPList list
       AjPStr*& array
    OUTPUT:
       RETVAL
       array

ajuint
ajListstrToarrayAppend (list, array)
       const AjPList list
       AjPStr*& array
    OUTPUT:
       RETVAL
       array

void
ajListstrFreeData (Plist)
       AjPList& Plist
    OUTPUT:
       Plist

void
ajListstrIterInsert (iter, str)
       AjIList iter
       AjPStr str

void
ajListstrIterRemove (iter)
       AjIList iter

