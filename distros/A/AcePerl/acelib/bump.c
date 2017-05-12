/*  File: bump.c
 *  Author: Jean Thierry-Mieg (mieg@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1992
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description:
 **  Bumper (Cambridge traditional folklore)
 * Exported functions:
 **  bumpCreate, bumpDestroy
 **  bumpItem, bumpText, bumpTest, bumpAdd
 **  the  BUMP structure is defined in wh/bump.h
 * HISTORY:
 * Last edited: Dec 21 13:58 1998 (fw)
 * Created: Thu Aug 20 10:34:55 1992 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: bump.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "regular.h"

#include "bump.h"
#include "bump_.h"

/************************************************************/

magic_t BUMP_MAGIC = "BUMP";

#define MINBUMP  ((float)(-2000000000.0))

/************* bump package based on gmap text **************/

BUMP bumpCreate (int nCol, int minSpace)
{
  int i ;
  BUMP bump;

  bump = (BUMP) messalloc (sizeof (struct BumpStruct)) ;
  bump->magic = &BUMP_MAGIC ;

  if (nCol < 1)
    nCol = 1 ;
  bump->n = nCol ;
  bump->bottom = (float*) messalloc (nCol*sizeof (float)) ;
  for (i = 0 ; i < nCol ; ++i)
    bump->bottom[i] = MINBUMP ;
  if (minSpace < 0)
    minSpace = 0 ;
  bump->minSpace = minSpace ;
  bump->sloppy = 0 ;
  bump->max = 0 ;
  return bump ;
}

BUMP bumpReCreate (BUMP bump, int nCol, int minSpace)
{ int i ;
    
  if (!bump)
    return bumpCreate(nCol, minSpace) ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpReCreate received corrupt bump->magic");

  if (nCol < 1)
    nCol = 1 ;
  if (nCol != bump->n)
    {  messfree (bump->bottom) ;
       bump->bottom = (float*) messalloc (nCol*sizeof (float)) ;
       bump->n = nCol ;
     }
    
  for (i = 0 ; i < nCol ; ++i)
    bump->bottom[i] = MINBUMP ;
  if (minSpace < 0)
    minSpace = 0 ;
  bump->minSpace = minSpace ;
  bump->sloppy = 0 ;
  bump->max = 0 ;
  
  return bump ;
} /* bumpReCreate */

void bumpDestroy (BUMP bump)
{
  if (!bump)
    return ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpDestroy received corrupt bump->magic");

  messfree (bump->bottom) ;
  messfree (bump) ;
} /* bumpDestroy */

int bumpMax (BUMP bump)
{
  if (!bump)
    return 0 ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpMax received corrupt bump->magic");

  return bump->max ;
} /* bumpMax */

float bumpSetSloppy( BUMP bump, float sloppy)
{ float old ;

  if (!bump)
    messcrash ("bumpSetSloppy received NULL bump");

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpSetSloppy received corrupt bump->magic");

  old = bump->sloppy;
  bump->sloppy = sloppy ;
  return old ;
}

/*
void bumpText(BUMP bump, char *cp, float *x, float *y) 
{ CHECKBUMP ;

  if (!cp || !*cp)
    return ;
  bumpItem(bump, strlen(cp), 1, &xs, &ys) ;
}
*/
void bumpRegister (BUMP bump, int wid, float height, int *px, float *py)
{ 
  int i = *px , j ;

  if (!bump)
     messcrash ("bumpRegister received NULL bump");

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpRegister received corrupt bump->magic");

  j = wid < bump->n ? wid : bump->n;


  if (bump->max < i + j - 1) 
    bump->max = i + j - 1 ;
  while (j--)	/* advance bump */
    bump->bottom[i+j] = *py + height ;
}

/* mhmp 16/05/97 */
void asciiBumpItem (BUMP bump, int wid, float height, 
                                 int *px, float *py)
                                /* works by resetting x, y */
{
  int x = *px ;
  float ynew, y = *py ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("asciiBumpItem received corrupt bump->magic");

  if (bump->xAscii != 0)
    {
      if (bump->xAscii + wid + bump->xGapAscii > bump->n)
	{
	  ynew = y + 1 ; 
	  x = 0 ;
	  bump->xAscii = wid ;
	}
      else
	{
	  ynew = y ;
	  x = bump->xAscii + bump->xGapAscii ;
	  bump->xAscii = x + wid ;
	}
    }
  else
    {
      if (x + wid > bump->n)
	{
	  if ((y - bump->yAscii) < 1 && (int) y == (int) bump->yAscii)
	    ynew = y + 1 ;  
	  else
	    ynew = y ; 
	  x = 0 ;
	  bump->xAscii = wid ;
	}
      else
	{
	  if (y != bump->yAscii && (int) y == (int) bump->yAscii)
	    ynew = y + 1 ; 
	  else
	    ynew = y ;
	}
    }
  *px = x ;
  *py = ynew ;
  bump->yAscii = ynew ;
}
  			 
BOOL bumpAdd (BUMP bump, int wid, float height, 
	      int *px, float *py, BOOL doIt)
     /* works by resetting x, y */
{
  int i, j ;
  int x = *px ;
  float ynew, y = *py ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpAdd received corrupt bump->magic");

  if (x + wid + bump->minSpace > bump->n)
    x = bump->n - wid - bump->minSpace ;
  if (x < 0) 
    x = 0 ;
  if (wid > bump->n)		/* prevent infinite loops */
    wid = bump->n ;
  if (y <= MINBUMP)
    y = MINBUMP + 1 ;

  ynew = y ;

  while (TRUE)
    { for (i = x, j = wid ; i < bump->n ; ++i)	/* always start at x */
	{ if (bump->bottom[i] > y + bump->sloppy)
	    { j = wid ;
              ynew = y ; /* this line was missing in the old code */
            }
	  else 
	    { if (bump->bottom[i] > ynew)
		ynew = bump->bottom[i] ;
	      if (!--j)		/* have found a gap */
		break ;
	    }

	}
      if (!j)	
	{ 
	  if (doIt)
	    {
	      for (j = 0 ; j < wid ; j++)	/* advance bump */
		bump->bottom[i - j] = ynew+height ;
	      if (bump->max < i + 1) 
		bump->max = i + 1 ;
	    }
	  *px = i - wid + 1 ;
	  *py = ynew ;
	  return TRUE ;
	}
      y += 1 ;	/* try next row down */
      if (!doIt && bump->maxDy && y - *py > bump->maxDy)
	return FALSE ;
    }
}

/* abbreviate text, if vertical bump exceeds dy 
   return accepted length 
*/


int bumpText (BUMP bump, char *text, int *px, float *py, float dy, BOOL vertical)
{ 
  int w, n, x = *px;  
  float y = *py, h, old = bump->maxDy ;

  if (bump->magic != &BUMP_MAGIC)
    messcrash ("bumpText received corrupt bump->magic");

  if (!text || !*text) return 0 ;
  n = strlen(text) ;
  bump->maxDy = dy ;
  while (TRUE)
    {
      x = *px ; y = *py ; /* try always from desired position */
      if (vertical)  /*like in the genetic map */
	{ w = n + 1 ; h = 1 ;}
      else           /* like in pmap */
	{ w = 1 ; h = n + 1 ;}  
      if (bumpAdd (bump, w, h, &x, &y, FALSE))
	{ /* success */
	  bump->maxDy = old ;
	  bumpRegister(bump, w, h, &x, &y) ;
	  *px = x ; *py = y ;
	  return n ;
	}

      if (n > 7)
	{ n = 7 ; continue ; }
      if (n > 3)
	{ bump->maxDy = 2 * dy ; n = 3 ; continue ; }
      if (n > 1)
	{ bump->maxDy = 3 * dy ; n = 1 ; continue ; }
      bump->maxDy = old ;
      return 0 ; /* failure */
    } 
}

/**************************************************/
/**************************************************/
 
