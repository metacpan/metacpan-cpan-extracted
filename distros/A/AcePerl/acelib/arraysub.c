/*  File: arraysub.c
 *  Author: Jean Thierry-Mieg (mieg@mrc-lmba.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmba.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@crbm.cnrs-mop.fr
 *
 * Description:
 *              Arbitrary length arrays, stacks, associators
 *              line breaking and all sorts of other goodies
 *              These functions are declared in array.h
 *               (part of regular.h - the header for libfree.a)
 * Exported functions:
 *              See Header file: array.h (includes lots of macros)
 * HISTORY:
 * Last edited: Dec  4 11:12 1998 (fw)
 * * Nov  1 16:11 1996 (srk)
 *		-	MEM_DEBUG code clean-up 
 *                      (some loose ends crept in from WIN32)
 *		-	int (*order)(void*,void*) prototypes used 
 *                                            uniformly throughout
 * * Jun  5 00:48 1996 (rd)
 * * May  2 22:33 1995 (mieg): killed the arrayReport at 20000
      otherwise it swamps 50 Mbytes of RAM
 * * Jan 21 16:25 1992 (mieg): messcrash in uArrayCreate(size<=0)
 * * Dec 17 11:40 1991 (mieg): stackTokeniseTextOn() tokeniser.
 * * Dec 12 15:45 1991 (mieg): Stack magic and stackNextText
 * Created: Thu Dec 12 15:43:25 1989 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: arraysub.c,v 1.1 2002/11/14 20:00:06 lstein Exp $	 */

   /* Warning : if you modify Array or Stack structures or 
      procedures in this file or array.h, you may need to modify 
      accordingly the persistent array package asubs.c.
   */

#include "regular.h"
/*#include <limits.h>*/

extern BOOL finalCleanup ;	/* in messubs.c */

/******** tells how much system stack used *********/

char *stackorigin ;

unsigned int stackused (void)
{ char x ;
  if (!stackorigin)          /* ideally should set in main() */
    stackorigin = &x ;
  return stackorigin - &x ;        /* MSDOS stack grows down */
}

/************ Array : class to implement variable length arrays ************/

static int totalAllocatedMemory = 0 ;
static int totalNumberCreated = 0 ;
static int totalNumberActive = 0 ;
static Array reportArray = 0 ;
static void uArrayFinalise (void *cp) ;

#ifndef MEM_DEBUG
  Array uArrayCreate (int n, int size, STORE_HANDLE handle)
{ int id = totalNumberCreated++ ;
  Array new = (Array) handleAlloc (uArrayFinalise, 
				   handle,
				   sizeof (struct ArrayStruct)) ;
#else
Array   uArrayCreate_dbg (int n, int size, STORE_HANDLE handle,
					      const char *hfname,int hlineno) 
{ int id = totalNumberCreated++ ;
  Array new = (Array) handleAlloc_dbg (uArrayFinalise, 
				   handle,
				   sizeof (struct ArrayStruct),
				   dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
#endif

  if (!reportArray)
    { reportArray = (Array)1 ; /* prevents looping */
      reportArray = arrayCreate (512, Array) ;
    }
  if (size <= 0)
    messcrash("negative size %d in uArrayCreate", size) ;
  if (n < 1)
    n = 1 ;
  totalAllocatedMemory += n * size ;
#ifndef MEM_DEBUG
  new->base = messalloc (n*size) ;
#else
  new->base = messalloc_dbg (n*size,dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
#endif
  new->dim = n ;
  new->max = 0 ;
  new->size = size ;
  new->id = ++id ;
  new->magic = ARRAY_MAGIC ;
  totalNumberActive++ ;
  if (reportArray != (Array)1) 
    { if (new->id < 20000)
	array (reportArray, new->id, Array) = new ;
      else
	{ Array aa = reportArray ;
	  reportArray = (Array)1 ; /* prevents looping */
	  arrayDestroy (aa) ;
	}
    }
  return new ;
}

/**************/

int arrayReportMark (void)
{
  return reportArray != (Array)1 ?  
      arrayMax(reportArray) : 0 ;
}

/**************/

void arrayReport (int j)
{ int i ;
  Array a ;

 if (reportArray == (Array)1) 
   { fprintf(stderr,
	     "\n\n %d active arrays, %d created, %d kb allocated\n\n ",   
	     totalNumberActive,   totalNumberCreated , totalAllocatedMemory/1024) ;
     return ;
   }
  
  fprintf(stderr,"\n\n") ;
  
  i = arrayMax (reportArray) ;
  while (i-- && i > j)
    { a = arr (reportArray, i, Array) ;
      if (arrayExists(a))
	fprintf (stderr, "Array %d  size=%d max=%d\n", i, a->size, a->max) ;
    }
}

/**************/

void arrayStatus (int *nmadep, int *nusedp, int *memAllocp, int *memUsedp)
{ 
  int i ;
  Array a, *ap ;

  *nmadep = totalNumberCreated ; 
  *nusedp = totalNumberActive ;
  *memAllocp = totalAllocatedMemory ;
  *memUsedp = 0 ;

  if (reportArray == (Array)1) 
    return ;

  i = arrayMax(reportArray) ;
  ap = arrp(reportArray, 0, Array) - 1 ;
  while (ap++, i--)
    if (arrayExists (*ap))
      { a = *ap ;
	*memUsedp += a->max * a->size ;
      }
}

/**************/

Array uArrayReCreate (Array a, int n, int size)
{ if (!arrayExists(a))
    return  uArrayCreate(n, size, 0) ;

  if(a->size != size)
    messcrash("Type  missmatch in uArrayRecreate, you should always "
	      "call recreate using the same type") ;

  if (n < 1)
    n = 1 ;
  if (a->dim < n || 
      (a->dim - n)*size > (1 << 19) ) /* free if save > 1/2 meg */
    { totalAllocatedMemory -= a->dim * size ;
      messfree (a->base) ;
      a->dim = n ;
      totalAllocatedMemory += a->dim * size ;
      a->base = messalloc (a->dim*size) ;
    }
  memset(a->base,0,(mysize_t)(a->dim*size)) ;

  a->max = 0 ;
  return a ;
}

/**************/

void uArrayDestroy (Array a)
/* Note that the finalisation code attached to the memory does the work, 
   see below */
{
  if (!a) return;

  if (a->magic != ARRAY_MAGIC)
    messcrash ("uArrayDestroy received corrupt array->magic");

  messfree(a);
}

static void uArrayFinalise (void *cp)
{ Array a = (Array)cp;

  totalAllocatedMemory -= a->dim * a->size ;
  if (!finalCleanup) messfree (a->base) ;
  a->magic = 0 ;
  totalNumberActive-- ;
  if (!finalCleanup && reportArray != (Array)1) 
    arr(reportArray, a->id, Array) = 0 ;
}

/******************************/

#ifndef MEM_DEBUG
  void arrayExtend (Array a, int n)
#else
  void arrayExtend_dbg (Array a, int n, const char *hfname,int hlineno) 
#endif
{
  char *new ;

  if (!a || n < a->dim)
    return ;

  totalAllocatedMemory -= a->dim * a->size ;
  if (a->dim*a->size < 1 << 23)  /* 2 megs of keys, or 8 megs of ram */
    a->dim *= 2 ;
  else
    a->dim += 1024 + ((1 << 23) / a->size) ;
  if (n >= a->dim)
    a->dim = n + 1 ;

  totalAllocatedMemory += a->dim * a->size ;
#ifndef MEM_DEBUG
  new = messalloc (a->dim*a->size) ;
#else
  new = messalloc_dbg (a->dim*a->size,dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
#endif
  memcpy (new,a->base,a->size*a->max) ;
  messfree (a->base) ;
  a->base = new ;
}

/***************/

char *uArray (Array a, int i)
{
  if (i < 0)
    messcrash ("referencing array element %d < 0", i) ;
  if (!a)
    messcrash ("uArray called with NULL Array struc");

  if (i >= a->max)
    { if (i >= a->dim)
        arrayExtend (a,i) ;
      a->max = i+1 ;
    }
  return a->base + i*a->size ;
}

/***************/

char *uArrayCheck (Array a, int i)
{
  if (i < 0)
    messcrash ("referencing array element %d < 0", i) ;

  return uArray(a, i) ;
}

/***************/

char *uArrCheck (Array a, int i)
{
  if (i >= a->max || i < 0)
    messcrash ("array index %d out of bounds [0,%d]",
	       i, a->max - 1) ;
  return a->base + i*a->size ;
}

/**************/

#ifndef MEM_DEBUG
  Array arrayCopy (Array a)
#else
  Array arrayCopy_dbg(Array a, const char *hfname,int hlineno) 
#endif
{ Array b ;
  
  if (arrayExists (a) && a->size)
    {
#ifndef MEM_DEBUG
      b = uArrayCreate (a->max, a->size, 0) ;
#else
	  b = uArrayCreate_dbg (a->max, a->size, 0,
				dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
#endif
      memcpy(b->base, a->base, a->max * a->size);
      b->max = a->max ;
      return b;
    }
  else
    return 0 ;
}

/**************/

Array arrayTruncatedCopy (Array a, int x1, int x2)
{ Array b = 0 ;
  
  if (x1 < 0 || x2 < x1 || x2 > a->max)
    messcrash 
      ("Bad coordinates x1 = %d, x2 = %d in arrayTruncatedCopy",
       x1, x2) ;
  if (arrayExists (a) && a->size)
    { if (x2 - x1)
	{ b = uArrayCreate (x2 - x1, a->size, 0) ;
	  b->max = x2 - x1 ;
	  memcpy(b->base, a->base + x1, b->max * b->size);
	}
      else
	b = uArrayCreate (10, a->size, 0) ;
    }
  return b;
}

/**************/

void arrayCompress(Array a)
{
  int i, j, k , as ;
  char *x, *y, *ab  ;
  
  if (!a || !a->size || arrayMax(a) < 2 )
    return ;

  ab = a->base ; 
  as = a->size ;
  for (i = 1, j = 0 ; i < arrayMax(a) ; i++)
    { x = ab + i * as ; y = ab + j * as ;
      for (k = a->size ; k-- ;)		
	if (*x++ != *y++) 
	  goto different ;
      continue ;
      
    different:
      if (i != ++j)
	{ x = ab + i * as ; y = ab + j * as ;
	  for (k = a->size ; k-- ;)	 
	    *y++ = *x++ ;
	}
    }
  arrayMax(a) = j + 1 ;
}

/****************/

/* 31.7.1995 dok408  added arraySortPos() - restricted sorting to tail of array */

void arraySort(Array a, int (*order)(void*, void*)) { arraySortPos(a, 0, order) ; }

void arraySortPos (Array a, int pos, int (*order)(void*, void*))
{
  typedef int (*CONSTORDER)(const void*, const void*) ;
  unsigned int n = a->max - pos, s = a->size ;
  void *v = a->base + pos * a->size ;
 
  if (pos < 0) messcrash("arraySortPos: pos = %d", pos);

  if (n > 1) 
#if defined(THINK_C) || defined(metrowerks) /* THINK C & Metrowerks quicksorts suck */
    { extern void qcksrt (char *base, int n, int size, 
			  int (*comp)(void*, void*)) ;
      qcksrt (v, n, s, order) ;
    }
#else
    qsort(v, n, s, (CONSTORDER)order) ;
#endif
}

/***********************************************************/

BOOL arrayIsEntry (Array a, int i, void *s)
{
  char *cp = uArray(a,i), *cq = s ;
  int j = a->size;

  while (j--)
    if (*cp++ != *cq++) 
      return FALSE ;
  return TRUE;
}

/***********************************************/
       /* Finds Entry s from Array  a
        * sorted in ascending order of order()
        * If found, returns TRUE and sets *ip
        * if not, returns FALSE and sets *ip one step left
        */

BOOL arrayFind(Array a, void *s, int *ip, int (* order)(void*, void*))
{
  int ord;
  int i = 0 , j = arrayMax(a), k;

  if(!j || (ord = order(s,uArray(a,0)))<0)
    { if (ip)
	*ip = -1; 
      return FALSE;
    }   /* not found */

  if (ord == 0)
    { if (ip)
	*ip = 0;
      return TRUE;
    }

  if ((ord = order(s,uArray(a,--j)))>0 )
    { if (ip)
	*ip = j; 
      return FALSE;
    }
  
  if (ord == 0)
    { if (ip)
	*ip = j;
      return TRUE;
    }

  while(TRUE)
    { k = i + ((j-i) >> 1) ; /* midpoint */
      if ((ord = order(s, uArray(a,k))) == 0)
	{ if (ip)
	    *ip = k; 
	  return TRUE;
	}
      if (ord > 0) 
	(i = k);
      else
	(j = k) ;
      if (i == (j-1) )
        break;
    }
  if (ip)
    *ip = i ;
  return FALSE;
}

/**************************************************************/
       /* Removes Entry s from Array  a
        * sorted in ascending order of order()
        */

BOOL arrayRemove (Array a, void * s, int (* order)(void*, void*))
{
  int i;

  if (arrayFind(a, s, &i,order))
    {
      /* memcpy would be faster but regions overlap
       * and memcpy is said to fail with some compilers
       */
      char *cp = uArray(a,i),  *cq = cp + a->size ;
      int j = (arrayMax(a) - i)*(a->size) ;
      while(j--)
	*cp++ = *cq++;

      arrayMax(a) --;
      return TRUE;
    }
  else

    return FALSE;
}

/**************************************************************/
       /* Insert Segment s in Array  a
        * in ascending order of s.begin
        */

BOOL arrayInsert(Array a, void * s, int (*order)(void*, void*))
{
  int i, j;

  if (arrayFind(a, s, &i,order))
    return FALSE;  /* no doubles */
  
  j = arrayMax(a) + 1;
  uArray(a,j-1) ; /* to create space */

	/* avoid memcpy for same reasons as above */
  {
    char* cp = uArray(a,j - 1) + a->size - 1,  *cq = cp - a->size ;
    int k = (j - i - 1)*(a->size);
    while(k--)
      *cp-- = *cq--;
    
    cp = uArray(a,i+1); cq = (char *) s; k = a->size;
    while(k--)
      *cp++ = *cq++;
  }
  return TRUE;
}

/********* Stack : arbitrary Stack class - inherits from Array **********/

static void uStackFinalise (void *cp) ;

#ifndef MEM_DEBUG
Stack stackHandleCreate (int n, STORE_HANDLE handle)  /* n is initial size */
{
  Stack s = (Stack) handleAlloc (uStackFinalise, 
				 handle,
				 sizeof (struct StackStruct)) ;
#else
Stack stackHandleCreate_dbg (int n, STORE_HANDLE handle,  /* n is initial size */
					      const char *hfname, int hlineno)
{
  Stack s = (Stack) handleAlloc_dbg (uStackFinalise, 
				 handle,
				 sizeof (struct StackStruct),
				 hfname, hlineno) ;
#endif
  s->magic = STACK_MAGIC ;
  s->a = arrayCreate (n,char) ;
  s->pos = s->ptr = s->a->base ;
  s->safe = s->a->base + s->a->dim - 16 ; /* safe to store objs up to size 8 */
  s->textOnly = FALSE;
  return s ;
}

void stackTextOnly(Stack s)
{ if (!stackExists(s))
    messcrash("StackTextOnly given non-exisant stack.");

  s->textOnly = TRUE;
}

Stack stackReCreate (Stack s, int n)               /* n is initial size */
{
  if (!stackExists(s))
    return stackCreate(n) ;

  s->a = arrayReCreate (s->a,n,char) ;
  s->pos = s->ptr = s->a->base ;
  s->safe = s->a->base + s->a->dim - 16 ; /* safe to store objs up to size 8 */
  return s ;
}

Stack stackCopy (Stack s, STORE_HANDLE handle)
{
  Stack new ;

  if (!stackExists(s))
    return 0 ;

  new = (Stack) handleAlloc (uStackFinalise, handle,
			     sizeof (struct StackStruct)) ;
  *new = *s ;
  new->a = arrayCopy (s->a) ;
  return new ;
}

Stack arrayToStack (Array a)
{ 
  Stack s ;
  int n ;

  if (!arrayExists(a) || a->size != 1 )
    return 0 ;
    
  n = arrayMax(a) ;
  s = stackCreate(n  + 32) ;
              
  memcpy(s->a->base, a->base, n) ;
                
  s->pos = s->a->base ;
  s->ptr = s->a->base + n ;
  s->safe = s->a->base + s->a->dim - 16 ; /* safe to store objs up to size 8 */
  while ((long)s->ptr % STACK_ALIGNMENT)
    *(s->ptr)++ = 0 ;   
  return s ;
}

void uStackDestroy(Stack s)
{ if (s && s->magic == STACK_MAGIC) messfree(s);
} /* the rest is done below as a consequence */

static void uStackFinalise (void *cp)
{ Stack s = (Stack)cp;
  if (!finalCleanup) arrayDestroy (s->a) ;
  s->magic = 0 ;
}

void stackExtend (Stack s, int n)
{
  int ptr = s->ptr - s->a->base,
      pos = s->pos - s->a->base ;
  s->a->max = s->a->dim ;	/* since only up to ->max copied over */
  arrayExtend (s->a,ptr+n+16) ;	/* relies on arrayExtend mechanism */
  s->ptr = s->a->base + ptr ;
  s->pos = s->a->base + pos ;
  s->safe = s->a->base + s->a->dim - 16 ;
}

int stackMark (Stack s)
{ return (s->ptr - s->a->base) ;
}

int stackPos (Stack s)
{ return (s->pos - s->a->base) ;
}

void stackCursor (Stack s, int mark)
{ s->pos = s->a->base + mark ;
}


/* access doubles on the stack by steam on systems where we don't
   align the stack strictly enough, this code assumes that ints are 32bits
   and doubles 64 */



union mangle { double d;
	       struct { int i1;
			int i2;
		      } i;
	     };

void ustackDoublePush(Stack stk, double x)
{ union mangle m;

  m.d = x;
  push(stk, m.i.i1, int);
  push(stk, m.i.i2, int);
}

double ustackDoublePop(Stack stk)
{ union mangle m;

  m.i.i2 = pop(stk, int);
  m.i.i1 = pop(stk, int);

  return m.d;
}

double ustackDoubleNext(Stack stk)
{ union mangle m;

  m.i.i1 = stackNext(stk, int);
  m.i.i2 = stackNext(stk, int);

  return m.d;
}

void pushText (Stack s, char* text)
{
  while (s->ptr + strlen(text)  > s->safe) 
    stackExtend (s,strlen(text)+1) ;
  while ((*(s->ptr)++ = *text++)) ;
  if (!s->textOnly)
    while ((long)s->ptr % STACK_ALIGNMENT)
      *(s->ptr)++ = 0 ;   
}

char* popText (Stack s)
{
  char *base = s->a->base ;

  while (s->ptr > base && !*--(s->ptr)) ;
  while (s->ptr >= base && *--(s->ptr)) ;
  return ++(s->ptr) ;
}

void catText (Stack s, char* text)
{
  while (s->ptr + strlen(text) > s->safe)
    stackExtend (s,strlen(text)+1) ;
  *s->ptr = 0 ;
  while (s->ptr >= s->a->base && *s->ptr == 0)
    s->ptr -- ;
  s->ptr ++ ;
  while ((*(s->ptr)++ = *text++)) ;
  if (!s->textOnly)
    while ((long)s->ptr % STACK_ALIGNMENT)
      *(s->ptr)++ = 0 ;   
}

void catBinary (Stack s, char* data, int size)
{
  int total;
  total = size + 1;

  while (s->ptr + total > s->safe)
    stackExtend (s,size+1) ;
  *s->ptr = 0 ;
  while (s->ptr >= s->a->base && *s->ptr == 0)
    s->ptr -- ;
  s->ptr ++ ;
  memcpy(s->ptr,data,size);
  s->ptr += size;
  /* end with a newline to prevent truncation by next cat */
  *(s->ptr)++ = '\n';
  if (!s->textOnly)
    while ((long)s->ptr % STACK_ALIGNMENT)
      *(s->ptr)++ = 0 ;   
}

char* stackNextText (Stack s)
{ char *text = s->pos ;
  if (text>= s->ptr)
    return 0 ;  /* JTM, so while stackNextText makes sense */
  while (*s->pos++) ;
  if (!s->textOnly)
    while ((long)s->pos % STACK_ALIGNMENT)
      ++s->pos ;
  return text ;
}

/*********/
     /* Push text in stack s, after breaking it on delimiters */
     /* You can later access the tokens with command
	while (token = stackNextText(s)) work on your tokens ;
	*/
void  stackTokeniseTextOn(Stack s, char *text, char *delimiters)
{
  char *cp, *cq , *cend, *cd, old, oldend ;
  int i, n ;

  if(!stackExists(s) || !text || !delimiters)
    messcrash("stackTextOn received some null parameter") ;

  n = strlen(delimiters) ;
  cp = cq  = text ;
  while(TRUE)
    {
      while(*cp == ' ')
	cp++ ;
      cq = cp ;
      old = 0 ;
      while(*cq)
	{ for (cd = delimiters, i = 0 ; i < n ; cd++, i++)
	    if (*cd == *cq)
	      { old = *cq ;
		*cq = 0 ;
		goto found ;
	      }
	  cq++ ;
	}
    found:
      cend = cq ;
      while(cend > cp && *--cend == ' ') ;
      if (*cend != ' ') cend++ ;
      oldend = *cend ; *cend = 0 ;
      if (*cp && cend > cp)
	pushText(s,cp) ;
      *cend = oldend ;
      if(!old)
	{ stackCursor(s, 0) ;
	  return ;
	}
      *cq = old ;
      cp = cq + 1 ;
    }
}

void stackClear(Stack s)
{ if (stackExists(s))
    { s->pos = s->ptr = s->a->base;
      s->a->max = 0;
    }
}

/****************** routines to set text into lines ***********************/

static char *linesText ;
static Array lines ;
static Array textcopy ;
static int kLine, popLine ;

/**********/

int uLinesText (char *text, int width)
{
  char *cp,*bp ;
  int i ;
  int nlines = 0 ;
  int length = strlen (text) ;
  int safe = length + 2*(length/(width > 0 ? width : 1) + 1) ; /* mieg: avoid zero divide */
  static int isFirst = TRUE ;

  if (isFirst)
    { isFirst = FALSE ;
      lines = arrayCreate(16,char*) ;
      textcopy = arrayCreate(128,char) ;
    }

  linesText = text ;
  array(textcopy,safe,char) = 0 ;   /* ensures textcopy is long enough */

  if (!*text)
    { nlines = popLine = kLine = 0 ;
      array(lines,0,char*) = 0 ;
      return 0 ;
    }

  cp = textcopy->base ;
  nlines = 0 ;
  for (bp = text ; *bp ; ++bp)
    { array(lines,nlines++,char*) = cp ;
      for (i = 0 ; (*cp = *bp) && *cp != '\n' ; ++i, ++cp, ++bp)
        if (i == width)		/* back up to last space */
          { while (i--)
	      { --bp ; --cp ;
		if (*cp == ' ' || *cp == ',' || *cp == ';')
		  goto eol ;
	      }
	    cp += width ;	/* no coma or spaces in whole line ! */
	    bp += width ;
	    break ;
	  }
eol:  if (!*cp)
        break ;
      if (*cp != '\n')
	++cp ;
      *cp++ = 0 ;
    }
  kLine = 0 ;			/* reset for uNextLine() */
  popLine = nlines ;
  array(lines,nlines,char*) = 0 ; /* 0 terminate */

  return nlines ;
 }

char *uNextLine (char *text)
 {
   if (text != linesText)
     messout ("Warning : uNextLine being called with bad context") ;
   return array(lines,kLine++,char*) ;
 }

char *uPopLine (char *text)
 {
   if (text != linesText)
     messout ("Warning : uPopLine being called with bad context") ;
   if (popLine)
     return array(lines,--popLine,char*) ;
   else return 0;
 }

char **uBrokenLines (char *text, int width)
{
  uLinesText (text,width) ;
  return (char**)lines->base ;
}

char *uBrokenText (char *text, int width)
{
  char *cp ;

  uLinesText (text,width) ;
  uNextLine (text) ;
  while ((cp = uNextLine (text)))
    *(cp-1) = '\n' ;
  return arrp(textcopy,0,char) ;
}

/*************************************************************/
/* perfmeters */
int assBounce = 0, assFound = 0, assNotFound = 0, assInserted = 0, assRemoved = 0 ;

/* Associator package is for associating pairs of pointers. 
   Assumes that an "in" item is non-zero and non -1.
   Implemented as a hash table of size 2^m.  
   
   Originally grabbed from Steve Om's sather code by Richard Durbin.

   Entirelly rewritten by mieg, using bouncing by relative primes
   and deletion flagging.

   User has access to structure member ->n = # of pairs
*/

#define VSIZE (sizeof(void*))
#define VS5 (VSIZE/5)
#define VS7 (VSIZE/7)
#define moins_un ((void*) (-1))

#define HASH(_xin) { register long z = VS5, x = (char*)(_xin) - (char*)0 ; \
		  for (hash = x, x >>= 5 ; z-- ; x >>= 5) hash ^= x ; \
		  hash &= a->mask ; \
		}

#define DELTA(_xin)   { register long z = VS7, x = (char*)(_xin) - (char*)0 ; \
		       for (delta = x, x >>= 7 ; z-- ; x >>= 7) delta ^= x ; \
		       delta = (delta & a->mask) | 0x01 ; \
		   }  /* delta odd is prime relative to  2^m */

/**************** Destruction ****************************/

static void assFinalise(void *cp)
{ Associator a = (Associator)cp;

  a->magic = 0 ;
  if (!finalCleanup)
    { messfree(a->in) ;
      messfree(a->out);
    }
}

void uAssDestroy (Associator a)
{ if (assExists(a))
    messfree (a) ;  /* calls assFinalise */
}

/**************** Creation *******************************/

#ifndef MEM_DEBUG
  static Associator assDoCreate (int nbits, STORE_HANDLE handle)
#else
  static Associator assDoCreate (int nbits, STORE_HANDLE handle,
				 const char *hfname, int hlineno)
#endif
{ static int nAss = 0 ;
  Associator a ;
  int size = 1 << nbits,  /* size must be a power of 2 */
      vsize = size * VSIZE ; 
#ifndef MEM_DEBUG
  a = (Associator) handleAlloc(assFinalise, 
			       handle, 
			       sizeof (struct AssStruct)) ;
  a->in = (void**) messalloc (vsize) ;
  a->out = (void**) messalloc (vsize) ;
#else
  a = (Associator) handleAlloc_dbg(assFinalise, 
			       handle, 
			       sizeof (struct AssStruct),
				   dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
  a->in = (void**) messalloc_dbg(vsize,dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
  a->out = (void**) messalloc_dbg(vsize,dbgPos(hfname, hlineno, __FILE__), __LINE__) ;
#endif
  a->magic = ASS_MAGIC ;
  a->id = ++nAss ;
  a->n = 0 ;
  a->i = 0 ; /* start up position for recursive calls */
  a->m = nbits ;
  a->mask = size - 1 ;
  return a ;
}

/*******************/

#ifndef MEM_DEBUG
  Associator assBigCreate (int size)
#else
  Associator assBigCreate_dbg(int size, const char *hfname, int hlineno)
#endif
{
  int n = 2 ; /* make room, be twice as big as needed */

  if (size <= 0) 
    messcrash ("assBigCreate called with size = %d <= 0", size) ;

  --size ;
  while (size >>= 1) n++ ; /* number of left most bit + 1 */
#ifndef MEM_DEBUG
  return assDoCreate(n, 0) ;
#else
  return assDoCreate(n, 0, hfname, hlineno) ;
#endif
}

/*******************/

#ifndef MEM_DEBUG
  Associator assHandleCreate(STORE_HANDLE handle) { return assDoCreate(5, handle) ;}
#else
  Associator assHandleCreate_dbg(STORE_HANDLE handle, const char *hfname,int hlineno)
  { return assDoCreate(5, handle, dbgPos(hfname, hlineno, __FILE__), __LINE__) ; }
#endif

/*******************/

void assClear (Associator a)
{ mysize_t sz ;
  if (!assExists(a)) 
    return ;
  
  a->n = 0 ;
  sz = ( 1 << a->m) *  VSIZE ;
  memset(a->in, 0, sz) ;
  memset(a->out, 0, sz) ;
}

/********************/

Associator assReCreate (Associator a)
{ if (!assExists(a))
    return assCreate() ;
  else
    { assClear (a) ;  return a ; }
}

/********************/

static void assDouble (Associator a)
{ int oldsize, newsize, nbits ;
  register int hash, delta ;
  void **old_in = a->in, **old_out = a->out, **xin, **xout ;
  int i ;

  nbits = a->m ;
  oldsize = 1 << nbits ;
  newsize = oldsize << 1 ; /* size must be a power of 2 */

  a->n = 0 ;
  a->i = 0 ; /* start up position for recursive calls */
  a->m = nbits + 1 ;
  a->mask = newsize - 1 ;
  a->in  = (void**) messalloc (newsize * VSIZE) ;
  a->out = (void**) messalloc (newsize * VSIZE) ;

  for (i = 0, xin = old_in, xout = old_out ; i < oldsize ; i++, xin++, xout++)
    if (*xin && *xin != moins_un)
      { HASH(*xin) ;
        while (TRUE)
          { if (!a->in[hash])  /* don't need to test moins_un */
              { a->in[hash] = *xin ;
                a->out[hash] = *xout ;
                ++a->n ;
                assInserted++ ;
                break ;
              }
            assBounce++ ;
	    DELTA(*xin) ;	/* redo each time - cheap overall */
            hash = (hash + delta) & a->mask ;
          }
      }

  messfree (old_in) ;
  messfree (old_out) ;
}

/************************ Searches  ************************************/

BOOL uAssFind (Associator a, void* xin, void** pout)
/* if found, updates *pout and returns TRUE, else returns FALSE	*/
{ int hash, delta = 0 ;
  void* test ;

  if (!assExists(a))
    messcrash ("assFind received corrupted associator") ;
  if (!xin || xin == moins_un) return FALSE ;

  HASH(xin) ;
  while (TRUE)
    { test = a->in[hash] ;
      if (test == xin)
	{ if (pout)
	    *pout = a->out[hash] ;
	  assFound++ ;
	  a->i = hash ;
	  return TRUE ;
	}
      if (!test)
	break ;
      assBounce++ ;
      if (!delta) DELTA(xin) ;
      hash = (hash + delta) & a->mask ;
    }
  assNotFound++ ;
  return FALSE ;
}

/********************/
  /* Usage: if(uAssFind()){while (uAssFindNext()) ... } */
BOOL uAssFindNext (Associator a, void* xin, void** pout)
/* if found, updates *pout and returns TRUE, else returns FALSE	*/
{ int	hash, delta ;
  void* test ;

  if (!assExists(a))
    messcrash ("assFindNext received corrupted associator") ;
  if (!xin || xin == moins_un || !a->in[a->i]) 
    return FALSE ;
  if (a->in[a->i] != xin)
    messcrash ("Non consecutive call to assFindNext") ;

  hash = a->i ;
  DELTA(xin) ;
  while (TRUE)
    { test = a->in[hash] ;
      if (test == xin)
	{ if (pout)
	    *pout = a->out[hash] ;
	  while (TRUE) /* locate on next entry */
	    { hash = (hash + delta) & a->mask ; 
	      test = a->in[hash] ;
	      if (!test || test == xin)
		break ;
	      assBounce++ ;
	    }
	  a->i = hash ; /* points to next entry or zero */
	  assFound++ ;
	  return TRUE ;
	}
      if (!test)
	break ;
      assBounce++ ;
      hash = (hash + delta) & a->mask ;
    }
  assNotFound++ ;
  return FALSE ;
}

/************************ Insertions  ************************************/

     /* if already there returns FALSE, else inserts and returns TRUE */
static BOOL assDoInsert (Associator a, void* xin, void* xout, BOOL noMultiples)
{ int	hash, delta = 0 ;
  void* test ;

  if (!assExists(a))
    messcrash ("assInsert received corrupted associator") ;

  if (!xin || xin == moins_un) 
    messcrash ("assInsert received forbidden value xin == 0") ;

  if (a->n >= (1 << (a->m - 1))) /* reaching floating line */
    assDouble (a) ;

  HASH (xin) ;
 
  while (TRUE)
    { test = a->in[hash] ;
      if (!test || test == moins_un)  /* reuse deleted slots */
	{ a->in[hash] = xin ;
	  a->out[hash] = xout ;
	  ++a->n ;
	  assInserted++ ;
	  return TRUE ;
	}
      if (noMultiples && test == xin)		/* already there */
	return FALSE ;
      assBounce++ ;
      if (!delta) DELTA (xin) ;
      hash = (hash + delta) & a->mask ;
    }
}

/*****************/
     /* This one does not allow multiple entries in one key. */
BOOL assInsert (Associator a, void* xin, void* xout)
{ return assDoInsert (a, xin, xout, TRUE) ;
}
 
/*****************/

void assMultipleInsert (Associator a, void* xin, void* xout)
     /* This one allows multiple entries in one key. */
{ assDoInsert (a, xin, xout, FALSE) ;
}
 
/************************ Removals ************************************/
   /* if found, removes entry and returns TRUE, else returns FALSE	*/
   /* No a->n--, because the entry is blanked but not actually removed */
BOOL assRemove (Associator a, void* xin)
{ if (assExists(a) && uAssFind (a, xin, 0))
    { a->in[a->i] = moins_un ;
      assRemoved++ ;
      return TRUE ;
    }
  else
    return FALSE ;
}

/*******************/

/* if found, removes entry and returns TRUE, else returns FALSE	*/
/* Requires both xin and xout to match */
BOOL assPairRemove (Associator a, void* xin, void* xout)
{ if (!assExists(a) || !xin || xin == moins_un) return FALSE ;
  if (uAssFind (a, xin, 0))
    while (uAssFindNext (a, xin, 0))
      if (a->out[a->i] == xout)
	{ a->in[a->i] = moins_un ;
	  assRemoved++ ;
	  return TRUE ;
	}
  return FALSE ;
}

/************************ dumpers ********************************/
     /* lets you step through all members of the table */
BOOL uAssNext (Associator a, void* *pin, void* *pout)
{ int size ;
  void *test ;

  if (!assExists(a))
     messcrash("uAssNext received a non existing associator") ;
  size = 1 << a->m ;
  if (!*pin)
    a->i = -1 ;
  else if (*pin != a->in[a->i])
    { messerror ("Non-consecutive call to assNext()") ;
      return FALSE ;
    }

  while (++a->i < size)
    { test = a->in[a->i] ;
      if (test && test != moins_un) /* not empty or deleted */
	{ *pin = a->in[a->i] ;
	  if (pout)
	    *pout = a->out[a->i] ;
	  return TRUE ;
	}
    }
  return FALSE ;
}

/*******************/

void assDump (Associator a)
{ int i ; 
  void **in, **out ;
  char *cp0 = 0 ;

  if (!assExists(a)) return ;

  i = 1 << a->m ;
  in = a->in - 1 ; out = a->out - 1 ;
      /* keep stderr here since it is for debugging */
  fprintf (stderr,"Associator %lx : %d pairs\n",(unsigned long)a,a->n) ;
  while (in++, out++, i--)
    if (*in && *in != moins_un) /* not empty or deleted */
      fprintf (stderr,"%lx - %lx\n",
	       (long)((char*)(*in) - cp0),(long)( (char *)(*out) - cp0)) ;
}

/************************  end of file ********************************/
/**********************************************************************/
 
 
 
 
 
