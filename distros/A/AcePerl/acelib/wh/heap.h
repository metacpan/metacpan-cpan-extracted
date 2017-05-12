/*  File: heap.h
 *  Author: Richard Durbin (rd@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: header file for heap package
 * Exported functions:
 * HISTORY:
 * Last edited: Feb  6 00:20 1993 (mieg)
 * Created: Sat Oct 12 21:30:43 1991 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: heap.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef HEAP_INTERNAL
typedef void* Heap ;
#endif

Heap heapCreate (int size) ;
void heapDestroy (Heap heap) ;
int  heapInsert (Heap heap, float score) ;
int  heapExtract (Heap heap, float *sp) ;

/* end of file */
