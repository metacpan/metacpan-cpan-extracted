/*  File: filsubs.c
 *  Author: Jean Thierry-Mieg (mieg@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description:
 *                   cross platform file system routines
 *              
 * Exported functions:
 * HISTORY:
 * Last edited: Jan  5 16:36 1999 (fw)
 * * Dec  8 10:20 1998 (fw): new function filAge to determine time since
 *              last modification of file
 * * Oct 22 16:17 1998 (edgrif): Replace unsafe strtok with strstr.
 * * Oct 15 11:47 1998 (fw): include messSysErrorText in some messges
 * * Sep 30 09:37 1998 (edgrif): Replaced my strdup with acedb strnew.
 * * Sep  9 14:07 1998 (edgrif): Add filGetFilename routine that will 
 *               return the filename given a pathname 
 *              (NOT the same as the UNIX basename).
 * * DON'T KNOW WHO DID THE BELOW..assume Richard Bruskiewich (edgrif)
 *	-	fix root path detection for default drives (in WIN32)
 * * Oct  8 23:34 1996 (rd)
 *              filDirectory() returns a sorted Array of character 
 *              strings of the names of files, with specified ending 
 *              and spec's, listed in a given directory "dirName";
 *              If !dirName or directory is inaccessible, 
 *              the function returns 0
 * * Jun  6 17:58 1996 (rd)
 * * Mar 24 02:42 1995 (mieg)
 * * Feb 13 16:11 1993 (rd): allow "" endName, and call getwd if !*dname
 * * Sep 14 15:57 1992 (mieg): sorted alphabetically
 * * Sep  4 13:10 1992 (mieg): fixed NULL used improperly when 0 is meant
 * * Jul 20 09:35 1992 (aochi): Add directory names to query file chooser
 * * Jan 11 01:59 1992 (mieg): If file has no ending i suppress the point
 * * Nov 29 19:15 1991 (mieg): If file had no ending, we were losing the
                               last character in dirDraw()
 * Created: Fri Nov 29 19:15:34 1991 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: filsubs.c,v 1.2 2002/11/24 19:27:20 lstein Exp $	 */

#include "regular.h"
#include "mytime.h"
#include "call.h"		/* for callScript (to mail stuff) */

/********************************************************************/

#include "mydirent.h"

#if !defined(WIN32)
/*           UNIX             */
#include <sys/file.h>
#define HOME_DIR_ENVP "HOME"

#define ABSOLUTE_PATH(path) *path == SUBDIR_DELIMITER

#else  /* Utility macros for WIN32 only */

#include <tchar.h> 
#include <direct.h>	   /* for getwcd() and _getdrive() */

/* simple, single letter logical drives assumed here */
static const char *DRIVES = "abcdefghijklmnopqrstuvwxyz";
#define DRIVE_NO(drv) ((drv)-'a'+1)
#define GET_CURRENT_DRIVE *( DRIVES + _getdrive() - 1 )

#define HOME_DIR_ENVP "HOMEPATH"

#include <ctype.h> /* for isalpha() */
#define ABSOLUTE_PATH(path) \
           ( isalpha( (int)*path ) ) && \
           (*(path+1) == DRIVE_DELIMITER) && \
           (*(path+2) == SUBDIR_DELIMITER)
#endif /* WIN32 */

/********************************************************************/

static Stack dirPath = 0 ;

UTIL_FUNC_DEF void filAddDir (char *s)	/* add to dirPath */
{
  char *home ;

  if (!dirPath)
    dirPath = stackCreate (128) ;

  /* if the user directory is specified */
  if (*s == '~' &&
		(home = getenv (HOME_DIR_ENVP))) /* substitute */
    {
#if defined(WIN32) /* in WIN32, need to prefix homepath with home drive*/
      char *drive;
      drive = getenv ("HOMEDRIVE") ;
	  pushText(dirPath, drive) ;
	  catText(dirPath, home) ;
#else
      pushText (dirPath, home) ;
#endif
      catText (dirPath, ++s) ;
    }
  else
    pushText (dirPath, s) ;

  catText (dirPath, SUBDIR_DELIMITER_STR) ;

  return;
} /* filAddDir */

/*********************************************/

UTIL_FUNC_DEF void filAddPath (char *cp)
{
  char *cq = cp ;

  while (TRUE)
    { 
      while (*cq && *cq != PATH_DELIMITER)
	++cq ;
      if (*cq == PATH_DELIMITER)
	{
	  *cq = 0 ;
	  filAddDir (cp) ;
	  cp = ++cq ;
	}
      else
	{ 
	  filAddDir (cp) ;
	  break ;
	}
    }

  return;
} /* filAddPath */


/*****************************************************************************/
/* This function returns the filename part of a given path,                  */
/*                                                                           */
/*   Given   "/some/load/of/directories/filename"  returns  "filename"       */
/*                                                                           */
/* The function returns NULL for the following errors:                       */
/*                                                                           */
/* 1) supplying a NULL ptr as the path                                       */
/* 2) supplying "" as the path                                               */
/* 3) supplying a path that ends in "/"                                      */
/*                                                                           */
/* NOTE, this function is _NOT_ the same as the UNIX basename command or the */
/* XPG4_UNIX basename() function which do different things.                  */
/*                                                                           */
/* The function makes a copy of the supplied path on which to work, this     */
/* copy is thrown away each time the function is called.                     */
/*                                                                           */
/*****************************************************************************/

UTIL_FUNC_DEF char *filGetFilename(char *path)
{
  static char *path_copy = NULL ;
  const char *path_delim = SUBDIR_DELIMITER_STR ;
  char *result = NULL, *tmp ;
    
  if (path != NULL)
    {
      if (strcmp((path + strlen(path) - 1), path_delim) != 0) /* Last char = "/" ?? */
	{
	  if (path_copy != NULL) messfree(path_copy) ;
	  
	  path_copy = strnew(path, 0) ;
	  
	  tmp = path ;
	  while (tmp != NULL)
	    {
	      result = tmp ;
	      
	      tmp = strstr(tmp, path_delim) ;
	      if (tmp != NULL) tmp++ ;
	    }
	}
    }
  
  return(result) ;
} /* filGetFilename */


/*****************************************************************************/
/* This function returns the file-extension part of a given path/filename,   */
/*                                                                           */
/*   Given   "/some/load/of/directories/filename.ext"  returns  "ext"        */
/*                                                                           */
/* The function returns NULL for the following errors:                       */
/*                                                                           */
/* 1) supplying a NULL ptr as the path                                       */
/* 2) supplying a path with no filename                                      */
/*                                                                           */
/* The function returns "" for a filename that has no extension              */
/*                                                                           */
/* The function makes a copy of the supplied path on which to work, this     */
/* copy is thrown away each time the function is called.                     */
/*                                                                           */
/*****************************************************************************/
UTIL_FUNC_DEF char *filGetExtension(char *path)
{
  static char *path_copy = NULL ;
  char *extension = NULL, *cp ;
    
  if (path == NULL)
    return NULL;

  if (strlen(path) == 0)
    return NULL;

  if (path_copy != NULL) messfree(path_copy) ;
  path_copy = messalloc ((strlen(path)+1) * sizeof(char));
  strcpy (path_copy, path);

  cp = path_copy + (strlen(path_copy) - 1);
  while (cp > path_copy &&
	 *cp != SUBDIR_DELIMITER &&
	 *cp != '.')
    --cp;

  extension = cp+1;
    
  return(extension) ;
} /* filGetExtension */


/**********************************************************************/
/* This function takes a directory name and does the following:
   1. Returns the name if it is "complete" 
      (an absolute path on a given platform)
   2. On WIN32 platforms, for onto rooted paths	lacking a 
      drive specification, returns the directory name prefixed with 
      the default drive letter 
   3. Otherwise, assumes that the directory name resides within the 
      current working directory and thus, returns it prefixes the
      directory name with the working directory path */
/**********************************************************************/
UTIL_FUNC_DEF char *filGetFullPath(char *dir)
{
  static char *path_copy = NULL;
  char *pwd ;
  char dirbuf[MAXPATHLEN] ;

  /* Return dir if absolute path already */
  if (ABSOLUTE_PATH(dir))
    { 
      if (path_copy) 
	messfree (path_copy);
      path_copy = (char*) messalloc (strlen(dir) + 1) ;
      strcpy (path_copy, dir) ;
      return path_copy ;
    }

#if defined(WIN32)
  /* else if dir is a Win32 rooted path, then add current drive to rooted paths */
  else if ( *dir == SUBDIR_DELIMITER )
    { 
      char drive[3] = { GET_CURRENT_DRIVE, DRIVE_DELIMITER, '\0' } ;
      
      if (path_copy)
	messfree (path_copy);

      path_copy = (char*) messalloc (strlen(dir) + strlen(drive) + 1) ;
      strcpy (path_copy, drive) ;
      strcat (path_copy, dir) ;

      return path_copy ;
    }
#endif

  /* else if I can, then prefix "dir" with working directory path... */
  else if ((pwd = getwd (dirbuf)))
    { 
      if (path_copy)
	messfree (path_copy);

      path_copy = (char*) messalloc (strlen(pwd) + strlen(dir) + 2) ;

      strcpy (path_copy, pwd) ;
      strcat (path_copy, SUBDIR_DELIMITER_STR) ;
      strcat (path_copy, dir) ;

      return path_copy ;
    }
  else
    return 0 ;  /* signals error that the path was not found */
} /* filGetFullPath */

/*******************************/

static BOOL filCheck (char *name, char *spec)
	/* allow 'd' as second value of spec for a directory */
{
  char *cp ;
  BOOL result ;
  struct stat status ;

  if (!spec) /* so filName returns full file name (for error messages) */
    return TRUE ;
				/* directory check */
  if (spec[1] == 'd'  &&
      (stat (name, &status) || !(status.st_mode & S_IFDIR)))
    return 0 ;

  switch (*spec)
    {
    case 'r':
      return !(access (name, R_OK)) ;
    case 'w':
    case 'a':
      if (!access (name, W_OK))	/* requires file exists */
	return TRUE ;
				/* test directory writable */
      cp = name + strlen (name) ;
      while (cp > name)
	if (*--cp == SUBDIR_DELIMITER) break ;
      if (cp == name)
	return !(access (".", W_OK)) ;
      else
	{ *cp = 0 ;
	  result = !(access (name, W_OK)) ;
	  *cp = SUBDIR_DELIMITER ;
	  return result ;
	}
    case 'x':
      return !(access (name, X_OK)) ;
    default:
      messcrash ("Unknown spec %s passed to filName", spec) ;
    }
  return FALSE ;
}

/************************************************/

static char *filDoName (char *name, char *ending, char *spec, BOOL strict)
{
  static Stack part = 0, full = 0 ;
  char *dir, *result ;
#if defined(WIN32)
  char *cp, buf2[2] ;
  static char driveStr[3] = { 'C', DRIVE_DELIMITER, '\0' },
			  *pDriveStr = driveStr ; 
#endif

  if (!name)
    messcrash ("filName received a null name") ;

  if (!part)
    { part = stackCreate (128) ;
      full = stackCreate (MAXPATHLEN) ;
    }
    
  stackClear (part) ;

#if defined(WIN32)
  /* convert '/' => '\\' in path string */
  cp = name ; buf2[1] = 0 ;
  while (*cp)
    {
      if (*cp == '/') 
	catText (part, "\\") ;
      else
	{ buf2[0] = *cp; catText (part, buf2) ; }
      cp++ ;
    }
#else
  catText (part, name) ;
#endif
  if (ending && *ending)
    { catText (part, ".") ;
      catText (part, ending) ;
    }
	/* NB filName is reentrant in the sense that it can be called 
	   on strings it generates, because they first get copied into 
	   part, and then the new name is constructed in full.
	*/
  if (ABSOLUTE_PATH(name))
    {
      stackClear (full) ;
      catText (full, stackText (part, 0)) ;
      result = stackText (full, 0) ;
      if (filCheck (result, spec))
	return result ;
      else
	return 0 ;
    }
  
#if defined(WIN32)
/* Check if path name is a root path
   hence on the default logical drive */
  if( name[0] == SUBDIR_DELIMITER )
    {
      stackClear (full) ;
      driveStr[0] = GET_CURRENT_DRIVE ;
      catText (full, pDriveStr ) ;
      catText (full, stackText (part, 0)) ;
      result = stackText (full, 0) ;
      if (filCheck (result, spec))
	return result ;
      else
	return 0 ;
    }
#endif
  
  if (!dirPath)			/* add cwd as default to search */
    filAddDir (getwd (stackText (full, 0))) ;
  stackCursor (dirPath, 0) ;
  while ((dir = stackNextText (dirPath)))
    { 
      stackClear (full) ;
      catText (full, dir) ;
      catText (full, stackText (part, 0)) ;
      result = stackText (full, 0) ;
      if (filCheck (result, spec))
	return result ;
      if (strict)
	break ;
    }
  return 0 ;
} /* filDoName */

/************************************************************/

UTIL_FUNC_DEF char *filName (char *name, char *ending, char *spec)
{ return filDoName(name, ending, spec, FALSE) ; }

/************************************************************/

UTIL_FUNC_DEF char *filStrictName (char *name, char *ending, char *spec)
{ return filDoName(name, ending, spec, TRUE) ; }

/************************************************************/

UTIL_FUNC_DEF BOOL filremove (char *name, char *ending) 
				/* TRUE if file is deleted. -HJC*/
{
  char *s = filName (name, ending, "r") ;
  if (s)
    return unlink(s) ? FALSE : TRUE ;
  else
    return FALSE ;
} /* filremove */

/************************************************************/

UTIL_FUNC_DEF FILE *filopen (char *name, char *ending, char *spec)
{
  char *s = filName (name, ending, spec) ;
  FILE *result = 0 ;
   
  if (!s)
    {
      if (spec[0] == 'r')
	messerror ("Failed to open for reading: %s (%s)",
		   filName (name, ending,0),
		   messSysErrorText()) ;
      else if (spec[0] == 'w')
	messerror ("Failed to open for writing: %s (%s)",
		   filName (name, ending,0),
		   messSysErrorText()) ;
      else if (spec[0] == 'a')
	messerror ("Failed to open for appending: %s (%s)",
		   filName (name, ending,0),
		   messSysErrorText()) ;
      else
	messcrash ("filopen() received invalid filespec %s",
		   spec ? spec : "(null)");
    }
  else if (!(result = fopen (s, spec)))
    {
      messerror ("Failed to open %s (%s)",
		 s, messSysErrorText()) ;
    }
  return result ;
} /* filopen */

/********************* temporary file stuff *****************/

static Associator tmpFiles = 0 ;

UTIL_FUNC_DEF FILE *filtmpopen (char **nameptr, char *spec)
{
  if (!nameptr)
    messcrash ("filtmpopen requires a non-null nameptr") ;

  if (!strcmp (spec, "r"))
    return filopen (*nameptr, 0, spec) ;

#if defined(SUN) || defined(SOLARIS)
  if (!(*nameptr = tempnam ("/var/tmp", "ACEDB")))
#else
  if (!(*nameptr = tempnam ("/tmp", "ACEDB")))
#endif
    { 
      messerror ("failed to create temporary file (%s)",
		 messSysErrorText()) ;
      return 0 ;
    }
  if (!tmpFiles)
    tmpFiles = assCreate () ;
  assInsert (tmpFiles, *nameptr, *nameptr) ;

  return filopen (*nameptr, 0, spec) ;
} /* filtmpopen */

/************************************************************/

UTIL_FUNC_DEF BOOL filtmpremove (char *name)	/* delete and free()  */
{ BOOL result = filremove (name, 0) ;

  free (name) ;	/* NB free since allocated by tempnam */
  assRemove (tmpFiles, name) ;
  return result ;
}

/************************************************************/

UTIL_FUNC_DEF void filtmpcleanup (void)
{ char *name = 0 ;
 
  if (tmpFiles)
    while (assNext (tmpFiles, &name, 0))
      { filremove (name, 0) ;
	free (name) ;
      }
}

/************* filqueryopen() ****************/

static QueryOpenRoutine queryOpenFunc = 0 ;

UTIL_FUNC_DEF QueryOpenRoutine filQueryOpenRegister (QueryOpenRoutine new)
{ QueryOpenRoutine old = queryOpenFunc ; queryOpenFunc = new ; return old ; }

UTIL_FUNC_DEF FILE *filqueryopen (char *dname, char *fname, char *end, char *spec, char *title)
{
  Stack s ;
  FILE*	fil = 0 ;
  int i ;
				/* use registered routine if available */
  if (queryOpenFunc)
    return (*queryOpenFunc)(dname, fname, end, spec, title) ;

  /* otherwise do here and use messprompt() */
  s = stackCreate(50);

  if (dname && *dname)
    { pushText(s, dname) ; catText(s,"/") ; }
  if (fname)
    catText(s,fname) ; 
  if (end && *end)
    { catText(s,".") ; catText(s,end) ; }

 lao:
  if (!messPrompt("File name please", stackText(s,0), "w")) 
    { stackDestroy(s) ;
      return 0 ;
    }
  i = stackMark(s) ;
  pushText(s, freepath()) ;	/* freepath needed by WIN32 */
  if (spec[0] == 'w' && 
      (fil = fopen (stackText(s,i), "r")))
    { if ( fil != stdin && fil != stdout && fil != stderr)
	fclose (fil) ; 
      fil = 0 ;
      if (messQuery (messprintf ("Overwrite %s?",
				 stackText(s,i))))
	{ 
	  if ((fil = fopen (stackText(s,i), spec)))
	    goto bravo ;
	  else
	    messout ("Sorry, can't open file %s for writing",
		     stackText (s,i)) ;
	}
      goto lao ;
    }
  else if (!(fil = fopen (stackText(s,i), spec))) 
    messout ("Sorry, can't open file %s",
	     stackText(s,i)) ;
bravo:
  stackDestroy(s) ;
  return fil ;
} /* filqueryopen */

/*********************************************/

static Associator mailFile = 0, mailAddress = 0 ;

UTIL_FUNC_DEF void filclose (FILE *fil)
{
  char *address ;
  char *filename ;

  if (!fil || fil == stdin || fil == stdout || fil == stderr)
    return ;
  fclose (fil) ;
  if (mailFile && assFind (mailFile, fil, &filename))
    { if (assFind (mailAddress, fil, &address))
	callScript ("mail", messprintf ("%s %s", address, filename)) ;
      else
	messerror ("Have lost the address for mailfile %s", filename) ;
      assRemove (mailFile, fil) ;
      assRemove (mailAddress, fil) ;
      unlink (filename) ;
      free (filename) ;
    }
} /* filclose */

/***********************************/

UTIL_FUNC_DEF FILE *filmail (char *address)	/* requires filclose() */
{
  char *filename ;
  FILE *fil ;

  if (!mailFile)
    { mailFile = assCreate () ;
      mailAddress = assCreate () ;
    }
  if (!(fil = filtmpopen (&filename, "w")))
    { messout ("failed to open temporary mail file %s", filename) ;
      return 0 ;
    }
  assInsert (mailFile, fil, filename) ;
  assInsert (mailAddress, fil, address) ;
  return fil ;
} /* filmail */

/******************* directory stuff *************************/

static int dirOrder(void *a, void *b)
{
  char *cp1 = *(char **)a, *cp2 = *(char**)b;
  return strcmp(cp1, cp2) ;
} /* dirOrder */

/* returns an Array of strings representing the filename in the
   given directory according to the spec. "r" will list all files,
   and "rd" will list all directories.
   The behaviour of the "w" spec is undefined.
   The array has to be destroyed using filDirectoryDestroy,
   because the memory of the strings needs to be reclaimed as well. */

UTIL_FUNC_DEF Array filDirectoryCreate (char *dirName,
					char *ending, 
					char *spec)
{
  Array a ;
#if !defined(WIN32) && !defined(DARWIN)
  DIR	*dirp ;
  char	*dName, *dName_copy, entryPathName[MAXPATHLEN], *leaf ;
  int	dLen, endLen ;
  MYDIRENT *dent ;

  if (!dirName || !(dirp = opendir (dirName)))
    return 0 ;

  if (ending)
    endLen = strlen (ending) ;
  else
    endLen = 0 ;

  strcpy (entryPathName, dirName) ;
  strcat (entryPathName, "/") ;
  leaf = entryPathName + strlen(dirName) + 1 ;

  a = arrayCreate (16, char*) ;
  while ((dent = readdir (dirp)))           
    { dName = dent->d_name ;
      dLen = strlen (dName) ;
      if (endLen && (dLen <= endLen ||
		     dName[dLen-endLen-1] != '.'  ||
		     strcmp (&dName[dLen-endLen],ending)))
	continue ;

      strcpy (leaf, dName) ;
      if (!filCheck (entryPathName, spec))
	continue ;

      if (ending && dName[dLen - endLen - 1] == '.') /* remove ending */
	dName[dLen - endLen - 1] = 0 ;

      /* the memory of these strings is freed my 
	 the messfree()'s in filDirectoryDestroy() */
      dName_copy = messalloc(strlen(dName)+1) ;
      strcpy (dName_copy, dName);
      array(a, arrayMax(a), char*) = dName_copy;
    }
  
  closedir (dirp) ;
  
  /************* reorder ********************/
    
  arraySort(a, dirOrder) ;
  return a ;
#else   /* defined(WIN32) */
  return 0 ;
#endif	/* defined(WIN32) */
} /* filDirectoryCreate */

/*************************************************************/

UTIL_FUNC_DEF void filDirectoryDestroy (Array filDirArray)
{
#ifndef WIN32
  int i;
  char *cp;

  for (i = 0; i < arrayMax(filDirArray); ++i)
    {
      cp = arr(filDirArray, i, char*);

      messfree (cp);
    }
  arrayDestroy (filDirArray);
#endif /* !WIN32 */
  return;
} /* filDirectoryDestroy */

/************************************************************/
/* determines the age of a file, according to its last modification date.

   returns TRUE if the age could determined and the int-pointers
   (if non-NULL will be filled with the numbers).

   returns FALSE if the file doesn't exist, is not readable,
   or the age could not be detrmined. */
/************************************************************/
BOOL filAge (char *name, char *end,
	     int *diffYears, int *diffMonths, int *diffDays,
	     int *diffHours, int *diffMins, int *diffSecs)
{
  struct stat status;
  mytime_t time_now, time_modified;
  char time_modified_str[25];
	  
  /* get the last-modification time of the file,
     we parse the time into two acedb-style time structs
     in order to compare them using the timediff functions */
  
  if (!(filName (name, end, "r")))
    return FALSE;

  if (stat (filName (name, end, "r"), &status) == -1)
    return FALSE;

  {
    time_t t = status.st_mtime;
    struct tm *ts;

    /* convert the time_t time into a tm-struct time */
    ts = localtime(&t);		

    /* get a string with that time in it */
    strftime (time_modified_str, 25, "%Y-%m-%d_%H:%M:%S", ts) ;

    time_now =      timeNow();
    time_modified = timeParse(time_modified_str);

    if (diffYears)
      timeDiffYears (time_modified, time_now, diffYears);

    if (diffMonths)
      timeDiffMonths (time_modified, time_now, diffMonths);

    if (diffDays)
      timeDiffDays (time_modified, time_now, diffDays);

    if (diffHours)
      timeDiffHours (time_modified, time_now, diffHours);

    if (diffMins)
      timeDiffMins (time_modified, time_now, diffMins);

    if (diffSecs)
      timeDiffSecs (time_modified, time_now, diffSecs);
  }
  return TRUE;
} /* filAge */



/************************************************************/
/********** Some WIN32-specific filsub-like code ************/
/************************************************************/

#if defined(WIN32)

/************************************************************
 *	Converts MSDOS-like pathnames to POSIX-like ones.   *
 *  Warning: This function is not reentrant, to avoid	    *
 *  the complexities of heap memory allocation and release  *
 ************************************************************/
UTIL_FUNC_DEF char *DosToPosix(char *path)
{
  static char newFilName[MAXPATHLEN] ;
  char cwdpath[MAXPATHLEN], *cwd ;
  int i , drive ;

  if( !path || !*path ) return NULL ;

	/* POSIX with drive letters starts with "//" */
  newFilName[0] = SUBDIR_DELIMITER ;
  newFilName[1] = SUBDIR_DELIMITER ;

ReScan:
  i = 2 ;
	/* Drive letter as "A:\" format converted to "A/" format */
  if( strlen(path) >= 2  && 
     (isalpha( (int)*path ) ) && 
     (*(path+1) == DRIVE_DELIMITER) )
    {
      newFilName[i++] = drive = tolower(*path) ;
      path += 2 ; /* skip over drive letter... */
		/* If a root delimiter is present, then path from root (skip delimiter) */
      if( *path == SUBDIR_DELIMITER )
	path++ ;
      else /* else, a relative path on specified drive (append to current directory) */
	{	 /*  If a non-NULL current working directory on specified drive is found */
	  if( (cwd = _getdcwd(DRIVE_NO(drive),cwdpath,MAXPATHLEN - 2)) != NULL )
	    {	/* Then append relative path to current working directory*/
	      if( strlen(cwd)+strlen(path)-1 > MAXPATHLEN )
		messcrash("DosToPosix(): Path buffer overflow?") ;
	      /* If current working directory is not just a root directory pathname*/
	      if( *(cwd+3) ) /* i.e. non-null fourth character?*/
		strcat(cwd, SUBDIR_DELIMITER_STR) ; /* then tack on a SUBDIR_DELIMITER*/
	      strcat(cwd, path) ;
	      path = cwd ;  /* Reset path to new total path*/
	      goto ReScan ; /* Need to rescan because cwd is of DOS format?*/
	    } /* else, assume path from root*/
	}
    }
  else
    if( *path == SUBDIR_DELIMITER	/* If root directory specified only, with no drive letter? */
       && *path++								/* always TRUE thus skips over delimiter... */ )
      newFilName[i++] = GET_CURRENT_DRIVE ;	/* Then assume current drive at root directory*/

    else {	/* Else, no drive letter, no root delimiter => relative path not at root */
      if( (cwd = getwd(cwdpath)) != NULL )	/* If a non-NULL current working */
	{										/* directory on default drive is found */
	  if( strlen(cwd)+strlen(path)-1 > MAXPATHLEN ) /* Append relative path to cwd */
	    messcrash("DosToPosix(): Path buffer overflow?") ;
	  
	  if( *(cwd+3) )	/* If cwd is not just a root directory */
	    strcat(cwd, SUBDIR_DELIMITER_STR) ; /* then tack on a SUBDIR_DELIMITER */
	  strcat(cwd, path) ;
	  path = cwd ;  /* Reset path to new total path*/
	  goto ReScan ; /* Need to rescan because cwd is of DOS format?*/
	}
      else /* just use the current drive*/
	newFilName[i++] = GET_CURRENT_DRIVE ;
    }
  newFilName[i++] = SUBDIR_DELIMITER ;
  
  while(*path) /* Until '\0' encountered */
    {
      /* Path delimiter '\' format */
      if( (*path == SUBDIR_DELIMITER) )
	newFilName[i++] = SUBDIR_DELIMITER ; /* replace ...*/
      else
	newFilName[i++] = *path ; /* else, just copy letter */
      ++path ;	/* ... then skip over */
    }
  newFilName[i] = '\0' ;
  return newFilName ;
}

#endif /* #defined(WIN32) */

/*************** end of file ****************/
