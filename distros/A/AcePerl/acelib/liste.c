/*  File: liste.c
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
     Liste listeCreate (STORE_HANDLE hh) ;
     listeDestroy(_ll) 
     listeMax(_ll) 
     int listeFind (Liste liste, void *vp)  ;
     int listeAdd (Liste liste, void *vp) ;
     void listeRemove (Liste liste, void *vp, int i)  ;

 * HISTORY:
 * Last edited: Nov 23 11:21 1998 (fw)
 * Created: oct 97 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: liste.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "liste.h"

/* A liste is a list of void*
 * It is less costly than an associator if
 * the things in it are transient
 * because in an associator, you cannot easilly destroy
 * The liste does NOT check for doubles.
 */

static int LISTEMAGIC = 0 ;

static void listeFinalize(void *vp)
{
 
  /* I found that handleFinalise will free this memory
     with the 'free(unit)' call anyway (see memsubs.c:228)
     so we don't need to free it here in the finalization
     no memory leaks detected by purify as a result */
  /*  if (liste && liste->magic == &LISTEMAGIC)
    {
      arrayDestroy(liste->a) ;
      liste->magic = 0 ;
    }
    */
}

Liste listeCreate (STORE_HANDLE hh)
{
  Liste liste = (Liste)  halloc(sizeof(struct listeStruct), hh) ;
  
  liste->magic = &LISTEMAGIC ;
  liste->i = 1 ;
  liste->a = arrayHandleCreate (32, void*, hh) ;
  blockSetFinalise(liste,listeFinalize) ;
  array (liste->a,0,void*) = 0 ; /* avoid zero */
  return liste ;
}

void listeRemove (Liste liste, void *vp, int i) 
{
  Array a = liste->a ;
  void *wp = array(a, i, void*) ;

  if (vp != wp) messcrash ("Confusion in listeRemove") ;
  array (a,i,void*) = 0 ;
  if (i < liste->i)
    liste->i = i ;
}
  
int listeAdd (Liste liste, void *vp) 
{
  Array a = liste->a ;
  int i = liste->i ;
  void **vpp = arrayp(a, i, void*) ;
  int n = arrayMax(a) ;  /* comes after arrayp of above line ! */
  while (*vpp && i++ < n) vpp++ ;
  array (a,i,void*) = vp ;
  return i ;
}
  
int listeFind (Liste liste, void *vp) 
{
  Array a = liste->a ;
  int i = arrayMax (liste->a) ;
  void **vpp = arrayp(a, i - 1, void*) + 1 ;
  
  while (vpp--, i--)
    if (vp == *vpp) return i ;
  return 0 ;
}
  
/******************** end of file **********************/

 
 
