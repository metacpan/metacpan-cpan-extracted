/*  File: dict.h
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1995
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: public header for cut-out lex package in dict.c
 * Exported functions:
 * HISTORY:
 * Last edited: Dec  4 14:50 1998 (fw)
 * Created: Tue Jan 17 17:34:44 1995 (rd)
 *-------------------------------------------------------------------
 */

/* @(#)dict.h	1.4 9/16/97 */
#ifndef DICT_H
#define DICT_H

#include "regular.h"

	/* The DICT structure is private to lexhash.c
	   DO NOT LOOK AT OR TOUCH IT IN CLIENT CODE!!
	   Only use it via the subroutine interface.
	*/

typedef struct {
  int dim ;
  int max ;
  Array table ;			/* hash table */
  Array names ;			/* mark in text Stack per name */
  Stack nameText ;		/* holds names themselves */
} DICT ;

DICT *dictCreate (int size) ;
DICT *dictHandleCreate (int size, STORE_HANDLE handle) ;
void uDictDestroy (DICT *dict) ;
#define dictDestroy(_dict) {uDictDestroy(_dict) ; _dict=0;}
BOOL dictFind (DICT *dict, char *s, int *ip) ;
BOOL dictAdd (DICT *dict, char *s, int *ip) ;
char *dictName (DICT *dict, int i) ;
int dictMax (DICT *dict) ;		/* 1 + highest index = number of names */
DICT *dictCopy (DICT *dict) ;

#endif /* ndef DICT_H */
/******* end of file ********/
 
 
