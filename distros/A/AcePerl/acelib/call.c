/*  File: call.c
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1994
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: provides hooks to optional code, basically a call by
 			name dispatcher
	        plus wscripts/ interface
 * Exported functions:
 * HISTORY:
 * Last edited: Nov 19 14:40 1998 (fw)
 * * Mar  3 15:51 1996 (rd)
 * Created: Mon Oct  3 14:05:37 1994 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: call.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "acedb.h"
#include "call.h"
#include "mytime.h"
#include <ctype.h>		/* for isprint */

/************************* call by name package *********************/

typedef struct
{ char *name ;
  CallFunc func ;
} CALL ;

static Array calls ;	/* array of CALL to store registered routines */

/************************************/

static int callOrder (void *a, void *b) 
{ return strcmp (((CALL*)a)->name, ((CALL*)b)->name) ; }

void callRegister (char *name, CallFunc func)
{
  CALL c ;

  if (!calls)
    calls = arrayCreate (16, CALL) ;
  c.name = name ; c.func = func ;
  if (!arrayInsert (calls, &c, callOrder))
    messcrash ("Duplicate callRegister with name %s", name) ;
}

BOOL callExists (char *name)
{
  CALL c ;
  int i;

  c.name = name ;
  return (calls && arrayFind (calls, &c, &i, callOrder)) ;
}


#include <stdarg.h>   /* for va_start */
BOOL call (char *name, ...)
{
  va_list args ;
  CALL c ;
  int i ;

  c.name = name ;
  if (calls && arrayFind (calls, &c, &i, callOrder))
    { va_start(args, name) ;
      (*(arr(calls,i,CALL).func))(args) ;
      va_end(args) ;
      return TRUE ;
    }

  return FALSE ;
}

/***************** routines to run external programs *******************/

/* ALL calls to system() and popen() should be through these routines
** First, this makes it easier for the Macintosh to handle them.
** Second, by using wscripts as an intermediate one can remove system
**   dependency in the name, and even output style, of commands.
** Third, if not running in ACEDB it does not look for wscripts...
*/

static char *buildCommand (char *dir, char *script, char *args)
{
  static Stack command = 0 ;
/*#ifdef ACEDB*/  /* until we resolve this bit, we have to include wscripts bit even ifndef ACEDB */
  char *cp ;
  static Stack s = 0 ;		/* don't use messprintf() - often used to make args */
  s = stackReCreate (s, 32) ; 
  if (!dir)
    {
      catText (s, "wscripts/") ; 
      catText (s, script) ;
      if ((cp = filName (stackText (s, 0), 0, "x")))
	script = cp ;  /* mieg else fall back on direct unix call */
    }
/*#endif*/

  command = stackReCreate (command, 128) ;
  if (dir)
    { catText (command, "cd ") ;
      catText (command, dir) ;
      catText (command, "; ") ;
    }
  catText (command, script) ;
  if (args)
    { catText (command, " ") ;
      catText (command, args) ;
    }
  return stackText (command, 0) ;
}

int callCdScript (char *dir, char *script, char *args)
{
#if !defined(MACINTOSH)
  return system (buildCommand (dir, script, args)) ;
#else
  return -1 ;
#endif
}

int callScript (char *script, char *args)
{
  return callCdScript (0, script, args) ;
}

FILE* callCdScriptPipe (char *dir, char *script, char *args)
{
  char *command = buildCommand (dir, script, args) ;
  FILE *pipe ;
  int peek ;

#if !(defined(MACINTOSH) || defined(WIN32))
  pipe = popen (command, "r" ) ;
#elif defined(WIN32)
  pipe =  _popen (command, "rt")  ;
#else	/* defined(MACINTOSH) */
  return 0 ;
#endif	/* defined(MACINTOSH) */

  peek = fgetc (pipe) ;		/* first char from popen on DEC
				   seems often to be -1 == EOF!!!
				*/
  if (isprint(peek)) ungetc (peek, pipe) ;
#ifdef DEBUG
  printf ("First char on callCdScriptPipe is %c (0x%x)\n", peek, peek) ;
#endif
  return pipe ;
}

FILE* callScriptPipe (char *script, char *args)
{
  return callCdScriptPipe (0, script, args) ;
}
