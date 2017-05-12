/*  File: memsubs.c
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description:
 * Exported functions:
 * HISTORY:
 * Last edited: Dec  4 11:24 1998 (fw)
 * Created: Thu Aug 20 16:54:55 1998 (rd)
 *-------------------------------------------------------------------
 */

/* define MALLOC_CHECK here to check mallocs - also in regular.h */

#include "regular.h"

#if defined(NEXT) || defined(HP) || defined(MACINTOSH) 
extern void* malloc(mysize_t size) ;
#elif !defined(WIN32) && !defined(DARWIN)
#include <malloc.h>   /* normal machines  */
#endif

/********** primary type definition **************/

typedef struct _STORE_HANDLE_STRUCT {
  STORE_HANDLE next ;	/* for chaining together on Handles */
  STORE_HANDLE back ;	/* to unchain */
  void (*final)(void*) ;	/* finalisation routine */
  int size ;			/* of user memory to follow */
#ifdef MALLOC_CHECK
  int check1 ;			/* set to known value */
#endif
} STORE_HANDLE_STRUCT ;

/*********************************************************************/
/********** memory allocation - messalloc() and handles  *************/

static int numMessAlloc = 0 ;
static int totMessAlloc = 0 ;


  /* Calculate to size of an STORE_HANDLE_STRUCT rounded to the nearest upward
     multiple of sizeof(double). This avoids alignment problems when
     we put an STORE_HANDLE_STRUCT at the start of a memory block */

#define STORE_OFFSET ((((sizeof(STORE_HANDLE_STRUCT)-1)/MALLOC_ALIGNMENT)+1)\
                             * MALLOC_ALIGNMENT)


  /* macros to convert between a void* and the corresponding STORE_HANDLE */

#define toAllocUnit(x) (STORE_HANDLE) ((char*)(x) - STORE_OFFSET)
#define toMemPtr(unit)((void*)((char*)(unit) + STORE_OFFSET))

#ifdef MALLOC_CHECK
BOOL handlesInitialised = FALSE;
static Array handles = 0 ;

  /* macro to give the terminal check int for an STORE_HANDLE_STRUCT */
  /* unit->size must be a multiple of sizeof(int) */
#define check2(unit)  *(int*)(((char*)toMemPtr(unit)) + (unit)->size)

static void checkUnit (STORE_HANDLE unit) ;
static int handleOrder (void *a, void  *b)
{ return (*((STORE_HANDLE *)a) == *((STORE_HANDLE *)b)) ? 0 : 
	  (*((STORE_HANDLE *)a) > *((STORE_HANDLE *)b)) ? 1 : -1 ;
}
#endif
#if defined(MALLOC_CHECK) || defined(MEM_DEBUG)
STORE_HANDLE_STRUCT handle0 ;
#endif

/************** halloc(): key function - messalloc() calls this ****************/

#ifdef MEM_DEBUG
void *halloc_dbg(int size, STORE_HANDLE handle,const char *hfname, int hlineno) 
#else
void *halloc(int size, STORE_HANDLE handle)
#endif
{ 
  STORE_HANDLE unit ;
  
#ifdef MALLOC_CHECK
  if (!handlesInitialised)		/* initialise */
    { handlesInitialised = TRUE;
      /* BEWARE, arrayCreate calls handleAlloc, line above must precede
         following line to avoid infinite recursion */
      handles = arrayCreate (16, STORE_HANDLE) ;
      array (handles, 0, STORE_HANDLE) = &handle0 ;
      handle0.next = 0 ;
    }

  while (size % INT_ALIGNMENT) size++ ; /* so check2 alignment is OK */
  unit = (STORE_HANDLE) malloc(STORE_OFFSET + size + sizeof(int)) ;
  if (unit) memset (unit, 0, STORE_OFFSET + size + sizeof(int)) ;
#else
  unit = (STORE_HANDLE) malloc(STORE_OFFSET + size) ;
  if (unit) memset (unit, 0, STORE_OFFSET + size) ;
#endif

  if (!unit)			/* out of memory -> messcrash */
    {
      messcrash (
 "Memory allocation failure when requesting %d bytes, %d already allocated", 
  size, totMessAlloc) ;
    }
#if defined(MALLOC_CHECK) || defined(MEM_DEBUG)
  if (!handle)
    handle = &handle0 ;
#endif
  if (handle) 
    { unit->next = handle->next ;
      unit->back = handle ;
      if (handle->next) (handle->next)->back = unit ;
      handle->next = unit ;
    }

  unit->size = size ;
#ifdef MALLOC_CHECK
  unit->check1 = 0x12345678 ;
  check2(unit) = 0x12345678 ;
#endif

  ++numMessAlloc ;
  totMessAlloc += size ;

  return toMemPtr(unit) ;
}

void blockSetFinalise(void *block, void (*final)(void *))
{ STORE_HANDLE unit = toAllocUnit(block);
  unit->final = final ;
}  

/***** handleAlloc() - does halloc() + blockSetFinalise() - archaic *****/

#ifdef MEM_DEBUG
void *handleAlloc_dbg (void (*final)(void*), STORE_HANDLE handle, int size,
		   const char *hfname, int hlineno)
{
  void *result = halloc_dbg(size, handle, hfname, hlineno) ;
#else
void *handleAlloc (void (*final)(void*), STORE_HANDLE handle, int size)
{
  void *result = halloc(size, handle);
#endif
  if (final) 
    blockSetFinalise(result, final);

  return result;
}

/****************** useful utility ************/

#ifdef MEM_DEBUG
char *strnew_dbg(char *old, STORE_HANDLE handle, const char *hfname, int hlineno)
{ char *result = 0 ;
  if (old)
    { result = (char *)halloc_dbg(1+strlen(old), handle, hfname, hlineno) ;
#else
char *strnew(char *old, STORE_HANDLE handle)
{ char *result = 0 ;
  if (old)
    { result = (char *)halloc(1+strlen(old), handle);
#endif
      strcpy(result, old);
    }
  return result;
}

/****************** messfree ***************/

void umessfree (void *cp)
{
  STORE_HANDLE unit = toAllocUnit(cp) ;

#ifdef MALLOC_CHECK
  checkUnit (unit) ;
  unit->check1 = 0x87654321; /* test for double free */
#endif

  if (unit->final)
    (*unit->final)(cp) ;

  if (unit->back) 
    { (unit->back)->next = unit->next;
      if (unit->next) (unit->next)->back = unit->back;
    }
  
  --numMessAlloc ;
  totMessAlloc -= unit->size ;
  free (unit) ;
}

/************** create and destroy handles **************/

/* NOTE: handleDestroy is #defined in regular.h to be messfree */
/* The actual work is done by handleFinalise, which is the finalisation */
/* routine attached to all STORE_HANDLEs. This allows multiple levels */
/* of free-ing by allocating new STORE_HANDLES on old ones, using */
/* handleHandleCreate. handleCreate is simply defined as handleHandleCreate(0) */

static void handleFinalise (void *p)
{
  STORE_HANDLE handle = (STORE_HANDLE)p;
  STORE_HANDLE next, unit = handle->next ;

/* do handle finalisation first */  
  if (handle->final)
    (*handle->final)((void *)handle->back);

      while (unit)
    { 
#ifdef MALLOC_CHECK
      checkUnit (unit) ;
      unit->check1 = 0x87654321; /* test for double free */
#endif
      if (unit->final)
	(*unit->final)(toMemPtr(unit)) ;
      next = unit->next ;
      --numMessAlloc ;
      totMessAlloc -= unit->size ;
      free (unit) ;
      unit = next ;
    }

#ifdef MALLOC_CHECK
  arrayRemove (handles, &p, handleOrder) ;
#endif

/* This is a finalisation routine, the actual store is freed in messfree,
   or another invokation of itself. */
}
  
void handleSetFinalise(STORE_HANDLE handle, void (*final)(void *), void *arg)
{ handle->final = final;
  handle->back = (STORE_HANDLE)arg;
}

STORE_HANDLE handleHandleCreate(STORE_HANDLE handle)
{ 
  STORE_HANDLE res = (STORE_HANDLE) handleAlloc(handleFinalise, 
						handle,
						sizeof(STORE_HANDLE_STRUCT));
#ifdef MALLOC_CHECK
  /* NB call to handleAlloc above ensures that handles is initialised here */
  arrayInsert (handles, &res, handleOrder) ;
#endif
  res->next = res->back = 0 ; /* No blocks on this handle yet. */
  res->final = 0 ; /* No handle finalisation */
  return res ;
}

BOOL finalCleanup = FALSE ;
#ifdef MEM_DEBUG
void handleCleanUp (void) 
{ finalCleanup = TRUE ;
  handleFinalise ((void *)&handle0) ;
}
#endif

/************** checking functions, require MALLOC_CHECK *****/

#ifdef MALLOC_CHECK
static void checkUnit (STORE_HANDLE unit)
{
  if (unit->check1 == 0x87654321)
    messerror ("Block at %x freed twice - bad things will happen.",
	       toMemPtr(unit));
  else
    if (unit->check1 != 0x12345678)
      messerror ("Malloc error at %x length %d: "
		 "start overwritten with %x",
		 toMemPtr(unit), unit->size, unit->check1) ;
  
  if (check2(unit) != 0x12345678)
    messerror ("Malloc error at %x length %d: "
	       "end overwritten with %x",
	       toMemPtr(unit), unit->size, check2(unit)) ;
}

void messalloccheck (void)
{
  int i ;
  STORE_HANDLE unit ;

  if (!handles) return ;

  for (i = 0 ; i < arrayMax(handles) ; ++i) 
    for (unit = arr(handles,i,STORE_HANDLE)->next ; unit ; unit=unit->next)
      checkUnit (unit) ;
}
#else
void messalloccheck (void) {}
#endif

/******************* status monitoring functions ******************/

void handleInfo (STORE_HANDLE handle, int *number, int *size)
{
  STORE_HANDLE unit = handle->next;

  *number = 0;
  *size = 0;

  while (unit)
    { ++*number ;
      *size += unit->size ;
      unit = unit->next ;
    }
}

int messAllocStatus (int *mem)
{ 
  *mem = totMessAlloc ;
  return numMessAlloc ;
}

/*************************** end of file ************************/
/****************************************************************/
