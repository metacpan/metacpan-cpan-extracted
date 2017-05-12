/*  File: array.h
 *  Author: Richar Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (Sanger Centre, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@crbm.cnrs-mop.fr
 *
 * Description: header for arraysub.c
 *              NOT to be included by the user, included by regular.h
 * Exported functions:
 *              the Array type and associated functions
 *              the Stack type and associated functions
 *              the Associator functions
 * HISTORY:
 * Last edited: Dec  4 11:03 1998 (fw)
 * Created: Fri Dec  4 11:01:35 1998 (fw)
 *-------------------------------------------------------------------
 */

#ifndef DEF_ARRAY_H
#define DEF_ARRAY_H
 
unsigned int stackused (void) ;
 
/************* Array package ********/

/* #define ARRAY_CHECK either here or in a single file to
   check the bounds on arr() and arrp() calls
   if defined here can remove from specific C files by defining
   ARRAY_NO_CHECK (because some of our finest code
                   relies on abuse of arr!) YUCK!!!!!!!
*/

/* #define ARRAY_CHECK */

typedef struct ArrayStruct
  { char* base ;    /* char* since need to do pointer arithmetic in bytes */
    int   dim ;     /* length of alloc'ed space */
    int   size ;
    int   max ;     /* largest element accessed via array() */
    int   id ;      /* unique identifier */
    int   magic ;
  } *Array ;
 
    /* NB we need the full definition for arr() for macros to work
       do not use it in user programs - it is private.
    */

#define ARRAY_MAGIC 8918274
#define STACK_MAGIC 8918275
#define   ASS_MAGIC 8918276

#if !defined(MEM_DEBUG)
  Array   uArrayCreate (int n, int size, STORE_HANDLE handle) ;
  void    arrayExtend (Array a, int n) ;
  Array   arrayCopy (Array a) ;
#else
  Array   uArrayCreate_dbg (int n, int size, STORE_HANDLE handle,
			    const char *hfname,int hlineno) ;
  void    arrayExtend_dbg (Array a, int n, const char *hfname,int hlineno) ;
  Array	arrayCopy_dbg(Array a, const char *hfname,int hlineno) ; 
#define uArrayCreate(n, s, h) uArrayCreate_dbg(n, s, h, __FILE__, __LINE__)
#define arrayExtend(a, n ) arrayExtend_dbg(a, n, __FILE__, __LINE__)
#define arrayCopy(a) arrayCopy_dbg(a, __FILE__, __LINE__)
#endif

Array   uArrayReCreate (Array a,int n, int size) ;
void    uArrayDestroy (Array a);
char    *uArray (Array a, int index) ;
char    *uArrCheck (Array a, int index) ;
char    *uArrayCheck (Array a, int index) ;
#define arrayCreate(n,type)	uArrayCreate(n,sizeof(type), 0)
#define arrayHandleCreate(n,type,handle) uArrayCreate(n, sizeof(type), handle)
#define arrayReCreate(a,n,type)	uArrayReCreate(a,n,sizeof(type))
#define arrayDestroy(x)		((x) ? uArrayDestroy(x), x=0, TRUE : FALSE)

#if (defined(ARRAY_CHECK) && !defined(ARRAY_NO_CHECK))
#define arrp(ar,i,type)	((type*)uArrCheck(ar,i))
#define arr(ar,i,type)	(*(type*)uArrCheck(ar,i))
#define arrayp(ar,i,type)	((type*)uArrayCheck(ar,i))
#define array(ar,i,type)	(*(type*)uArrayCheck(ar,i))
#else
#define arr(ar,i,type)	((*(type*)((ar)->base + (i)*(ar)->size)))
#define arrp(ar,i,type)	(((type*)((ar)->base + (i)*(ar)->size)))
#define arrayp(ar,i,type)	((type*)uArray(ar,i))
#define array(ar,i,type)	(*(type*)uArray(ar,i))
#endif /* ARRAY_CHECK */

            /* only use arr() when there is no danger of needing expansion */
Array   arrayTruncatedCopy (Array a, int x1, int x2) ;
void    arrayStatus (int *nmadep,int* nusedp, int *memAllocp, int *memUsedp) ;
int     arrayReportMark (void) ; /* returns current array number */
void    arrayReport (int j) ;	/* write stderr about all arrays since j */
#define arrayMax(ar)            ((ar)->max)
#define arrayForceFeed(ar,j) (uArray(ar,j), (ar)->max = (j))
#define arrayExists(ar)		((ar) && (ar)->magic == ARRAY_MAGIC ? (ar)->id : 0 ) 
            /* JTM's package to hold sorted arrays of ANY TYPE */
BOOL    arrayInsert(Array a, void * s, int (*order)(void*, void*));
BOOL    arrayRemove(Array a, void * s, int (*order)(void*, void*));
void    arraySort(Array a, int (*order)(void*, void*)) ;
void    arraySortPos (Array a, int pos, int (*order)(void*, void*));
void    arrayCompress(Array a) ;
BOOL    arrayFind(Array a, void *s, int *ip, int (*order)(void*, void*));
BOOL    arrayIsEntry(Array a, int i, void *s);
 
/************** Stack package **************/
 
typedef struct StackStruct      /* assumes objects <= 16 bytes long */
  { Array a ;
    int magic ;
    char* ptr ;         /* current end pointer */
    char* pos ;         /* potential internal pointer */

    char* safe ;        /* need to extend beyond here */
    BOOL  textOnly; /* If this is set, don't align the stack.
		       This (1) save space (esp on ALPHA) and
		       (2) provides stacks which can be stored and got
		       safely between architectures. Once you've set this,
		       using stackTextOnly() only pushText, popText, etc, 
		       no other types. */   
  } *Stack ;
 
        /* as with ArrayStruct, the user should NEVER access StackStruct
           members directly - only through the subroutines/macros
        */
#if !defined(MEM_DEBUG)
  Stack   stackHandleCreate (int n, STORE_HANDLE handle) ;
#else
  Stack   stackHandleCreate_dbg (int n, STORE_HANDLE handle,
				 const char *hfname,int hlineno) ;
#define stackHandleCreate(n, h) stackHandleCreate_dbg(n, h, __FILE__, __LINE__)
#endif

#define stackCreate(n) stackHandleCreate(n, 0)
Stack   stackReCreate (Stack s, int n) ;
Stack   stackCopy (Stack, STORE_HANDLE handle) ;
void    stackTextOnly(Stack s);
void    uStackDestroy (Stack s);
#define stackDestroy(x)	 ((x) ? uStackDestroy(x), (x)=0, TRUE : FALSE)
void    stackExtend (Stack s, int n) ;
void    stackClear (Stack s) ;
#define stackEmpty(stk)  ((stk)->ptr <= (stk)->a->base)
#define stackExists(stk) ((stk) && (stk)->magic == STACK_MAGIC ? arrayExists((stk)->a) : 0)


/* Stack alignment: we use two strategies: the smallest type we push is
   a short, so if the required alignment is to 2 byte boundaries, we 
   push each type to its size, and alignments are kept.

   Otherwise, we push each type to STACK_ALIGNMENT, this ensures 
   alignment but can waste space. On machines with 32 bits ints and
   pointers, we make satck alignment 4 bytes, and do the consequent unaligned
   access to doubles by steam.

   Characters and strings are aligned separately to STACK_ALIGNMENT.
*/ 
   

#if (STACK_ALIGNMENT<=2)
#define push(stk,x,type) ((stk)->ptr < (stk)->safe ? \
                           ( *(type *)((stk)->ptr) = (x) , (stk)->ptr += sizeof(type)) : \
			    (stackExtend (stk,16), \
			     *(type *)((stk)->ptr) = (x) , (stk)->ptr += sizeof(type)) )
#define pop(stk,type)    (  ((stk)->ptr -= sizeof(type)) >= (stk)->a->base ? \
			    *((type*)((stk)->ptr)) : \
                          (messcrash ("User stack underflow"), *((type*)0)) )
#define stackNext(stk,type) (*((type*)(  (stk)->pos += sizeof(type) )  - 1 )  )

#else

#define push(stk,x,type) ((stk)->ptr < (stk)->safe ? \
                           ( *(type *)((stk)->ptr) = (x) , (stk)->ptr += STACK_ALIGNMENT) : \
			    (stackExtend (stk,16), \
			     *(type *)((stk)->ptr) = (x) , (stk)->ptr += STACK_ALIGNMENT) )
#define pop(stk,type)    (  ((stk)->ptr -= STACK_ALIGNMENT) >= (stk)->a->base ? \
			    *((type*)((stk)->ptr)) : \
                          (messcrash ("User stack underflow"), *((type*)0)) )
#define stackNext(stk,type) (*((type*)(  ((stk)->pos += STACK_ALIGNMENT ) - \
                                             STACK_ALIGNMENT ))  )
#endif

#if STACK_DOUBLE_ALIGNMENT > STACK_ALIGNMENT
void ustackDoublePush(Stack stk, double x);
double ustackDoublePop(Stack stk);
double stackDoubleNext(Stack stk);
#define pushDouble(stk,x) ustackDoublePush(stk, x)
#define popDouble(stk) ustackDoublePop(stk)
#define stackDoubleNext(stk) ustackDoubleNext(stk) 
#else
#define pushDouble(stk,x) push(stk, x, double)
#define popDouble(stk) pop(stk, double)
#define stackDoubleNext(stk) stackNext(stk, double)
#endif  


void    pushText (Stack s, char *text) ;
char*   popText (Stack s) ;	/* returns last text and moves pointer before it */
void    catText (Stack s, char *text) ;  /* like strcat */
void	stackTokeniseTextOn(Stack s, char *text, char *delimiters) ; /* tokeniser */

int     stackMark (Stack s) ;              /* returns a mark of current ptr */
int     stackPos (Stack s) ;              /* returns a mark of current pos, useful with stackNextText */
void    stackCursor (Stack s, int mark) ;  /* sets ->pos to mark */
#define stackAtEnd(stk)     ((stk)->pos >= (stk)->ptr)
char*   stackNextText (Stack s) ;
 
#define stackText(stk,mark) ((char*)((stk)->a->base + (mark)))
#define stackTextForceFeed(stk,j) (arrayForceFeed((stk)->a,j) ,\
                 (stk)->ptr = (stk)->pos = (stk)->a->base + (j) ,\
                 (stk)->safe = (stk)->a->base + (stk)->a->dim - 16 )
void    catBinary (Stack s, char* data, int size) ;
 
/********** Line breaking package **********/
 
int     uLinesText (char *text, int width) ;
char    *uNextLine (char *text) ;
char    *uPopLine (char *text) ;
char    **uBrokenLines (char *text, int width) ; /* array of lines */
char    *uBrokenText (char *text, int width) ; /* \n's intercalated */

/********** Associator package *************/

typedef struct AssStruct
  { int magic ;                 /* Ass_MAGIC */
    int id ;                    /* unique identifier */
    int n ;			/* number of items stored */
    int m ;			/* power of 2 = size of arrays - 1 */
    int i ;                     /* Utility state */
    void **in,**out ;
    unsigned int mask ;		/* m-1 */
  } *Associator ; 
 
#define assExists(a) ((a) && (a)->magic == ASS_MAGIC ? (a)->id : 0 )

#if !defined(MEM_DEBUG)
  Associator assHandleCreate (STORE_HANDLE handle) ;
  Associator assBigCreate (int size) ;
#else
  Associator assHandleCreate_dbg (STORE_HANDLE handle,
				 const char *hfname, int hlineno) ;
  Associator assBigCreate_dbg (int size, const char *hfname, int hlineno) ;
#define assHandleCreate(h) assHandleCreate_dbg(h, __FILE__, __LINE__)
#define assBigCreate(s) assBigCreate_dbg(s, __FILE__, __LINE__)
#endif

#define assCreate() assHandleCreate(0)
Associator assReCreate (Associator a) ;
void    uAssDestroy (Associator a) ;
#define assDestroy(x)  ((x) ? uAssDestroy(x), x = 0, TRUE : FALSE)
BOOL    uAssFind (Associator a, void* xin, void* *pout) ;
BOOL    uAssFindNext(Associator a, void* xin, void * *pout);
#define assFind(ax,xin,pout)    uAssFind((ax),(xin),(void**)(pout))
            /* if found, updates *pout and returns TRUE, else returns FALSE */
#define assFindNext(ax,xin,pout) uAssFindNext((ax),(xin),(void**)(pout))
BOOL    assInsert (Associator a, void* xin, void* xout) ;
            /* if already there returns FALSE, else inserts and returns TRUE */
void    assMultipleInsert(Associator a, void* xin, void* xout);
           /* allow multiple Insertions */
BOOL    assRemove (Associator a, void* xin) ;
            /* if found, removes entry and returns TRUE, else returns FALSE */
BOOL    assPairRemove (Associator a, void* xin, void* xout) ;
            /* remove only if both fit */
void    assDump (Associator a) ;
           /* for debug - uses printf */
void    assClear (Associator a) ;
BOOL    uAssNext (Associator a, void* *pin, void* *pout) ;
#define assNext(ax,pin,pout)	uAssNext((ax),(void**)(pin),(void**)pout)
/* convert an integer to a void * without generating a compiler warning */
#define assVoid(i) ((void *)(((char *)0) + (i))) 
#define assInt(v) ((int)(((char *)v) - ((char *)0)))

#endif /* defined(DEF_ARRAY_H) */

/**************************** End of File ******************************/

 
