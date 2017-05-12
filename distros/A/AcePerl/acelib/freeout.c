/*  File: freeout.c
 *  Author: Danielle et jean Thierry-Mieg (mieg@mrc-lmba.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1995
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmba.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@frmop11.bitnet
 *
 * Description:
 * Exported functions: see regular.h
 * HISTORY:
 * Last edited: Sep 11 10:09 1998 (edgrif)
 * * Sep 11 09:26 1998 (edgrif): Add messExit function registering.
 * * Dec 14 16:47 1995 (mieg)
 * Created: Thu Dec  7 22:22:33 1995 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: freeout.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "freeout.h"
#include <ctype.h>

typedef struct outStruct { int magic ;
			   FILE *fil ;
			   Stack s ;
			   int line ;  /* line number */
			   int pos ;   /* char number in line */
			   int byte ;  /* total byte length */
			   int level ;
			   struct outStruct *next ;
			 } OUT ;

static int MAGIC = 245393 ;
static int outLevel = 0 ;
static Array outArray = 0 ;
static OUT *outCurr ;
static Stack outBuf = 0 ;  /* buffer for messages */
#define BUFSIZE 65536 

static void freeMessOut (char*) ;

/************************************************/

void freeOutInit (void)
{
  static BOOL isInitialised = FALSE ;
  
  if (!isInitialised)
    { isInitialised = TRUE ;
      outLevel = 0 ;
      outCurr = 0 ;
      outArray = arrayCreate (6, OUT) ;
      freeOutSetFile (stdout) ;
      outBuf = stackCreate (BUFSIZE) ;
      messOutRegister (freeMessOut) ;
      messErrorRegister (freeMessOut) ;
      messExitRegister (freeMessOut) ;
				/* what about prompt/query? */
    }
}

/************************************************/

static int freeOutSetFileStack (FILE *fil, Stack s)
{ int i = 0 ;

  freeOutInit () ;
  while (array (outArray, i, OUT).magic) i++ ;
  
  outLevel++ ;
  outCurr = arrayp (outArray, i, OUT) ;
  if (fil) outCurr->fil = fil ;
  else if (s) outCurr->s = s ;
  outCurr->line = outCurr->pos = outCurr->byte = 0 ;    
  outCurr->next = 0 ;
  outCurr->level = outLevel ;
  outCurr->magic = MAGIC ;
  return outLevel ;
}

int freeOutSetFile (FILE *fil)
{ return freeOutSetFileStack (fil, 0) ;
}

int freeOutSetStack (Stack s)
{ return freeOutSetFileStack (0, s) ;
}

/************************************************/

void freeOutClose (int level)
{ int  i = arrayMax (outArray) ;
  OUT *out ;
  
  while (i--)
    { out = arrayp (outArray, i, OUT) ;
      if (!out->magic)
	continue ;
      if (out->magic != MAGIC)
	messcrash("bad magic in freeOutClose") ;
      if (out->level >= outLevel)  /* close all tees */
	{ /* do NOT close fil, because freeOutSetFile did not open it */
	  out->s = 0 ; out->fil = 0 ;
	  outCurr->line = outCurr->pos = outCurr->byte = 0 ;    
	  out->next = 0 ;
	  out->magic = 0 ;
	  out->level = 0 ;
	}
      else
	break ;
    }
  outLevel-- ;
  outCurr = arrayp (outArray, i, OUT) ;
  if (outCurr->level != outLevel)
    messcrash ("anomaly in freeOutClose") ;
}

/************************************************/

void freeOut (char *text)
{ OUT *out = outCurr ;
  char *cp ;
  int pos = 0, line = 0, ln  ;
  
  cp = text ;
  ln = strlen(text) ;
  while (*cp) 
    if (*cp++ == '\n') 
      { pos = 0 ; line++ ;}
    else
      pos++ ;
  while (out)
    { if (out->s)
	catText(out->s, text) ;
      if (out->fil)
	fputs(text, out->fil) ; /* fprintf over interprets % and \ */
      out->byte += ln ;
      if (line)
	{ out->line += line ; out->pos = pos ; }
      else
	out->pos += pos ;
      out = out->next ;
    }
}

static void freeMessOut (char* text)
{
  freeOut ("// ") ;
  freeOut (text) ;
  freeOut ("\n") ;
}

/*************************************************************/
/* copy a binary structure onto a text stack */
void freeOutBinary (char *data, int size)
{ 
  OUT *out = outCurr ;
  if (out->fil)
    fwrite(data,size,1,out->fil);
  else if (out->s) {
    catBinary (out->s,data,size);
    /* acts like a newline was added */
    out->pos = 0;
    out->line++;
  }
}

/*************************************************************/

void freeOutxy (char *text, int x, int y)
{ static Array buf = 0 ;
  OUT *out = outCurr ;
  int i, j, k = 0 ;

  i = x - out->pos , j = y - out->line ;
  if (i || j)
    { buf = arrayReCreate (buf, 100, char) ;
      k = 0 ;
      if (j > 0)
	{ while (j--)
	    array (buf, k++, char) = '\n' ;
	  i = x ;
	}
      if (i < 0)
	{ array (buf, k++, char) = '\n' ;
	  i = x ; out->line-- ; /* kludge, user should ignore this line feed */
	}
      if (i > 0)
	{ while (i--)
	    array (buf, k++, char) = ' ' ;
	}
      array (buf, k++, char) = 0 ;
      freeOut (arrp(buf, 0, char)) ;
    }
  freeOut (text) ;
}

/************************************************/

void freeOutf (char *format,...)
{ 
  va_list args ;
  
  stackClear (outBuf) ;
  va_start (args,format) ;
    vsprintf (stackText (outBuf,0), format,args) ;
  va_end (args) ;

  if (strlen(stackText (outBuf,0)) >= BUFSIZE)
    messcrash ("abusing freeOutf with too long a string: \n%s", 
	       outBuf) ;

  freeOut (stackText (outBuf,0)) ;
}

/************************************************/

int freeOutLine (void)
{ return outCurr->line ; }

int freeOutByte (void)
{ return outCurr->byte ; }

int freeOutPos (void)
{ return outCurr->pos ; }

/************************************************/
/************************************************/














 
