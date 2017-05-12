/*  File: texthelp.c
 *  Author: Friedemann Wobus (fw@sanger.ac.uk)
 *          and contributions from Darren Platt (daz@sanger.ac.uk)
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description:
     contains contains the code to display an HTML page as plain text
     Basic formatting is observed, but images and links are stripped.

 * Exported functions:
 **      helpPrint(char *helpFilename);
 * HISTORY:
 * Last edited: Dec  4 14:33 1998 (fw)
 * * Oct  8 16:01 1998 (fw): removed the declaration of 
			helpOn and help for #define MACINTOSH
 * * Aug 20 16:10 1998 (rd): removed refernces to old help-system
 * * Aug 18 17:17 1998 (fw): help-system split into 
		w1/helpsubs.c  (helpDir, HTML stuff etc).
		w1/texthelp.c  (non-graphical help for tace)
		w2/graphhelp.c (graphical help for xace,image etc.)
 * ----------------------------------------------------------------------
 * ---- major rework, these revision don't necessarily 
 * ---- affect code still left in this file
 * ----------------------------------------------------------------------
 * * May  2 01:07 1996 (rd): new implementation of 
                       helpMakeIndex() using filDirectory()
 * * May  2 18:24 1996 (mieg):
         fall back on oldhelp
         callMosaic if (http:)
         use freeout for server
         jaime's file name rotation
         remaining problem: help topic in tace should be case-insensitive
 * * May  1 18:24 1996 (fw): fixed freePage() to avoid mem leaks
 * * Apr 30 16:18 1996 (fw): fixed #ifdef NON_GRAPHICs for tace
 * * Apr 30 16:18 1996 (fw): added image dictionary
 * * Apr 29 12:37 1996 (fw): added handling of <DL> lists
 * * Apr 25 16:27 1996 (fw): added <IMG > tag
 * * Apr 22 17:43 1996 (fw): changed help system to HTML browser
 * Created: Thu Feb 20 14:49:50 1992 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: texthelp.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef MACINTOSH
/********************************************************************/
#include "help_.h"
#include "freeout.h"
/********************************************************************/
static void htmlPagePrint (HtmlPage *page);
static void printTextSection (HtmlNode *node);

/********************************************************************/
static char buf[10000] ;	/* text-buffer for wordwrapping */

/********************************************************************/

static float xPos ;
static int indent ;
static int WINX ;


/* dumps out help-page without images and markups */
UTIL_FUNC_DEF BOOL helpPrint (char *helpFilename)
/* returns TRUE if a help page could successfully be displayed
   for the given subject, returns FALSE if no such page found */
{
  HtmlPage *page ;
  Array dirList;
  char *cp;
  int i,n,x;

 if ((page = htmlPageCreate (helpFilename)))
   {
     /* found a page */
     htmlPagePrint (page);
     
     htmlPageDestroy (page);

     return TRUE;
   }

  if (!helpFilename)
    freeOut ("Help subject not found\n");
  else
    freeOut ("Help subject is ambiguous\n");

  freeOut ("Try:\n  help\n");
      
  /* now show a list of possible files */
  if(!(dirList = filDirectoryCreate
       (helpGetDir(), HELP_FILE_EXTENSION, "r")) )
    {
      messout ("Can't open help directory %s\n"
	       "(%s)",
	       helpGetDir(), messSysErrorText()) ;
      return FALSE ;
    }
  
  for (i = 0, x = 0 ; i < arrayMax(dirList) ; i++)
    {
      cp = arr(dirList,i,char*) ;
      if (!cp || !*cp || !strlen(cp))
	continue ;
      if (helpFilename)
	{
	  if (strncasecmp(filGetFilename(helpFilename),cp,
			  strlen(filGetFilename(helpFilename))) != 0)
	    continue;
	}

      n = strlen(cp) ;
      if (n > 5 && !strcmp("."HELP_FILE_EXTENSION,cp + n - 5))
	*(cp + n - 5) = 0 ; 

      x += n + 1 ;
      if (x > 50) { x = n + 1 ; freeOut("\n") ;}
      freeOutf("%s  ", cp) ;
    }
  freeOut("\n") ;

  filDirectoryDestroy (dirList);

  return FALSE;
} /* helpPrint */


/************************************************************/
/* counter-part to graphWebBrowser(), which remote-controls 
   netscape using the -remote command line option. Useful
   for textual applications running in an X11 environment,
   where x-apps can be called from within the application,
   but the Xtoolkit (used to drive netscape via X-atoms)
   shouldn't be linked in, because it is a textual app. */
/************************************************************/
UTIL_FUNC_DEF BOOL  helpWebBrowser(char *link)
{
  /* currently impossible, because it is hard to find out whether
     a netscape process is already running.
     Stupidly enough 'netscape -remote...' doesn't exit
     with code 1, if it can't connect to an existing process
*/
  return FALSE;
} /* helpWebBrowser */





/************************************************************/
/******************                   ***********************/
/****************** static functions  ***********************/
/******************                   ***********************/
/************************************************************/


static void htmlPagePrint (HtmlPage *page)
{
  /* init screen-position parameters */

  WINX = 80 ;
  indent = 2 ;
  xPos = indent ;

  /* start recursivle printing nodes */
  printTextSection (page->root) ;

  return;
} /* htmlPagePrint */
/************************************************************/


static void newTextLine (void)
{
  int i ;
  
/*  if (xPos != indent)*/
    {
      freeOut("\n") ;
      for (i = 0; i < indent; ++i) freeOut (" ") ;
      xPos = indent ;
    }
} /* newLine */
/************************************************************/

static void blankTextLine (void)
{
  int i ;

  freeOut("\n") ;
  for (i = 0; i < indent; ++i) freeOut (" ") ;
  xPos = indent ;

  newTextLine () ;
} /* newLine */
/************************************************************/

static void printTextSection (HtmlNode *node)
/* part specific to the text-help system, which uses freeOut
   to print arsed HTML as plain text */
{
  int i, len ;
  char *cp, *start ;
  static BOOL 
    MODE_PREFORMAT=FALSE, 
    MODE_HREF=FALSE,
    MODE_HEADER=FALSE, 
    FOUND_NOBULLET_IN_LIST_NOINDENT=FALSE ;
  static int itemNumber ;
  static char *currentLink ;

  switch (node->type)
    {
    case HTML_SECTION:
      printTextSection (node->left) ;
      if (node->right) printTextSection (node->right) ;
      break ;
    case HTML_COMMENT:
      /* do nothing */
      break ;
    case HTML_DOC:
    case HTML_HEAD:
    case HTML_BODY:
      if (node->left) printTextSection (node->left) ;
      break ;
    case HTML_TITLE:
      for (i = 0; i < strlen(node->text)+4; ++i)
	freeOutf ("*") ;
      freeOutf ("\n* %s *\n", node->text) ;
      for (i = 0; i < strlen(node->text)+4; ++i)
	freeOutf ("*") ;
      blankTextLine() ;
      break ;
    case HTML_HEADER:
      {
	MODE_HEADER = TRUE ;

	indent = node->hlevel*2 ;

	blankTextLine () ;
	
	/* check, in case some bozo has done a thing like <H1></H1> */
	if (node->left) printTextSection (node->left) ; 

	freeOutf ("\n") ;
	for (i = 0; i < xPos; ++i)
	  {
	    if (i < indent) freeOutf (" ") ;
	    else  freeOutf ("*") ;
	  }

	blankTextLine () ;
	
	MODE_HEADER = FALSE ;
      }
      break ;

    case HTML_LIST:
      if (node->lstyle == HTML_LIST_BULLET || 
	  node->lstyle == HTML_LIST_NUMBER)
	indent += 2 ;
      else if (node->lstyle == HTML_LIST_NOINDENT)
	indent -= 2 ;
      newTextLine () ;

      itemNumber = 0 ;

      /* a list might not have a leftnode (a list item) */
      if (node->left) printTextSection (node->left) ;

      if (node->lstyle == HTML_LIST_BULLET || 
	  node->lstyle == HTML_LIST_NUMBER)
	indent -= 2 ;
      else if (node->lstyle == HTML_LIST_NOINDENT)
	indent += 2 ;
      if (node->lstyle == HTML_LIST_NOINDENT &&
	  FOUND_NOBULLET_IN_LIST_NOINDENT)
	{
	  indent -= 4 ;
	  FOUND_NOBULLET_IN_LIST_NOINDENT = FALSE ;
	}

      blankTextLine () ;
      break ;

    case HTML_LISTITEM:
      ++itemNumber ;
      if (node->left)
	{
	  if (node->lstyle == HTML_LIST_NOINDENT_NOBULLET)
	    {
	      /* if we are in a <DL> list and went to indentation
		 because of a <DD> item, a <DT> item brings back
		 the old indent-level (noindent for <DL>'s) */
	      if (FOUND_NOBULLET_IN_LIST_NOINDENT)
		{
		  indent -= 6 ;
		  FOUND_NOBULLET_IN_LIST_NOINDENT = FALSE ;
		  newTextLine () ;
		  freeOutf ("  ") ;
		}
	    }
	  else
	    newTextLine () ;
	  if (node->lstyle == HTML_LIST_BULLET ||
	      node->lstyle == HTML_LIST_NOINDENT)
	    {
	      freeOutf ("* ") ;
	      indent += 2 ;
	      xPos  = indent ;
	    }
	  else if (node->lstyle == HTML_LIST_NUMBER)
	    {
	      freeOutf ("%d. ", itemNumber) ;
	      indent += strlen(messprintf ("%d. ", itemNumber)) ;
	      xPos  = indent ;
	    }
	  else if (node->lstyle == HTML_LIST_NOBULLET)
	    {
	      /* part of a <DL> noindented list, but a <DD>
		 item becomes indented, but no bullet */
	      /* if we come across the first NO_BULLET item, in
		 a LIST_NOINDENT, the LIST becomes indented */
	      if (!FOUND_NOBULLET_IN_LIST_NOINDENT)
		{
		  indent += 6 ;
		  xPos = indent ;
		  freeOutf ("      ") ;
		  fflush (stdout) ;

		  FOUND_NOBULLET_IN_LIST_NOINDENT = TRUE ;
		}
	    }
	  printTextSection (node->left) ;
	}
      if (node->lstyle == HTML_LIST_BULLET ||
	  node->lstyle == HTML_LIST_NOINDENT)
	{
	  indent -= 2 ;
	}
      else if (node->lstyle == HTML_LIST_NUMBER)
	{
	  indent -= strlen(messprintf ("%d. ", itemNumber)) ;
	}
      else if (node->lstyle == HTML_LIST_NOBULLET)
	{
	  if (!FOUND_NOBULLET_IN_LIST_NOINDENT)
	    indent -= 6 ;
	}
      
      if (node->right)
	{
	  printTextSection (node->right) ;
	}
      break ;

    case HTML_HREF:
      if (node->link)
	{
	  MODE_HREF = TRUE ;
	  currentLink = node->link ;
	}
      /* we have to check for leftnode, in case we have a thing
	 like <A HREF=...></A>. The HREF-node doesn't have a TEXT
	 node attached, and it would crash otherwise */
      if (node->left)printTextSection (node->left) ; 

      if (node->link)
	{
	  MODE_HREF = FALSE ;
	  currentLink = 0 ;
	}
      break ;
    case HTML_TEXT:
      cp = node->text ;
      if (!MODE_PREFORMAT)
	stripSpaces (node->text) ;
      /* for MODE_PREFORMAT keeps all controls chars */

      while (*cp)
	{
	  len = 0 ;
	  start = cp ;
	  
	  if (!MODE_PREFORMAT)
	    {
	      while (*cp && !isspace((int)*cp)) { ++(cp) ; ++len ; }
	      if (*cp) ++cp ;	/* skip whitespace */
	    }
	  else
	    {
	      while (*cp && *cp != '\n') { ++(cp) ; ++len ; }
	      if (*cp) 
		{
		  ++cp ;	/* skip RETURN */
		  ++len ;	/* so we copy the RETURN into buf */
		}
	    }

	  memset (buf, 0, 10000) ;
	  strncpy (buf, start, len) ;
	  buf[len] = 0 ;

	  /* linewrapping of words/lines longer than WINX */
	  if (strlen(buf) > WINX)
	    {
	      cp = start + (int)(WINX) ;
	      buf[(int)WINX] = 0 ;
	      len = (int)WINX ;
	    }
	  
	  /* word wrapping if not in preformatting mode */
	  if (!MODE_PREFORMAT)
	    {
	      if (xPos != indent)  /* not at start of line ... */
		{
		  xPos += 1 ;	   /* ... one space before the word */
		  freeOutf (" ") ;
		  fflush (stdout) ;
		}
	      if (xPos + len > WINX)
		{
		  newTextLine () ;
		}
	      freeOutf ("%s", buf) ;
	      xPos += strlen(buf) ; /* place xPos at the end of word */
	    }
	  else if (MODE_PREFORMAT)
	    {
	      int oldpos, stringpos, screenpos, ii ;
	      i = 0 ;

	      /* replace TABs with appropriate number of spaces */
	      while (buf[i])
		{
		  if (buf[i] == '\t')
		    {
		      /* oldpos is the position, that this TAB char
			 would go on the screen without TABifying
			 NOTE: xPos is always at least "indent" 
			 (to leave a left margin) */
		      oldpos = (xPos - indent) + i ;

		       /* screenpos is the position of the TAB char 
			  after inserting spaces
			  NOTE: the TAB itself will be
			  overwritten by one space */
		      screenpos = (((oldpos/8)+1)*8) - 1 ;

		       /* stringpos is where the TAB should go
			  in the string, where it'll turn into a space
			  at that position */
		      stringpos = screenpos - (xPos-indent) ;

		      /* shift all text from current position "i"
			 onwards */
		      for (ii = strlen(buf)-1; ii >= i ; --ii)
			buf[ii+(stringpos-i)] = buf[ii] ;

		      /* fill gap with spaces and also overwrite TAB
			 with a space */
		      for (ii = i; ii <= stringpos; ++ii)
			buf[ii] = ' ' ;

		      i = stringpos ;
		    }
		  ++i ;
		}

      /* don't use len, it might have changed when inserting spaces */
	      if (buf[strlen(buf)-1] == '\n')
		{
		  buf[strlen(buf)-1] = 0 ;
		  freeOutf ("%s", buf) ;
		  xPos += strlen(buf) ;
		  newTextLine ();	/* for the '\n' */
		}
	      else
		{
		  freeOutf ("%s", buf) ;
		  xPos += strlen(buf) ;
		}
	    }
	}
      break ;
    case HTML_GIFIMAGE:
      {
	freeOutf (" [IMAGE] ") ;
	xPos += 9 ;
      }
      break ;
    case HTML_NOIMAGE:
      break ;
    case HTML_RULER:
      {
	newTextLine () ;
	for (i = indent; i < WINX; ++i)
	  freeOutf ("-") ;
	xPos = WINX ;
	newTextLine () ;
      }
      break ;
    case HTML_PARAGRAPH:
      blankTextLine () ;
      break ;
    case HTML_LINEBREAK:
      newTextLine () ;
      break ;
    case HTML_BOLD_STYLE:
    case HTML_STRONG_STYLE:
      {
	if (node->left)	printTextSection (node->left) ;
      }
      break ;
    case HTML_ITALIC_STYLE:
      {
	if (node->left) printTextSection (node->left) ;
      }
      break ;
    case HTML_CODE_STYLE:
      {
	if (node->left)	printTextSection (node->left) ;
      }
      break ;
    case HTML_STARTBLOCKQUOTE:
      newTextLine () ;
      indent += 3 ;
      xPos = indent ;
      for (i = 0; i < indent; ++i) freeOutf (" ") ;
      fflush (stdout) ;
      break ;
    case HTML_ENDBLOCKQUOTE:
      indent -= 3 ;
      blankTextLine () ;
      break ;
    case HTML_STARTPREFORMAT:
      MODE_PREFORMAT = TRUE ;
      newTextLine () ;
      break ;
    case HTML_ENDPREFORMAT:
      MODE_PREFORMAT = FALSE ;
      break ;
    case HTML_UNKNOWN:
      break;			/* compiler happiness */
    }
} /* printTextSection */
/************************************************************/

#endif /* !def MACINTOSH */
 
 
 
 
