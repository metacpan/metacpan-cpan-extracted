/*  File: dict.c
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1995
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: 
 * Exported functions:
 * HISTORY:
 * Last edited: Sep 16 23:43 1997 (rd)
 * Created: Tue Jan 17 17:33:44 1995 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: dict.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "dict.h"

/************* standard utility from Jean *************/

static int hashString (char *cp, int n, BOOL isDiff)
{
  register int i ;
  register unsigned int j, x = 0 ;
  register int rotate = isDiff ? 21 : 13 ;
  register int leftover = 8*sizeof(int) - rotate ;

  while (*cp)
    x = freeupper (*cp++) ^ (( x >> leftover) | (x << rotate)) ; 

				/* compress down to n bits */
  for (j = x, i = n ; i < sizeof(int) ; i += n)
    j ^= (x >> i) ;
  j &= (1 << n) - 1 ;

  if (isDiff)			/* return odd number */
    j |= 1 ;

  return j ;
}

#ifdef DAZ
static int hashString (char *cp, int n, BOOL isDiff)
{
  register int x;
  register int mask = (1 << n) - 1 ;

  x = 0;
  if (isDiff)	
    { for (;*cp;*cp++) { x = ((x * 5) + *cp) & mask ; }
      x |= 1 ;                   /* return odd number */
    }
  else
    for (;*cp;*cp++) { x = ((x * 3) + *cp) & mask ; }

  return x ;
}
#endif

/******************************************************/

static void dictFinalise (void *x) ;

DICT *dictHandleCreate (int size, STORE_HANDLE handle)
{
  DICT *dict = (DICT*) halloc (sizeof (DICT), handle) ;

  blockSetFinalise (dict, dictFinalise) ;
  for (dict->dim = 6, dict->max = 64 ; 
       dict->max < size ; 
       ++dict->dim, dict->max *= 2) ;
  dict->table = arrayCreate (dict->max, int) ;
  array (dict->table, dict->max-1, int) = 0 ;	/* set arrayMax */
  dict->names = arrayCreate (dict->dim/4, int) ;
  array(dict->names, 0, int) = 0 ;		/* IMPORTANT - dummy 0 entry */
  dict->nameText = stackCreate (dict->dim) ;
  return dict ;
}

DICT *dictCreate (int size) { return dictHandleCreate (size, 0) ; }
void uDictDestroy (DICT *dict) { messfree (dict) ; }

static void dictFinalise (void *x) /* does the work */
{
  DICT *dict = (DICT*)x ;

  arrayDestroy (dict->table) ;
  arrayDestroy (dict->names) ;
  stackDestroy (dict->nameText) ;
}

DICT *dictCopy (DICT *dict)
{
  DICT *new ;

  if (!dict)
    return 0 ;
  new = (DICT*) messalloc (sizeof (DICT)) ;
  new->table = arrayCopy (dict->table) ;
  new->names = arrayCopy (dict->names) ;
  new->nameText = stackCopy (dict->nameText, 0) ;
  new->dim = dict->dim ;
  new->max = dict->max ;
  return new ;
}

/**********************************************/

static int newPos ;		/* local for dictAdd, dictReHash */

BOOL dictFind (DICT *dict, char *s, int *ip)
{
  register int i, h, dh = 0 ;

  if (!dict || !s)
    return FALSE ;

  h = hashString (s, dict->dim, FALSE) ;
  
  while (TRUE)
    { i = arr(dict->table, h, int) ;
      if (!i)			/* empty slot, s is unknown */
	{ newPos = h ;
	  return FALSE ;
	}
      if (!strcmp (s, stackText(dict->nameText, arr(dict->names, i, int))))
	{ if (ip) 
	    *ip = i-1 ;
	  return TRUE ;
	}
      if (!dh)
	dh = hashString (s, dict->dim, TRUE) ;
      h += dh ;
      if (h >= dict->max)
	h -= dict->max ;
    }
}

/*****************/

static void dictReHash (DICT *dict, int newDim)
{
  int i ;

  if (newDim <= dict->dim)
    return ;
  dict->dim = newDim ;
  dict->max = 1 << newDim ;
				/* remake the table */
  arrayDestroy (dict->table) ;
  dict->table = arrayCreate (dict->max, int) ;
  array (dict->table, dict->max-1, int) = 0 ;	/* set arrayMax */

				/* reinsert all the names */
  for (i = 1 ; i < arrayMax(dict->names) ; ++i)
    { dictFind (dict, stackText(dict->nameText, arr(dict->names, i, int)), 0) ;
				/* will fail, but sets newPos */
      arr(dict->table, newPos, int) = i ;
    }
}

/****************/

BOOL dictAdd (DICT *dict, char *s, int *ip)
      /* always fills ip, returns TRUE if added, FALSE if known */
{
  int i ;

  if (!dict || !s)
    return FALSE ;

  if (dictFind (dict, s, ip))	/* word already known */
    return FALSE ;

  i = arrayMax(dict->names) ;
  arr (dict->table, newPos, int) = i ;
  array (dict->names, i, int) = stackMark(dict->nameText) ;
  pushText (dict->nameText, s) ;

  if (arrayMax(dict->names) > 0.4 * dict->max)
    dictReHash (dict, dict->dim+1) ;

  if (ip)
    *ip = i-1 ;
  return TRUE ;
}

/********************** utilities ***********************/

char *dictName (DICT *dict, int i)
{
  if (i < 0 || ++i >= arrayMax(dict->names))
    messcrash ("Call to dictName() out of bounds: %d %d", i-1, dictMax(dict)) ;

  return stackText (dict->nameText, arr(dict->names, i, int)) ;
}

int dictMax (DICT *dict)
{
  return arrayMax(dict->names) - 1 ;
}

/******************** end of file **********************/

 
 
 
 
