/*  File: version.h
 *  Author: Ed Griffiths (edgrif@mrc-lmba.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmba.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@crbm1.cnusc.fr
 *
 * Description: Declares functions in the new acedb_version module.
 *              These functions allow the retrieval of various parts
 *              of the current acedb version number or string.
 * Exported functions: See descriptions below.
 * HISTORY:
 * Last edited: Dec  3 14:58 1998 (edgrif)
 * * Dec  3 14:39 1998 (edgrif): Changed the interface to fit in with
 *              libace.
 * Created: Wed Apr 29 13:46:41 1998 (edgrif)
 *-------------------------------------------------------------------
 */


#ifndef ACE_VERSION_H
#define ACE_VERSION_H


/* Use this set of functions to return the individual parts of the ACEDB release numbers,  */
/* including version number, release number, update letter and build date/time.            */
int aceGetVersion(void) ;
int aceGetRelease(void) ;
char *aceGetUpdate(void) ;
char *aceGetLinkDate(void) ;

/* Use this set of functions to return standard format string versions of the ACEDB        */
/* release version and build date.                                                         */
/* Version string is in the form:                                                          */
/*      "ACEDB Version  <version>_<release><update>"  e.g.  "ACEDB Version 4_6d"           */
/*                                                                                         */
/* LinkDate string is in the form:                                                         */
/*      "compiled on: __DATE__ __TIME__"  e.g.    "compiled on: Dec  3 1998 13:59:07"      */
/*                                                                                         */
char *aceGetVersionString(void) ;
char *aceGetLinkDateString(void) ;


#endif	/* end of ACE_VERSION_H */
