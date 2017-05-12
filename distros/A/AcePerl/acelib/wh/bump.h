/*  File: bump.h
 *  Author: Jean Thierry-Mieg (mieg@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1992
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description:
 * Exported functions:
 * HISTORY:
 * Last edited: Dec 17 16:05 1998 (fw)
 * Created: Thu Aug 20 10:42:03 1992 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: bump.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef DEF_BUMP_H
#define DEF_BUMP_H

/* forward declaration of opaque type */
typedef struct BumpStruct *BUMP;

BUMP bumpCreate (int ncol, int minSpace) ;
BUMP bumpReCreate (BUMP bump, int ncol, int minSpace) ;
void bumpDestroy (BUMP bump) ;
float bumpSetSloppy( BUMP bump, float sloppy) ;

/* Bumper works by resetting x,y
   bumpItem inserts and fills the bumper
   bumpTest restes x,y, but does not fill bumper
     this allows to reconsider the wisdom of bumping
   bumpRegister (called after bumpTest) fills 
     Test+Register == Add 
   bumpText returns number of letters that
     can be bumped without *py moving more than 3*dy  
*/

#define bumpItem(_b,_w,_h,_px,_py) bumpAdd(_b,_w,_h,_px,_py,TRUE)
#define bumpTest(_b,_w,_h,_px,_py) bumpAdd(_b,_w,_h,_px,_py,FALSE)
			
BOOL bumpAdd (BUMP bump, int wid, float height, int *px, float *py, BOOL doIt);
void bumpRegister (BUMP bump, int wid, float height, int *px, float *py) ;
int bumpText (BUMP bump, char *text, int *px, float *py, float dy, BOOL vertical) ;
int bumpMax(BUMP bump) ;
void asciiBumpItem (BUMP bump, int wid, float height, 
                                 int *px, float *py) ;
                                /* works by resetting x, y */


#endif /* DEF_BUMP_H */
