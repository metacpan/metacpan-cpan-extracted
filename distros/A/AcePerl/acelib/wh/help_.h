/*  File: helpsubs_.h
 *  Author: Fred Wobus (fw@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * SCCS: %W% %G%
 * Description: private headerfile for the help-system.
 * Exported functions: none
 * HISTORY:
 * Last edited: Dec  4 14:35 1998 (fw)
 * * Oct  8 14:15 1998 (fw): renamed from helpsubs_.h to help_.h
 * * Oct  8 11:35 1998 (fw): introduced macro for HELP_FILE_EXTENSION
 * Created: Tue Aug 18 17:38:27 1998 (fw)
 *-------------------------------------------------------------------
 */

#ifndef _HELP__H
#define _HELP__H

#include "help.h"

#include <ctype.h>		/* for isspace etc.. */

/************************************************************/

#define HELP_FILE_EXTENSION "html"

/* forward declaration of struct type */
typedef struct HtmlPageStruct HtmlPage;
typedef struct HtmlNodeStruct HtmlNode;

/************************************************************/
/********** routines shared by the help-package *************/

HtmlPage *htmlPageCreate (char *helpFilename);
/* parse the HTML page for the given file */

HtmlPage *htmlPageCreateFromFile (FILE *fil);
/* parse the HTML source from an opened file */

void htmlPageDestroy (HtmlPage *page);
/* clear all memory taken up by the page */

void stripSpaces (char *cp);
/* utility : remove whitespaces from free text in non-<PRE> mode */


/************************************************************/

typedef enum { 
  HTML_SECTION=1, 
  HTML_COMMENT, 
  HTML_DOC, 
  HTML_BODY, 
  HTML_HEAD,
  HTML_TITLE, 
  HTML_HEADER, 
  HTML_TEXT, 
  HTML_HREF, 
  HTML_RULER, 
  HTML_LINEBREAK, 
  HTML_PARAGRAPH, 
  HTML_LIST, 
  HTML_LISTITEM, 
  HTML_GIFIMAGE,
  HTML_BOLD_STYLE, 
  HTML_STRONG_STYLE, 
  HTML_ITALIC_STYLE, 
  HTML_CODE_STYLE,
  HTML_STARTPREFORMAT, 
  HTML_ENDPREFORMAT,
  HTML_STARTBLOCKQUOTE, 
  HTML_ENDBLOCKQUOTE,
  HTML_UNKNOWN, 
  HTML_NOIMAGE 
} HtmlNodeType ;
 
typedef enum {
  HTML_LIST_BULLET=1, 
  HTML_LIST_NUMBER, 
  HTML_LIST_NOINDENT, 
  HTML_LIST_NOBULLET, 
  HTML_LIST_NOINDENT_NOBULLET
} HtmlListType ;
/* a <UL> node and its <LI> items are LIST_BULLET
   a <OL> node and its <LI> items are LIST_NUMBER
   a <DL> node is LIST_NOINDENT,
               its <LI> node are also LIST_NOINDENT
               but <DD> items are LIST_NOBULLET
	       and <DT> items are LIST_NOINDENT_NOBULLET
*/

/************************************************************/


struct HtmlNodeStruct {
  HtmlNodeType type ;
  HtmlNode *left, *right ;
  char *text ;
  char *link ;
  int hlevel ;
  HtmlListType lstyle ;
  BOOL isNameRef ;
};


struct HtmlPageStruct {
  char *htmlText;		/* source text */
  HtmlNode *root;		/* root node of parsetree */
  STORE_HANDLE handle;
};


#endif /* !def _HELP__H */
