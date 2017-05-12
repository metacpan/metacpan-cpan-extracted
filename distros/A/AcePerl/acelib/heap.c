/*  File: heap.c
 *  Author: Richard Durbin (rd@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: supports maximising heaps with a float score.
 * Exported functions:  heapCreate, heapDestroy,
 			heapInsert, heapExtract
			keySetAlphaHeap
 * HISTORY:
 * Last edited: Jul  8 15:05 1998 (il)
 * * Nov 12 20:12 1991 (mieg): i add here my own keySetAlphaHeap
 it is probably equivalent to your code, i did not verify, but
 our 2 files were in w1, although i never saw your file before today,
 i must have killed it by mistake.
 * Created: Sat Oct 12 20:02:41 1991 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: heap.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "regular.h"

/* Package to manage a heap - keeps the max largest entries inserted.
   Top of tree (1) is smallest of these.  Daughters of each node must be
   larger.  Tree is kept balanced at all times, so daughters of n are
   implicit 2n and 2n+1.
   Insert returns 0 if not inserted, else an index in the range [1..max]
   that the user can use to associate extra data to the item.
   Extract returns that index for the SMALLEST item in the heap, or 0 if 
   the heap is empty.
*/

typedef struct heapStruct
  { float   *scores ;
    int     *index ;
    int     max ;
    int     n ;
    int     magic ;
  } *Heap ;

#define HEAP_INTERNAL
#include "heap.h"

#define HEAPMAGIC 897237

/************************************/

Heap heapCreate (int size)
{
  Heap heap = (Heap) messalloc (sizeof (struct heapStruct)) ;

  if (size <= 0)
    messcrash ("heapCreate called with non-positive arg %d", size) ;
    
  heap->magic = HEAPMAGIC ;
  heap->max = size ;
  heap->n = 0 ;
  heap->scores = (float*) messalloc (size * sizeof(float)) ;
  heap->index = (int*) messalloc (size * sizeof(int)) ;

  return heap ;
}

/***************/

void heapDestroy (Heap heap) /* mhmp 11.12 .98 */
{
  if (!heap)
    return ;
  if (heap->magic != HEAPMAGIC)
    messcrash ("heapDestroy received corrupt heap->magic");   
  heap->magic = 0 ;
  if (heap->scores && *heap->scores)
    messfree (heap->scores) ;
  if (heap->index && *heap->index)
    messfree (heap->index) ;
  messfree (heap) ;

}

/*************************************/

static int filterDown (Heap heap, int n, float score)
{				/* return final position */
  int n2 = n*2 ;

  while (n2 <= heap->n)
    { if (n2 < heap->n && 
	  heap->scores[n2+1] < heap->scores[n2])
	++n2 ;
      if (score < heap->scores[n2])
	break ;
      heap->scores[n] = heap->scores[n2] ;
      heap->index[n] = heap->index[n2] ;
      n = n2 ; n2 = n*2 ;
    }

  heap->scores[n] = score ;
  return n ;
}

/**************************************/

static int filterUp (Heap heap, int n, float score)
{				/* return final position */
  int n2 = n/2 ;

  while (n > 1 && score < heap->scores[n2])
    { heap->scores[n] = heap->scores[n2] ;
      heap->index[n] = heap->index[n2] ;
      n = n2 ; n2 = n/2 ;
    }
  return filterDown (heap, n, score) ;	/* must check down other branch */
}

/**************************************/

int heapInsert (Heap heap, float score)
{
  int n, ind ;

  if (!heap || heap->magic != HEAPMAGIC)
    messcrash ("Bad heap passed to heapInsert") ;

  if (heap->n < heap->max)
    { heap->scores[++heap->n] = score ;
      n = filterUp (heap, heap->n, score) ;
      return (heap->index[n] = heap->n) ;
    }
  else if (heap->scores[1] < score)
    { heap->scores[1] = score ;
      ind = heap->index[1] ;
      n = filterDown (heap, 1, score) ;
      return (heap->index[n] = ind) ;
    }
  else
    return 0 ;
}

/*************************************/

int heapExtract (Heap heap, float *sp)
{
  int n, ind ;

  if (!heap || heap->magic != HEAPMAGIC)
    messcrash ("Bad heap passed to heapExtract") ;

  if (!heap->n)
    return 0 ;

  *sp = heap->scores[1] ;
  ind = heap->index[1] ;
  heap->scores[1] = heap->scores[heap->n] ;
  --heap->n ;
  n = filterDown (heap, 1, heap->scores[1]) ;
  heap->index[n] = heap->index[heap->n + 1] ; /* new resting place */
  return ind ;
}

/*****************************************************/
/********** main() for test program ******************/

/****** commented out *******

static float scores[] = { 1, 9, 27, 8, 19, 4, 23, 2, 6, 12, 23, 7} ;

void main (void)
{
  float score ;
  int i ;
  Heap heap = heapCreate(4) ;

  for (i = 0 ; i < 12 ; ++i)
    if (heapInsert (heap, scores[i]))
      printf ("Inserted %f\n", scores[i]) ;
    else
      printf ("  failed %f\n", scores[i]) ;

  printf ("\n") ;
  while (heapExtract (heap, &score))
    printf ("Extracted %f\n", score) ;

  heapDestroy (heap) ;
}
****************************/
/**************************************************************************/
/**************************************************************************/
