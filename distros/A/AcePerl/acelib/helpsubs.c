/*  File: helpsubs.c
 *  Author: Fred Wobus (fw@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * SCCS: %W% %G%
 * Description: controls the help system, provides HTML parsing
 * Exported functions:
 * HISTORY:
 * Last edited: Dec  4 14:30 1998 (fw)
 * * Oct 12 12:27 1998 (fw): checkSubject now case-insensitive
 * * Oct  8 17:23 1998 (fw): removed warning, in case that 
    an open-list tag (e.g. <UL> was directly followed by a close-list
    tag (e.g. </UL>). The warning tried to enforce that 
    every type of list only has a certain type of items.
 * * Oct  8 11:36 1998 (fw): helpSubjectGetFilename takes over logic 
           from readHelpfile to locate the file containing the
	   help for a particular subject
 * Created: Tue Aug 18 16:11:07 1998 (fw)
 *-------------------------------------------------------------------
 */

#include "help_.h"

/************************************************************/
static char     *makeHtmlIndex (STORE_HANDLE handle);
static char     *makeHtmlImagePage (char *link, STORE_HANDLE handle);
static HtmlNode *parseHtmlText (char *text, STORE_HANDLE handle);
static BOOL      parseSection  (char **cp, HtmlNode **resultnode, 
				STORE_HANDLE handle);
/************************************************************/


/************ directory where help files are stored *********/
static char helpDir[MAXPATHLEN] = "" ;


/************************************************************/
/* function to register the helpOnRoutine
   This can be called at any stage (before the first helpOn,
   or later on, it will affect the system next time helpOn
   is called. */
/************************************************************/
static QueryRoutine helpOnRoutine = 0;
UTIL_FUNC_DEF QueryRoutine helpOnRegister (QueryRoutine func)
/* call with func = 0x0 just to check whether 
   anything has been registered yet */
{
  QueryRoutine old = helpOnRoutine ; 

  if (func) 
    helpOnRoutine = func ; 

  return old ;
}



/************************************************************/
/* Sets the helpDir;  */
/************************************************************/
UTIL_FUNC_DEF char *helpSetDir (char *dirname)
{
  if (dirname)
    {
      strcpy (helpDir, dirname);

      if (filName (dirname,0,"rd"))
	return (char*)&helpDir[0];
      else
	return (char*)0;
    }
  else
    {      
      strcpy (helpDir, filGetFullPath ("whelp"));
      
      if (filName (helpDir, 0, "rd"))
	return (char*)&helpDir[0];
    }

  return (char*)0;
} /* helpGetDir */



/************************************************************/
/* return the current helpDirectory or 
   initialise if not previously set */
UTIL_FUNC_DEF char *helpGetDir (void)
{
  if (!*helpDir)
    return (helpSetDir(0)) ;

  return (char*)&helpDir[0];
} /* helpGetDir */



/************************************************************/
/* pop up help on the given subject, depending on the registered
   display function, that will be textual, in the built-in
   simple HTML browser or even launch an external browser
   to display the help document */
/************************************************************/
UTIL_FUNC_DEF BOOL helpOn (char *subject)
{
  char *helpFilename;

  if (!helpGetDir() || !filName(helpGetDir(), "", "rd"))
    {
      messout ("Sorry, No help available ! "
	       "Could not open the HTML help directory "
	       "%s\n"
	       "(%s)",
	       helpGetDir(),
	       messSysErrorText());
      
      return FALSE;
    }
  
  helpFilename = helpSubjectGetFilename(subject);
  /* may be NULL if file could not be found,
     the registered helpOnRoutine has to cope
     with this case and may decide to display an 
     index instead */
  
  if (helpOnRoutine)
    return ((*helpOnRoutine)(helpFilename));


  return (helpPrint (helpFilename)); /* textual help as default */
} /* helpOn */
/************************************************************/


UTIL_FUNC_DEF char *helpSubjectGetFilename (char *subject)
/* this function attempts to find the file name corresponding
   to a particular help-subject.
   It will attempt to find a matching file according to
   the current settings of helpDir and HELP_FILE_EXTENSION.
   
   the subject '?' will just return ? again. This is a special
   code within the help system to tell the help display
   function that the user required some kind of help.
   Usually the helpOnRegister'd function would display a
   dynamically created index of the help-directory.

   this function can be even cleverer by doing keyword searches
   on <TITLE> and <H1> strings in files that might be relevant
   of no obvious match is found.
*/
{
  static char filename_array[MAXPATHLEN] = "";
  char *filename = &filename_array[0];
  char *subject_copy;
  Array dirList;

  if (subject == NULL) 
    return NULL;

  if (strlen(subject) == 0) 
    return NULL;

  if (strcmp(subject, "?") == 0)
    {
      /* return ? to signal that the calling 
	 function needs to display a dynamically
	 created index or show some kind of help. 
       */
      /* if the construct
	 page = htmlPageCreate(helpGetFilename(subject_requested));
	 is used, the resulting page will therefor be a marked up
	 directory listing of helpsubjects
       */
      strcpy (filename, "?");
      return filename;
    }

  subject_copy = strnew (subject, 0);

  strcpy (filename, "");	/* intialise, if this is
				   non-empty at the end of the loop,
				   we found a matching helpfile */
  while (TRUE)
    {
      /* simple attempt to locate file - path/helpDir/subject.html */
      sprintf(filename, "%s%s%s.%s", 
	      filGetFullPath(helpGetDir()),
	      SUBDIR_DELIMITER_STR,
	      subject_copy, HELP_FILE_EXTENSION);

      if (filName(filename, 0, "r"))
	break;

      /* advanced attempt, try to find a matching file from
	 the list of available ones by scanning the directory
	 contents of the helpdirectory */
      if ((dirList = filDirectoryCreate
	   (helpGetDir(), HELP_FILE_EXTENSION, "r")) )
	{
	  int i;
	  int matches;
	  char *s;
	  
	  /* first look for an exact case-insensitive match */
	  strcpy (filename, "");
	  for (i = 0 ; i < arrayMax(dirList) ; i++)
	    {
	      s = arr(dirList,i,char*);
	      
	      if (strcasecmp (s, subject_copy) == 0)
		{
		  sprintf(filename, "%s%s%s.%s", 
			  filGetFullPath(helpGetDir()),
			  SUBDIR_DELIMITER_STR,
			  s, HELP_FILE_EXTENSION);
		  if (filName(filename, 0, "r"))
		    break;	/* exit for-loop */

		  strcpy (filename, "");
		}
	    }

	  if (strlen(filename) > 0)
	    break;		/* exit while(true) loop */

	  /* count the number of filenames starting with the
	     given subject string */
	  matches = 0;
	  for (i = 0 ; i < arrayMax(dirList) ; i++)
	    {
	      s = arr(dirList,i,char*);
	      
	      if (strncasecmp (s, subject_copy, 
			       strlen(subject_copy)) == 0)
		{
		  sprintf(filename, "%s%s%s.%s", 
			  filGetFullPath(helpGetDir()),
			  SUBDIR_DELIMITER_STR,
			  s, HELP_FILE_EXTENSION);
		  ++matches;
		}
	    }

	  if (matches == 0)
	    {
	      strcpy (filename, ""); /* not found */
	    }
	  else if (matches == 1)
	    {
	      /* the one exact match (already in filename string)
		 is the complete filename */
	      if (filName(filename, 0, "r"))
		break;		/* exit while(true) loop */
	    }
	  else if (matches > 1)
	    {
	      /* construct a filename that we know won't work.
		 But it may be used by the help display
		 function to give a meaningful message
		 to say that this subject is ambiguos.
		 The returned filename is then considered
		 a template, similar to 'ls subject*'
		 so the help-display function may give a list 
		 of possible matching subjects. */

	      sprintf(filename, "%s%s%s", 
		      filGetFullPath(helpGetDir()),
		      SUBDIR_DELIMITER_STR, subject_copy);
	      break;
	    }

	  filDirectoryDestroy (dirList);

	} /* endif dirList */

      /* file didn't exist, whichever way we tried so far,
	 so we try to chop off the last bit of the subject name.
	 In case trySubject was "Tree_Clone_Inside", we now
	 go through the look again with "Tree_Clone" and re-try. */

      if (strchr (subject_copy, '_'))
	{
	  int j;

	  j = strlen (subject_copy);
	  while (subject_copy[j--] != '_') ; /* find the last _ char */
	  subject_copy[j + 1] = '\0';
	}
      else
	{
	  /* If we run out of trailing components, then we exit
	   * anyway.
	   */
	  strcpy (filename, "");
	  break;		/* exit while(true)loop */
	}
    } /* end-while(true) */

  messfree (subject_copy);


  if (strcmp(filename, "") != 0)
    return filename;		/* success */

  if ((strcasecmp(subject, "index") == 0) ||
      (strcasecmp(subject, "home") == 0) ||
      (strcasecmp(subject, "toc") == 0))
    {
      /* we asked for some kind of index-page but couldn't find it,
	 so we can always try to return the question mark '?'
	 which will ask the calling function to display a
	 dynamically created index of help-subjects. */

      strcpy (filename, "?");
      return filename;
    }


  return NULL;			/* failure - no file found */
} /* helpSubjectGetFilename */


/************************************************************/
/* helpPackage utility to find out the filename of a given
   link reference. Absolute filenames are returned unchanged,
   but relative filenames are expanded to be the full path
   of the helpfile. Can be used for html/gif files referred to
   by the HREF of anchor tags or the SRC or IMG tags */

/* NOTE: the pointer returned is a static copy, which is
   re-used everytime it is called. If the calling function
   wants to mess about with the returned string, a copy
   has to be made.
   NULL is returned if the resulting file can't be opened.
   the calling function can inspect the result of
   messSysErrorText(), the report the resaon for failure */
/************************************************************/
UTIL_FUNC_DEF char *helpLinkGetFilename (char *link)
{
  static char link_path_array[MAXPATHLEN] = "";
  char *link_path = &link_path_array[0];

  if (link[0] == SUBDIR_DELIMITER) /* absolute path (UNIX) */
    {
      strcpy (link_path, link);
    }
  else				/* relative path */
    {
      strcpy (link_path, helpGetDir());
      strcat (link_path, SUBDIR_DELIMITER_STR);
      strcat (link_path, link);
    }

  if (filName(link_path, "", "r"))
    return link_path;

  return NULL;
} /* helpLinkGetFilename */


/************************************************************/
/******************                   ***********************/
/************** private helpPackage functions ***************/
/******************                   ***********************/
/************************************************************/


HtmlPage *htmlPageCreate (char *helpFilename)
/* complemeted by htmlPageDestroy */
{
  FILE *fil;
  HtmlPage *page = 0;

  if (!helpFilename)		/* we could get a NULL filename */
    return 0;                   /* here, which might come from
				   helpSubjectGetFilename() that couldn't
				   find a file matching the subject */

  /* create a page with a marked up directory listing */
  if (strcmp(helpFilename, "?") == 0)
    {
      page = messalloc (sizeof(HtmlPage));
      page->handle = handleCreate();
      page->htmlText = makeHtmlIndex(page->handle);
      if (!(page->root = parseHtmlText(page->htmlText, page->handle)))
	htmlPageDestroy(page);

      return page;
    }

  if (!(filName(helpFilename, "", "r")))
    return 0;			/* prevent error caused 
				   by unsucsessful filopen */


  /* create a page inlining the image */
  if (strcasecmp (helpFilename + (strlen(helpFilename)-4), ".gif") == 0)
    {
      page = messalloc (sizeof(HtmlPage));
      page->handle = handleCreate();
      page->htmlText = makeHtmlImagePage(helpFilename, page->handle);
      if (!(page->root = parseHtmlText(page->htmlText, page->handle)))
	htmlPageDestroy(page);

      return page;
    }


  /* assume HTML page */
  if ((fil = filopen(helpFilename, "", "r")))
    {
      page = htmlPageCreateFromFile (fil);
      filclose (fil);
    }

  return page;
} /* htmlPageCreate */
/************************************************************/

HtmlPage *htmlPageCreateFromFile (FILE *fil)
{
  HtmlPage *page;
  int fileSize;

  if (!fil)
    return (HtmlPage*)0;

  /* determine filesize */
  rewind (fil);
  fseek (fil, 0, SEEK_END);
  fileSize = ftell (fil);
  rewind (fil);
      
  if (fileSize == 0)
    return (HtmlPage*)0;
    
  /* if we have a positive fileSize, we are pretty much
     guaranteed, that we'll get some HTML text and a parsetree */

  page = messalloc (sizeof(HtmlPage));

  page->handle = handleCreate();

  /* grab the contents of the file */
  page->htmlText = halloc ((fileSize + 1) * sizeof(char), page->handle);
  fread (page->htmlText, sizeof (char), fileSize, fil);
  page->htmlText[fileSize] = '\0'; /* add string terminator */
      
  /* get parsetree */
  page->root = parseHtmlText(page->htmlText, page->handle);

  return page;
} /* htmlPageCreateFromFile */
/************************************************************/

void htmlPageDestroy (HtmlPage *page)
{
  if (!page) return;

  /* clear all memory used during parsing of the page */
  handleDestroy (page->handle);

  /* clear the memory taken up by the structure itself */
  messfree (page);

  return;
} /* htmlPageDestroy */
/************************************************************/

void stripSpaces (char *cp)
/* utility to get rid of multiple spaces from a string */
/* we use it on node->text, where the text isn't within <PRE> tags */
{
  char *s ;
  int i ;

   /* strip unwanted white spaces from the text */
  for (i = 0; i < strlen(cp); ++i)
    if (isspace ((int)cp[i])) cp[i] = ' ' ;

  while ((s = strstr (cp, "  ")))
    {
      s[1] = 0 ;
      strcat (cp, s+2) ;
    }
 
  if (cp[strlen(cp)-1] == ' ')
    cp[strlen(cp)-1] = '\0' ;

  return ;
} /* stripSpaces */



/************************************************************/
/******************                   ***********************/
/****************** static functions  ***********************/
/******************                   ***********************/
/************************************************************/




/************************************************************/
/* as the helpviewer supports inlined images, it is easy
   to display image, even when they're not inlined as in
   <A HREF=image.gif>click here for image</A>.
   We just return a container page, that inlines the image */
/************************************************************/
static char *makeHtmlImagePage (char *link, STORE_HANDLE handle)
{
  char *text;
  int len;

  len = 0;
  len = 7+6+strlen(filGetFilename(link))+8+10+strlen(link)+2;

  text = halloc((len+1)*sizeof(char), handle);

  sprintf (text,
	   "<TITLE>Image %s</TITLE>"
	   "<IMG SRC=\"%s\">", filGetFilename(link), link);

  text[len] = 0;

  return text;
} /* makeHtmlImagePage */



/************************************************************/
/* reads the directory of helpDir and constructs an HTML-page
   containing a <UL>-list of all HTML-files in helpDir */
/************************************************************/
static char *makeHtmlIndex (STORE_HANDLE handle)
{
  char *cp, *text, *s ;
  int i, len ;
  Array dirList;

  if(!(dirList = filDirectoryCreate
       (helpGetDir(), HELP_FILE_EXTENSION, "r")) )
    {
      messout ("Can't open help directory %s\n"
	       "(%s)",
	       helpDir, messSysErrorText()) ;

      return 0 ;
    }

  len = 0 ;

  /* determine the length of the text to be returned */
  len += 39+15+5+6 ;			/* for header */
  for (i = 0 ; i < arrayMax(dirList) ; i++)
    {
      s = arr(dirList,i,char*) ;
      len += strlen(s)*2 + strlen(HELP_FILE_EXTENSION) + 19;
      /* this is the length of each line as written 
	 to the string by sprintf(cp,"<LI>...") below */
    }

  text = (char*)halloc ((len+1) * sizeof(char), handle) ;
  cp = text ;

  sprintf (cp,
	   "<TITLE>Index of Help Directory</TITLE>\n"
	   "<H1>Index</H1>\n"
	   "<UL>\n") ;
  cp += 39+15+5 ;

  for (i = 0 ; i < arrayMax(dirList) ; i++)
    {
      s = arr(dirList, i, char*) ;
      sprintf (cp, "<LI><A HREF=%s.%s>%s</A>\n",
	       s, HELP_FILE_EXTENSION, s) ;
      cp += strlen(s)*2 + strlen(HELP_FILE_EXTENSION) + 19;
    }
  sprintf (cp, "</UL>\n") ;
  text[len] = 0 ;

  filDirectoryDestroy (dirList) ;

  return text ;
} /* makeHtmlIndex */
/************************************************************/




/*************************************************************
 *****************  HTML Parsing package *********************
 *** currently very crude parser, will fall over any bad  ****
 *** whether Mosaic, Netscape or MSIE can deal with or not. **
 ************************************************************/
 

static HtmlNode *parseHtmlText(char *text, STORE_HANDLE handle)
/* return root node of html parse-tree, 
   generated from the HTML source text */
{
  char *cp = text;
  HtmlNode *node;
  
  if (!text) return 0;

  /* start recursion */
  parseSection (&cp, &node, handle) ;

  return node;			/* return root-node */
} /* parseHtmlText */
/************************************************************/

static void skipSpaces (char **cp)
{
  while (**cp && isspace((int)**cp)) { ++(*cp) ; }
} /* skipSpaces */

/************************************************************/

static void replaceEscapeCodes (char *cp)
{
  char *s ;

/*
   quotation mark                       &#34;  --> "    &quot;   --> "
   ampersand                            &#38;  --> &    &amp;    --> &
   less-than sign                       &#60;  --> <    &lt;     --> <
   greater-than sign                    &#62;  --> >    &gt;     --> >
*/
  
  s = cp ;

  while (*s)
    {
      if (strncasecmp (s, "&#34;", 5) == 0)
	{
	  s[0] = '"' ; s[1] = 0 ;
	  strcat (s+1, s+5) ;
	}
      else if (strncasecmp (s, "&#38;", 5) == 0)
	{
	  s[0] = '&' ; s[1] = 0 ;
	  strcat (s+1, s+5) ;
	}
      else if (strncasecmp (s, "&#60;", 5) == 0)
	{
	  s[0] = '<' ; s[1] = 0 ;
	  strcat (s+1, s+5) ;
	}
      else if (strncasecmp (s, "&#62;", 5) == 0)
	{
	  s[0] = '>' ; s[1] = 0 ;
	  strcat (s+1, s+5) ;
	}
      else if (strncasecmp (s, "&quot;", 6) == 0)
	{
	  s[0] = '"' ; s[1] = 0 ;
	  strcat (s+1, s+6) ;
	}
      else if (strncasecmp (s, "&amp;", 5) == 0)
	{
	  s[0] = '&' ; s[1] = 0 ;
	  strcat (s+1, s+5) ;
	}
      else if (strncasecmp (s, "&lt;", 4) == 0)
	{
	  s[0] = '<' ; s[1] = 0 ;
	  strcat (s+1, s+4) ;
	}
      else if (strncasecmp (s, "&gt;", 4) == 0)
	{
	  s[0] = '>' ; s[1] = 0 ;
	  strcat (s+1, s+4) ;
	}
      else if (strncasecmp (s, "&nbsp;", 4) == 0)
	{
	  s[0] = ' ' ; s[1] = 0 ;
	  strcat (s+1, s+6) ;
	}

      ++s ;
    }
 
  return ;
} /* replaceEscapeCodes */
/************************************************************/

static HtmlNode *makeNode (HtmlNodeType type, STORE_HANDLE handle)
/* allocate a node and initialise the type */
{
  HtmlNode *newnode ;

  newnode = (HtmlNode*)halloc (sizeof(HtmlNode), handle) ;
  newnode->type = type ;

  return (newnode) ;
} /* makeNode */
/************************************************************/

static BOOL parseHtml (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 6 ;			/* skip <HTML> */

  skipSpaces (cp) ;

  node = makeNode (HTML_DOC, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : text inside <HTML> not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</HTML>", 7) == 0)
    {
      *cp += 7 ;
    }
  else
    {
      printf ("Warning : <HTML> tag not closed by </HTML> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseHtml */
/************************************************************/

static BOOL parseHead (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 6 ;			/* skip <HEAD> */

  skipSpaces (cp) ;

  node = makeNode (HTML_HEAD, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : HTML inside <head> not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</HEAD>", 7) == 0)
    {
      *cp += 7 ;
    }
  else
    {
      printf ("Warning : <HEAD> tag not closed by </HEAD> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseHead */
/************************************************************/

static BOOL parseBody (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 6 ;			/* skip <BODY> */

  skipSpaces (cp) ;

  node = makeNode (HTML_BODY, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : HTML inside <BODY> not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</BODY>", 7) == 0)
    {
      *cp += 7 ;
    }
  else
    {
      printf ("Warning : <BODY> tag not closed by </BODY> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseBody */
/************************************************************/

static BOOL parseComment (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node ;
  int len ;
  char *start ;

  *cp += 4 ;			/* skip <!-- */

  start = *cp ;
  while (**cp && **cp != '>') { ++(*cp) ; }
  
  if (!**cp)
    {
      *resultnode = 0 ;
      return FALSE ;
    }
  
  node = makeNode (HTML_COMMENT, handle) ;

  len = *cp-start ;

  ++(*cp) ;			/* skip '>' */

  node->text = (char*)halloc ((len+1) * sizeof(char), handle) ;
  
  strncpy (node->text, start, len) ;
  node->text[len] = 0 ;
  
  *resultnode = node ;

  return TRUE ;
} /* parseComment */
/************************************************************/

static BOOL parseTitle (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node ;
  int len, numspaces=0 ;
  char *start ;

  *cp += 7 ;			/* skip <TITLE> */

  skipSpaces (cp) ;

  start = *cp ;

  while (**cp)
    {
      if (strncasecmp (*cp, "</title>", 8) == 0)
	break ;
      if (isspace((int)**cp))
	++numspaces ;
      else
	numspaces = 0 ;
      ++(*cp) ;
    }
  
  node = makeNode (HTML_TITLE, handle) ;
  
  len = (*cp-start) - numspaces ;

  if (**cp)
    *cp += 8 ;

  node->text = (char*)halloc ((len+1) * sizeof(char), handle);
  
  strncpy (node->text, start, len) ;
  node->text[len] = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseTitle */
/************************************************************/

static BOOL parseHeader (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;
  int level ;

  level = (*cp)[2]-'0' ;

  *cp += 4 ;			/* skip <H?> */

  skipSpaces (cp) ;

  node = makeNode (HTML_HEADER, handle) ;
  node->hlevel = level ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : heading%d text not valid !!\n", level) ;
    }

  skipSpaces (cp) ;

  if ((strncasecmp (*cp, "</H", 3) == 0) &&
      (*cp)[3]-'0' == level && (*cp)[4] == '>')
    {
      *cp += 5 ;
    }
  else
    {
      printf ("Warning : <H%d> tag not closed by </H%d> !!\n", level, level) ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseHeader */
/************************************************************/

static BOOL parseCode (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 6 ;			/* skip <CODE> */

  skipSpaces (cp) ;

  node = makeNode (HTML_CODE_STYLE, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : <code> text not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</CODE>", 7) == 0)
    {
      *cp += 7 ;
    }
  else
    {
      printf ("Warning : <CODE> tag not closed by </CODE> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseCode */
/************************************************************/

static BOOL parseBold (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 3 ;			/* skip <B> */

  skipSpaces (cp) ;

  node = makeNode (HTML_BOLD_STYLE, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : HTML inside <B> not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</B>", 3) == 0)
    {
      *cp += 4 ;
    }
  else
    {
      printf ("Warning : <B> tag not closed by </B> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseBold */
/************************************************************/

static BOOL parseStrong (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 8 ;			/* skip <STRONG> */

  skipSpaces (cp) ;

  node = makeNode (HTML_STRONG_STYLE, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : strong text not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</STRONG>", 9) == 0)
    {
      *cp += 9 ;
    }
  else
    {
      printf ("Warning : <STRONG> tag not closed by </STRONG> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseStrong */
/************************************************************/

static BOOL parseItalic (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 3 ;			/* skip <I> */

  skipSpaces (cp) ;

  node = makeNode (HTML_ITALIC_STYLE, handle) ;

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : bold text not valid !!\n") ;
    }

  skipSpaces (cp) ;

  if (strncasecmp (*cp, "</I>", 3) == 0)
    {
      *cp += 4 ;
    }
  else
    {
      printf ("Warning : <I> tag not closed by </I> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseItalic */
/************************************************************/

static BOOL parseText (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node ;
  int len ;
  char *start ;

  start = *cp ;

  while (**cp)
    {
      /* read until beginning of new TAG */
      if (strncasecmp (*cp, "<", 1) == 0)
	break ;
      ++(*cp) ;
    }
  
  if (*cp == start)
    {
      /* an unknown tag had been reached, the text read until that
	 will be of length zero, because parseSection() couldn't
	 recognise it, and passed the text here, where it reads
	 until it finds a '<', which it'll find imediately,
	 so the length will be zero */

      while (**cp)
	{
	  /* read until beginning of new TAG */
	  if (strncasecmp (*cp, ">", 1) == 0)
	    break ;
	  ++(*cp) ;
	}
      ++(*cp) ;
      
      node = makeNode (HTML_UNKNOWN, handle) ;

      /* copy unknown tag into node->text */
      len = (*cp-start) ;
      node->text = (char*)halloc ((len+1) * sizeof(char), handle);
      strncpy (node->text, start, len);
      node->text[len] = 0 ;

      *resultnode = node ;
      return TRUE ;
    }

  node = makeNode (HTML_TEXT, handle) ;
  
  len = (*cp-start) ;
  
  node->text = (char*)halloc ((len+1) * sizeof(char), handle);
  
  strncpy (node->text, start, len) ;
  node->text[len] = 0 ;
  
  replaceEscapeCodes (node->text) ;

  *resultnode = node ;

  return TRUE ;
} /* parseText */
/************************************************************/

static BOOL parseHref (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;
  int hlen = -1;		/* init for compiler happiness */
  int numspaces ;
  char *hstart = NULL;		/* init for compiler happiness */
  BOOL HAVE_HREF, IS_NAME_REF ;

  *cp += 2 ;			/* skip '<A' */

  skipSpaces (cp) ;

  IS_NAME_REF = FALSE ;
  if (strncasecmp (*cp, "HREF=", 5) == 0)
    {
      HAVE_HREF = TRUE ;
      *cp += 5 ;		/* skip 'HREF=' */
    }
  else if (strncasecmp (*cp, "NAME=", 5) == 0)
    {

      HAVE_HREF = TRUE ; 
      IS_NAME_REF = TRUE ;
      *cp += 5 ;		/* skip 'NAME=' */
    }
  else
    {
      printf ("Warning : anchor tag <A without argument !!\n");
      HAVE_HREF = FALSE ;
    }

  if (HAVE_HREF)
    hstart = *cp ;

  /* parse the href destination or if no arg given
     just forward to next '>'*/
  numspaces = 0 ;
  while (**cp)
    {
      if (strncasecmp (*cp, ">", 1) == 0)
	break ;
      if (isspace((int)**cp))
	++numspaces ;
      else
	numspaces = 0 ;
      ++(*cp) ;
    }
  if (HAVE_HREF)
    hlen = (*cp-hstart) - numspaces ;

  if (**cp)
    *cp += 1 ;			/* skip '>' */

  node = makeNode (HTML_HREF, handle) ;

  if (HAVE_HREF)
    {
      if ((hstart[0] == '"') && (hstart[hlen-1] == '"'))
	{
	  ++hstart ;
	  hlen -= 2 ;
	}
      node->isNameRef = IS_NAME_REF ;

      node->link = (char*)halloc ((hlen+1) * sizeof(char), handle);

      strncpy (node->link, hstart, hlen) ;
      node->link[hlen] = 0 ;
    }
  else
    node->link = 0 ;		/* no link then */

  if (!(parseSection (cp, &leftnode, handle)))
    {
      printf ("Warning : referenced text not valid !!\n") ;
    }

  skipSpaces (cp) ;
  if (strncasecmp (*cp, "</a>", 4) == 0)
    {
      *cp += 4 ;
    }
  else
    {
      printf ("Warning : anchor tag not closed by </A> !!\n") ;
    }
  
  node->left = leftnode ;
  node->right = 0 ;

  *resultnode = node ;

  return TRUE ;
} /* parseHref */

/************************************************************/

static BOOL parseImage (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node ;
  int len, srclen, numspaces ;
  char *start, *s ;
  BOOL HAVE_SRC=FALSE ;
  *cp += 4 ;			/* skip '<IMG' */

  skipSpaces (cp) ;

  start = *cp ;

  /* read in the arguments list until next '>'*/
  numspaces = 0 ;
  while (**cp)
    {
      if (strncasecmp (*cp, ">", 1) == 0)
	break ;
      if (isspace((int)**cp))
	++numspaces ;
      else
	numspaces = 0 ;
      ++(*cp) ;
    }

  /* the length of everything between the 
     end of <IMG and the end of the args or the next > */
  len = (*cp-start) - numspaces ;

  if (**cp)
    *cp += 1 ;			/* skip '>' */

  /* now find the SRC= argument */

  s = start ;
  while (*s)
    {
      if (strncasecmp (s, "src=", 4) == 0)
	{
	  HAVE_SRC = TRUE ;
	  break ;
	}
      ++s ;
    }
  if (HAVE_SRC)
    {
      s += 4 ;			/* skip 'src=' */
      len -= 4;

      start = s ;
      srclen = 0 ;

      if (s[0] == '"')	/* if src in quotes then link ends with quote */
	{
	  s++ ; start++ ;
	  while (*s && ++srclen < len && *s != '"')
	    { ++(s) ; }
	  --srclen;		/* discard the quote */
	}
      else
	{ 
	  while (*s && ++srclen < len && !isspace((int)*s))
	    { ++(s) ; }
	}

      node = makeNode (HTML_GIFIMAGE, handle) ;

      /* save the file name of the image */
      node->link = (char*)halloc((srclen+1) * sizeof(char), handle);

      strncpy (node->link, start, srclen) ;
      node->link[srclen] = 0 ;
    }
  else
    {
      node = makeNode (HTML_UNKNOWN, handle) ;
    }

  *resultnode = node ;

  return TRUE ;
} /* parseImage */
/************************************************************/

static BOOL parseListItem (HtmlListType   style,
			   char		**cp, 
			   HtmlNode     **resultnode,
			   STORE_HANDLE   handle)
{
  HtmlNode *node, *leftnode, *rightnode ;
  int lstyle = style ;

  skipSpaces (cp) ;

  /* check, whether the next tag is a valid listitem tag */
  
  /* with <DL> list <LI> and <DD> items are allowed */
  if (lstyle == HTML_LIST_NOINDENT &&
      !(strncasecmp (*cp, "<dd>", 4) == 0 ||
	strncasecmp (*cp, "<li>", 4) == 0 ||
	strncasecmp (*cp, "<dt>", 4) == 0))
    {
      *resultnode = 0 ;
      return FALSE ;
    }
  /* only <LI> items in <UL> or <OL> lists */
  else if ((lstyle == HTML_LIST_BULLET || lstyle == HTML_LIST_NUMBER) &&
	   !(strncasecmp (*cp, "<li>", 4) == 0))
    {
      *resultnode = 0 ;
      return FALSE ;
    }

  if (lstyle == HTML_LIST_NOINDENT)
    {
      /* in <DL> list a <DD> item becomes indented but no bullet */
      if (strncasecmp (*cp, "<dd>", 4) == 0)
	lstyle = HTML_LIST_NOBULLET ;
      else if (strncasecmp (*cp, "<dt>", 4) == 0)
	lstyle = HTML_LIST_NOINDENT_NOBULLET ;
    }
  *cp += 4 ;
  /* now cp stands right after an <LI> and parses the following
     as a normal section */
  
  parseSection (cp, &leftnode, handle) ;
  
  node = makeNode (HTML_LISTITEM, handle) ;
  
  node->left = leftnode ;
  node->lstyle = lstyle ;

  if (parseListItem (style, cp, &rightnode, handle))
    {
      node->right = rightnode ;
    }
  else
    {
      node->right = 0 ;		/* no further list items */
    }

  *resultnode = node ;

  return TRUE ;
} /* parseListItem */
/************************************************************/

static BOOL parseList (int style, char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode ;

  *cp += 4 ;			/* skip <UL> */

#ifdef ALLOW_SECONDLEVEL_LIST_LIST_DOESN_T_YET_WORK
  if (strncasecmp (*cp, "<ul>", 4) == 0 ||
      strncasecmp (*cp, "<ol>", 4) == 0 ||
      strncasecmp (*cp, "<dl>", 4) == 0)
    {
      /* create list item for this list-in-list */
      node = makeNode (HTML_LISTITEM, handle) ;
      
      node->left = leftnode ;
      node->lstyle = lstyle ;

    }
#endif

  parseListItem (style, cp, &leftnode, handle);
  
  skipSpaces (cp) ;
  
  if ((style == HTML_LIST_BULLET && strncasecmp (*cp, "</ul>", 5) == 0) ||
      (style == HTML_LIST_NOINDENT && strncasecmp (*cp, "</dl>", 5) == 0) ||
      (style == HTML_LIST_NUMBER && strncasecmp (*cp, "</ol>", 5) == 0))
    {
      *cp += 5 ;		/* skip </ul> */
    }
  else
    {
      if (style == HTML_LIST_BULLET)
	printf ("Warning : found <UL> without closing </UL> tag !!\n") ;
      else if (style == HTML_LIST_NOINDENT)
	printf ("Warning : found <DL> without closing </DL> tag !!\n") ;
      else if (style == HTML_LIST_NUMBER)
	printf ("Warning : found <OL> without closing </OL> tag !!\n") ;
    }

  node = makeNode (HTML_LIST, handle) ;

  node->left = leftnode ;
  node->lstyle = style ;

  *resultnode = node ;

  return TRUE ;
} /* parseList */
/************************************************************/

static BOOL parseSection (char **cp, HtmlNode **resultnode, STORE_HANDLE handle)
{
  HtmlNode *node, *leftnode, *rightnode ;
  static BOOL MODE_PREFORMAT=FALSE, MODE_BLOCKQUOTE=FALSE ;

  if (!MODE_PREFORMAT)
    skipSpaces (cp) ;

  if (!**cp)			/* EOF */
    {
      if (MODE_PREFORMAT)
	printf ("Warning : found <PRE> tag "
		"without closing </PRE> tag !!\n") ;
      if (MODE_BLOCKQUOTE)
	printf ("Warning : found <BLOCKQUOTE> tag "
		"without closing </BLOCKQUOTE> tag !!\n") ;

      *resultnode = 0 ;
      return TRUE ;
    }

  if (strncasecmp (*cp, "<!--", 4) == 0)
    {
      if (!parseComment (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "<html>", 6) == 0)
    {
      if (!(parseHtml (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</html>", 7) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<head>", 6) == 0)
    {
      if (!(parseHead (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</head>", 7) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<body>", 6) == 0)
    {
      if (!(parseBody (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</body>", 7) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<title>", 7) == 0)
    {
      if (!parseTitle (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if ((strncasecmp (*cp, "<H", 2) == 0) &&
	   (*cp)[2]-'0' >= 1 && (*cp)[2]-'0' <= 7 && (*cp)[3] == '>')
    {
      if (!parseHeader (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if ((strncasecmp (*cp, "</H", 3) == 0) &&
	   (*cp)[3]-'0' >= 1 && (*cp)[3]-'0' <= 7 && (*cp)[4] == '>')
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<a", 2) == 0 &&
	   (isspace((int)(*cp)[2]) || (*cp)[2] == '\n'))
    {
      if (!parseHref (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</a>", 4) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<img", 4) == 0)
    {
      if (!parseImage (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "<ul>", 4) == 0)
    {
      if (!parseList (HTML_LIST_BULLET, cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "<ol>", 4) == 0)
    {
      if (!parseList (HTML_LIST_NUMBER, cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "<dl>", 4) == 0)
    {
      if (!parseList (HTML_LIST_NOINDENT, cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "<li>", 4) == 0)
    {
      /* LI isn't a section, so we've hit the end of a section */
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<dd>", 4) == 0)
    {
      /* DD isn't a section, so we've hit the end of a section */
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<dt>", 4) == 0)
    {
      /* DT isn't a section, so we've hit the end of a section */
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "</ul>", 5) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "</ol>", 5) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "</dl>", 5) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<hr>", 4) == 0)
    {
      leftnode = makeNode (HTML_RULER, handle) ;
      *cp += 4 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "<p>", 3) == 0)
    {
      leftnode = makeNode (HTML_PARAGRAPH, handle) ;
      *cp += 3 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "</p>", 4) == 0)
    {
      leftnode = makeNode (HTML_PARAGRAPH, handle) ;
      *cp += 4 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "<br>", 4) == 0)
    {
      leftnode = makeNode (HTML_LINEBREAK, handle) ;
      *cp += 4 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "<pre>", 5) == 0)
    {
      if (MODE_PREFORMAT)
	printf ("Warning : nesting of <PRE> tags without effect !!\n") ;
      MODE_PREFORMAT = TRUE ;

      leftnode = makeNode (HTML_STARTPREFORMAT, handle) ;
      *cp += 5 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "</pre>", 6) == 0)
    {
      if (!MODE_PREFORMAT)
	printf ("Warning : found </PRE> without preceeding <PRE>\n") ;
      MODE_PREFORMAT = FALSE ;

      leftnode = makeNode (HTML_ENDPREFORMAT, handle) ;
      *cp += 6 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "<blockquote>", 12) == 0)
    {
      if (!MODE_BLOCKQUOTE)
	{
	  leftnode = makeNode (HTML_STARTBLOCKQUOTE, handle) ;
	  MODE_BLOCKQUOTE = TRUE ;
	}
      else
	printf ("Warning : nesting of <BLOCKQUOTE> tags "
		"without effect !!\n") ;

      *cp += 12 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "</blockquote>", 13) == 0)
    {
      if (MODE_BLOCKQUOTE)
	{
	  leftnode = makeNode (HTML_ENDBLOCKQUOTE, handle) ;
	  MODE_BLOCKQUOTE = FALSE ;
	}
      else
	printf ("Warning : found </BLOCKQUOTE> "
		"without preceeding <BLOCKQUOTE>\n") ;

      *cp += 13 ;
      skipSpaces (cp) ;
    }
  else if (strncasecmp (*cp, "<code>", 6) == 0)
    {
      if (!(parseCode (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</code>", 7) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<b>", 3) == 0)
    {
      if (!(parseBold (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</b>", 4) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<strong>", 8) == 0)
    {
      if (!(parseStrong (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</strong>", 9) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else if (strncasecmp (*cp, "<i>", 3) == 0)
    {
      if (!(parseItalic (cp, &leftnode, handle)))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  else if (strncasecmp (*cp, "</i>", 4) == 0)
    {
      *resultnode = 0 ;
      return TRUE ;
    }
  else
    {
      if (!parseText (cp, &leftnode, handle))
	{
	  *resultnode = 0 ;
	  return FALSE ;
	}
    }
  
  node = makeNode (HTML_SECTION, handle) ;
  node->left = leftnode ;
  if (leftnode->type == 0)
    {
      printf ("section on section \n") ;
    }
  if (parseSection (cp, &rightnode, handle))
    {
      node->right = rightnode ;
      *resultnode = node ;
      return TRUE ;
    }
  else
    {
      node->right = 0 ;
      *resultnode = node ;
      return FALSE ;
    }

} /* parseSection */
/************************************************************/


