/*  File: help.h
 *  Author: Fred Wobus (fw@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * SCCS: %W% %G%
 * Description: part of the utility-library that handles the
          on-line help package.
	  The system works on the basis that all help files are HTML
	  documents contained in one directory. Depending on
	  what display function is registered, they can be shown
	  as text, using the built-in simple browser or even
	  dispatched to an external browser.
 * Exported functions: see below
 * HISTORY:
 * Last edited: Oct 23 12:19 1998 (fw)
 * Created: Thu Oct  8 14:01:07 1998 (fw)
 *-------------------------------------------------------------------
 */

#ifndef _HELP_H
#define _HELP_H

#include "regular.h"		/* basic header for util-lib */

/************** public routines of the help-package *******************/

UTIL_FUNC_DCL BOOL helpOn (char *subject);
/* displays help on the given subject.  Dispatches to registered
   display function. defaults to helpPrint (text-help) */

UTIL_FUNC_DCL QueryRoutine helpOnRegister (QueryRoutine func);
/* register any func to display help-page, the functions
   are >> BOOL func (char *filename) <<, where the filename
   is a *full* pathname to an HTML document that is to be shown */

UTIL_FUNC_DCL char *helpSetDir (char *dirname);
/* set the /whelp/ dir if possible, returns path to it */

UTIL_FUNC_DCL char *helpGetDir (void);
/* find the /whelp/ dir if possible, returns pointer to path
   If called for the first time without prior helpSetDir(),
   it will try to init to whelp/, but return 0 if it is not
   accessible*/


UTIL_FUNC_DCL BOOL  helpPrint (char *helpFilename);
/* dump helpfile as text - default for helpOn, 
   if helpOnRegister wasn't called to change it. */

UTIL_FUNC_DCL BOOL  helpWebBrowser(char *link);
/* counter-part to graphWebBrowser(), which remote-controls 
   netscape using the -remote command line option. Useful
   for textual applications running in an X11 environment,
   where x-apps can be called from within the applcation,
   but the Xtoolkit (used to drive netscape via X-atoms)
   shoiuldn't be linked in, because it is a textual app. */


UTIL_FUNC_DCL char *helpSubjectGetFilename (char *subject);
/* Returns the complete file name of the html help
     file for a given subject. 
   Returns ? if subject was ? to signal, 
     that a dynamically created index
     or some kind of help should be displayed.
   Returns NULL of no helpfile is available. */

UTIL_FUNC_DCL char *helpLinkGetFilename (char *link_href);
/* given a relative link in a page it returns the full
   pathname to the file that is being linked to.
   The pointer returned belongs to an internal static copy
   that is reused every tjis function is called */

#endif /* !def _HELP_H */
