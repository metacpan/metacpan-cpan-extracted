/*  File: liste.h
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1995
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: 
     You can add and remove from a liste in a loop
     without making the list grow larger then the max current nimber
     this is more economic than hashing, where removing is inneficient
     and faster than an ordered set

     This library will not check for doubles,
      i.e. it maintains a list, not a set.
 * Exported functions:
 * HISTORY:
 * Last edited: Dec  4 14:45 1998 (fw)
 * Created: oct 97 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: liste.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */
#ifndef LISTE_H
#define LISTE_H

#include "regular.h"

	/* The LISTE structure is private
	   DO NOT LOOK AT OR TOUCH IT IN CLIENT CODE!!
	   Only use it via the subroutine interface.
	*/

typedef struct listeStruct {
  void *magic ;
  int i ;     /* probably lowest empty slot */
  Array a ;   /* the actual liste */
} * Liste ;

Liste listeCreate (STORE_HANDLE hh) ;

#define listeDestroy(_ll) ((_ll) ? messfree(_ll) , _ll = 0, TRUE : FALSE)

#define listeMax(_ll) (arrayMax((_ll)->a) - 1)

int listeFind (Liste liste, void *vp)  ;
int listeAdd (Liste liste, void *vp) ;
void listeRemove (Liste liste, void *vp, int i)  ;


#endif /* ndef LISTE_H */
/******* end of file ********/
 
