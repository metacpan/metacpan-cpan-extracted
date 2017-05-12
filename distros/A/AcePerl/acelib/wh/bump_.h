/*  File: bump_.h
 *  Author: Fred Wobus (fw@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (Sanger Centre, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@crbm.cnrs-mop.fr
 *
 * Description: private header for the internals of the BUMP-package
 * Exported functions:  none
 *              completion of the BUMP structure to allow
 *              the inside if the BUMP-package to access the members
 *              of the structure.
 * HISTORY:
 * Last edited: Dec 17 16:20 1998 (fw)
 * Created: Thu Dec 17 16:17:32 1998 (fw)
 *-------------------------------------------------------------------
 */


#ifndef DEF_BUMP__H
#define DEF_BUMP__H

#include "bump.h"		/* include public header */

/* allow verification of a BUMP pointer */
extern magic_t BUMP_MAGIC;

/* completion of public opaque type as declared in bump.h */

struct BumpStruct {
  magic_t *magic ;		/* == &BUMP_MAGIC */
  int n ;         /* max x, i.e. number of columns */
  float *bottom ; /* array of largest y in each column */
  int minSpace ;  /* longest loop in y */
  float sloppy ;
  float maxDy ;  /* If !doIt && maxDy !=0,  Do not add further down */
  int max ;      /* largest x used (maxX <= n) */
  int xAscii, xGapAscii ;
  float yAscii ;
} ;

#endif /* DEF_BUMP_H */
