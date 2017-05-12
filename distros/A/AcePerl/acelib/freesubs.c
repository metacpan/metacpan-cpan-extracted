/*  File: freesubs.c
 *  Author: Richard Durbin (rd@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: free format input - record based
 * Exported functions: lots - see regular.h
 * HISTORY:
 * Last edited: Dec  4 11:20 1998 (fw)
 * * Dec  3 14:46 1998 (edgrif): Insert version macros for libfree.
 *    freecard ignores "\r" and "\n" under WIN32
 * * Sep 30 14:19 1998 (edgrif)
 * * Nov 27 12:30 1995 (mieg): freecard no longer stips \, freeword does
 *    also i added freeunprotect
 * Created: Sun Oct 27 18:16:01 1991 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: freesubs.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include "regular.h"
#include "version.h"
#include <ctype.h>

/* free package version and copyright string.    */
/*                                               */
#define FREE_TITLE   "Free library"
#define FREE_DESC    "Sanger Centre Informatics utilities library."

#define FREE_VERSION 1
#define FREE_RELEASE 1
#define FREE_UPDATE  1
#define FREE_VERSION_NUMBER  UT_MAKE_VERSION_NUMBER(FREE_VERSION, FREE_RELEASE, FREE_UPDATE)

UT_COPYRIGHT_STRING(FREE_TITLE, FREE_VERSION, FREE_RELEASE, FREE_UPDATE, FREE_DESC)

 
int isInteractive = TRUE ;      /* can set FALSE, i.e. in tace */
 
#define MAXSTREAM 80
#define MAXNPAR 80
typedef struct
  { FILE *fil ;
    char *text ;
    char special[24] ;
    int npar ;
    int parMark[MAXNPAR] ;
    int line ;
    BOOL isPipe ;
  } STREAM ;
static STREAM   stream[MAXSTREAM] ;
static int	streamlevel ;
static FILE	*currfil ;	/* either currfil or currtext is 0 */
static char	*currtext ;	/* the other is the current source */
static Stack    parStack ;
static int	maxcard = 1024 ;
static unsigned char *card, *word, *cardEnd, *pos ;
static Associator filAss ;
 
#define _losewhite    while (*pos == ' '|| *pos == '\t') ++pos
#define _stepover(x)  (*pos == x && ++pos)
#define _FREECHAR     (currfil ? getc (currfil) : *currtext++)
 
/************************************/
 
void freeinit (void)
{ static BOOL isInitialised = FALSE ;
  
  if (!isInitialised)
    { streamlevel = 0 ;
      currtext = 0 ;
      stream[streamlevel].fil = currfil = stdin ;
      stream[streamlevel].text = 0 ;
      freespecial ("\n\t\\/@%") ;
      card = (unsigned char *) messalloc (maxcard) ;
      cardEnd = &card[maxcard-1] ;
      pos = card ;
      word = (unsigned char *) messalloc (maxcard) ;
      filAss = assCreate () ;
      parStack = stackCreate (128) ;
      isInitialised = TRUE ;
    }
}

/*******************/

/* Sometimes you may need to know if a function below you succeeded in       */
/* changing a stream level.                                                  */
UTIL_FUNC_DCL int freeCurrLevel(void)
  {
  return streamlevel ;
  }

/*******************/

static void freeExtend (unsigned char **pin)
{	/* only happens when getting card */
  unsigned char *oldCard = card ;

  maxcard *= 2 ;
  card = (unsigned char *) messalloc (maxcard) ;
  if (oldCard)     /* jtm june 22, 1992 */
    memcpy (card, oldCard, maxcard/2) ;
  cardEnd = &card[maxcard-1] ;
  *pin += (card - oldCard) ;
  messfree (oldCard) ;
  messfree (word) ;
  word = (unsigned char *) messalloc (maxcard) ;
}
 
/********************/

static char special[256] ;

void freespecial (char* text)
{
  if (!text)
    messcrash ("freespecial received 0 text") ;
  if (strlen(text) > 23)
    messcrash ("freespecial received a string longer than 23") ;
  if (text != stream[streamlevel].special)
    strcpy (stream[streamlevel].special, text) ;
  memset (special, 0, (mysize_t) 256) ;
  while (*text)
    special [((int) *text++) & 0xFF] = TRUE ;
  special[0] = TRUE ;
  special[(unsigned char)EOF] = TRUE ;		/* better have these to ensure streams terminate! */
}
 
/********************/
 
void freeforcecard (char *string)
{ int level = freesettext (string, "") ;
  freespecial ("") ;
  freecard (level) ;
}
 
/********************/
 
char* freecard (int level)	/* returns 0 when streamlevel drops below level */
{ 
  unsigned char *in,ch,*cp ;
  int kpar ;
  int isecho = FALSE ;		/* could reset sometime? */
  FILE *fil ;
  BOOL acceptShell, acceptCommand ;

restart :
  if (level > streamlevel)
    return 0 ;

  if (isecho)
    printf (!currfil ? "From text >" : "From file >") ;
  in = card ; --in ;

  acceptCommand = special['@'] ;
  acceptShell = special['$'] ;
 
  while (TRUE)
    { if (++in >= cardEnd)
	freeExtend (&in) ;

      *in = _FREECHAR ;
    lao:
      if (special[((int) *in) & 0xFF] && *in != '$' && *in != '@' )
	switch (*in)
	  {
#if defined(WIN32)
	  case '\r':
		  continue ; /* ignore carriage returns */ 
#endif
	  case '\n':		/* == '\x0a' */
	  case ';':		/* card break for multiple commands on one line */
	    goto got_line ;
	  case (unsigned char) EOF:
	  case '\0':
	    freeclose(streamlevel) ;
	    goto got_line;
	  case '\t':     /* tabs should get rounded to 8 spaces */
	    if (isecho)	/* write it out */
	      putchar (*in) ;
            *in++ = ' ' ;
            while ((in - card) % 8)
              { if (in >= cardEnd)
                  freeExtend (&in) ;
                *in++ = ' ' ;
              }
	    --in ;
	    continue ;  
	  case '/':		/* // means start of comment */
	    if ((ch = _FREECHAR) == '/')
	      { while ((ch = _FREECHAR) != '\n' && ch != (unsigned char)EOF) ;
		goto got_line ;
	      }
	    else
	      { if (isecho) putchar (*in) ;
		if (currfil)                     /* push back ch */
		  ungetc (ch, currfil) ;
		else
		  --currtext ;
	      }
	    break ;
	  case '%':		/* possible parameter */
	    --in ; kpar = 0 ;
	    while (isdigit (ch = _FREECHAR))
	      kpar = kpar*10 + (ch - '0') ;
	    if (kpar > 0 && kpar <= stream[streamlevel].npar)
	      for (cp = (unsigned char *) stackText (parStack, 
			     stream[streamlevel].parMark[kpar-1]) ; *cp ; ++cp)
		{ if (++in >= cardEnd)
		    freeExtend (&in) ;
		  *in = *cp ;
		  if (isecho)
		    putchar (*in) ;
		}
	    else
	      messout ("Parameter %%%d can not be substituted", kpar) ;
	    if (++in >= cardEnd)
	      freeExtend (&in) ;
	    *in = ch ; 
	    goto lao ; /* mieg */
	  case '\\':		/* escapes next character - interprets \n */
	    *in = _FREECHAR ;
	    if (*in == '\n')    /* fold continuation lines */
	      { if (isInteractive && !streamlevel)
		  printf ("  Continuation >") ;
		while ((ch = _FREECHAR) == ' ' || ch == '\t') ;
			/* remove whitespace at start of next line */
		if (currfil)                     /* push back ch */
		  ungetc (ch, currfil) ;
		else
		  --currtext ;
		stream[streamlevel].line++ ;
		--in ;
	      }
#if !defined(WIN32)
	    else if (*in == 'n') /* reinterpret \n as a format */
	      { *in = '\n' ; 
	      }
#endif
	    else  /* keep the \ till freeword is called */
	      { *(in+1) = *in ;
		*in = '\\' ;
		if (++in >= cardEnd)
		  freeExtend (&in) ;
	      }
	    break ;
	  default:
	    messerror ("freesubs got unrecognised special character 0x%x = %c\n",
		     *in, *in) ;
	  }
      else
	{ if (!isprint(*in) && *in != '\t' && *in != '\n') /* mieg dec 15 94 */
	    --in ;
	  else if (isecho)	/* write it out */
	    putchar (*in) ;
	}
    }				/* while TRUE loop */
 
got_line:
  stream[streamlevel].line++ ;
  *in = 0 ;
  if (isecho)
    putchar ('\n') ;
  pos = card ;
  _losewhite ;
  if (acceptCommand && _stepover ('@'))        /* command file */
    { char *name ;
      if ((name = freeword ()) && 
	  (fil = filopen (name, 0, "r")))
	freesetfile (fil, (char*) pos) ;
      goto restart ;
    }
  if (acceptShell && _stepover ('$'))        /* shell command */
    {
#if !defined(MACINTOSH)
      system ((char*)pos) ;
#endif
      goto restart ;
    }

  return (char*) card ;
}
 
/************************************************/

void freecardback (void)    /* goes back one card */
{ stream[streamlevel].line-- ;
  freesettext ((char*) card, "") ;
}

/************************************************/
 
BOOL freeread (FILE *fil)                /* reads card from fil */
{
  unsigned char ch, *in = card ;
  int  *line, chint ;
  
  if (!assFind (filAss, fil, &line))
    { line = (int*) messalloc (sizeof (int)) ;
      assInsert (filAss, fil, line) ;
    }
 
  --in ;
  while (TRUE)
    { ++in ;
      if (in >= cardEnd)
	    freeExtend (&in) ;
	  chint = getc(fil) ;
	  if (ferror(fil))
	  	messerror ("chint was bad");
	  *in = chint ;
      switch (*in)
        {
	case '\n' :
	  ++*line ;
	case (unsigned char) EOF :
	  goto got_line ;
	case '/' :		/* // means start of comment */
	  if ((ch = getc (fil)) == '/')
	    { while (getc(fil) != '\n' && !feof(fil)) ;
	      ++*line ;
	      if (in > card)	/* // at start of line ignores line */
		goto got_line ;
	      else
		--in ; /* in = 0   unprintable, so backstepped */
	    }
	  else
	    ungetc (ch,fil) ;
	  break ;
	case '\\' :		/* escape next character */
	  *in = getc(fil) ;
	  if (*in == '\n')	/* continuation */
	    { ++*line ;
	      while (isspace (*in = getc(fil))) ;    /* remove whitespace */
	    }
	  else if (*in == '"' || *in == '\\') /* escape for freeword */
	    { *(in+1) = *in ;
	      *in = '\\' ;
	      ++in ;
	    }
	  /* NB fall through - in case next char is nonprinting */
	default:
	  if (!isprint (*in) && *in != '\t')	/* ignore control chars, e.g. \x0d */
	    --in ;
	}
    }
 
got_line :
  *in = 0 ;
  pos = card ;
  _losewhite ;
  if (feof(fil))
    { assRemove (filAss, fil) ;
      messfree (line) ;
    }
  return *pos || !feof(fil) ;
}

int freeline (FILE *fil)
{ int *line ;

  if (assFind (filAss, fil, &line))
    return *line ;
  else
    return 0 ;
}
 
int freestreamline (int level)
{ 
  return stream[level].line  ;
}
 
/********************************************/


static void freenewstream (char *parms)
{
  int kpar ;

  stream[streamlevel].fil = currfil ;
  stream[streamlevel].text = currtext ;
  if (++streamlevel == MAXSTREAM)
    messcrash ("MAXSTREAM overflow in freenewstream") ;
  strcpy (stream[streamlevel].special, stream[streamlevel-1].special) ;

  stream[streamlevel].npar = 0 ;
  stream[streamlevel].line = 1 ;

 if (!parms || !*parms)
    return ;                           /* can t abuse NULL ! */
  pos = (unsigned char *) parms ;			/* abuse freeword() to get parms */

  for (kpar = 0 ; kpar < MAXNPAR && freeword () ; kpar++) /* read parameters */
    { stream[streamlevel].parMark[kpar] = stackMark (parStack) ;
      pushText (parStack, (char*) word) ;
    }

  stream[streamlevel].npar = kpar ;
  stream[streamlevel].isPipe = FALSE ;
  pos = card ;			/* restore pos to start of blank card */
  *card = 0 ;
}
 
int freesettext (char *string, char *parms)
{
  freenewstream (parms) ;

  currfil = 0 ;
  currtext = string ;

  return streamlevel ;
}

int freesetfile (FILE *fil, char *parms)
{
  freenewstream (parms) ;

  currfil = fil ;
  currtext = 0 ;

  return streamlevel ;
}

int freesetpipe (FILE *fil, char *parms)
{
  freenewstream (parms) ;

  currfil = fil ;
  currtext = 0 ;
  stream[streamlevel].isPipe = TRUE ;
  return streamlevel ;
}

void freeclose(int level)
{ int kpar ;
  while (streamlevel >= level)
    { if (currfil && currfil != stdin && currfil != stdout)
	{
	  if (stream[streamlevel].isPipe)
	    pclose (currfil) ;
	  else
	    filclose (currfil) ;
	}
      for (kpar = stream[streamlevel].npar ; kpar-- ;)
	popText (parStack) ;
      --streamlevel ;
      currfil = stream[streamlevel].fil ;
      currtext = stream[streamlevel].text ;
      freespecial (stream[streamlevel].special) ;
    }
}

/************************************************/
/* freeword(), freewordcut() and freestep() are the only calls that
     directly move pos forward -- all others act via freeword().
   freeback() moves pos back one word.
*/
 
char *freeword (void)
{
  unsigned char *cw ;
 
  _losewhite ;             /* needed in case of intervening freestep() */

  if (_stepover ('"'))
    { for (cw = word ; !_stepover('"') && *pos ; *cw++ = *pos++)
	if (_stepover('\\'))	/* accept next char unless end of line */
	  if (!*pos)
	    break ;
      _losewhite ;
      *cw = 0 ;
      return (char*) word ;	/* always return a word, even if empty */
    }

		/* default: break on space and \t, not on comma */
  for (cw = word ; isgraph (*pos) && *pos != '\t' ; *cw++ = *pos++)
    if (_stepover('\\'))	/* accept next char unless end of line */
      if (!*pos)
	break ;
  _losewhite ;
  *cw = 0 ;
  return *word ? (char*) word : 0 ;
}
 
/************************************************/

#if defined(WIN32)

char *freepath (void)
{
  unsigned char *cw ;
 
  _losewhite ;             /* needed in case of intervening freestep() */

  if (_stepover ('"'))
    { for (cw = word ; !_stepover('"') && *pos ; *cw++ = *pos++)
	if (_stepover('\\'))	/* accept next char unless end of line */
	  if (!*pos)
	    break ;
      _losewhite ;
      *cw = 0 ;
      return (char*) word ;	/* always return a word, even if empty */
    }

  /* default: break on space, \t or end of line, not on comma
	 also, does not skip over backslashes which are assumed to be
	 MS DOS/Windows path delimiters */
  for (cw = word ; ( *pos == '\\' || isgraph (*pos) ) && *pos != '\t' ; *cw++ = *pos++) ;
  _losewhite ;
  *cw = 0 ;
  return *word ? (char*) word : 0 ;
}

#endif
 
/************************************************/
 
char *freewordcut (char *cutset, char *cutter)
        /* Moves along card, looking for a character from cut, which is a
           0-terminated char list of separators.
           Returns everything up to but not including the first match.
           pos is moved one char beyond the character.
           *cutter contains the char found, or if end of card is reached, 0.
        */
{ unsigned char *cc,*cw ;
 
  for (cw = word ; *pos ; *cw++ = *pos++)
    for (cc = (unsigned char *) cutset ; *cc ; ++cc)
      if (*cc == *pos)
        goto wcut ;
wcut:
  *cutter = *pos ;
  if (*pos)
    ++pos ;
  _losewhite ;
  *cw = 0 ;
  return *word ? (char*) word : 0 ;
}
 
/************************************************/
 
void freeback (void)    /* goes back one word - inefficient but reliable */
 
 {unsigned char *now = pos ;
  unsigned char *old = pos ;
 
  pos = card ; _losewhite ;
  while  (pos < now)
   {old = pos ;
    freeword () ;
   }
  pos = old ;
 }
 
/************************************************/

#define NON_INT -(1<<30)
#define NON_FLOAT -(1<<30)
 
BOOL freeint (int *p)
 
 {unsigned char *keep = pos ;
  unsigned char *cp ;
  int value = 0 ;
  BOOL isMinus = FALSE ;
 
  if (freeword ())
    { /*printf ("freeint got '%s'\n", word) ;*/
      cp = word ;
      if (!strcmp ((char*)cp, "NULL"))
	{ *p = NON_INT ;
	  return TRUE ;
	}
      if (*cp == '-')
        { isMinus = TRUE ;
          ++cp ;
        }
      while (*cp)
      	{ if (*cp >= '0' && *cp <= '9')
      	    value = value*10 + (*cp++ - '0') ;
      	  else
      	    { pos = keep ;
      	      return FALSE ;
      	    }
      	 }
   	  *p = isMinus ? -value : value ;
      return (TRUE) ;
    }
  else
    { pos = keep ;
      return (FALSE) ;
    }
 }
 
/*****************************/
 
BOOL freefloat (float *p)
{
  unsigned char *keep = pos ;
  float old = *p ;
  char dummy ; 
 
  if (freeword ())
    { if (!strcmp ((char*)word, "NULL"))
	{ *p = NON_FLOAT ;
	  return TRUE ;
	}
      if (sscanf ((char*) word,"%f%c",p,&dummy) == 1)
	return (TRUE) ;
    }

  pos = keep ;
  *p = old ;
  return (FALSE) ;
}
 
/**************************************************/
 
BOOL freedouble (double *p)
{ 
  unsigned char *keep = pos ;
  double old = *p ;
  char dummy ;
 
  if (freeword () && (sscanf ((char*) word,"%lf%c",p,&dummy) == 1))
    return (TRUE) ;
  else
    { pos = keep ;
      *p = old ;
      return (FALSE) ;
    }
}
 
/*************************************************/
 
static int ambiguouskey;
 
BOOL freekey (KEY *kpt, FREEOPT *options)
{
  unsigned char  *keep = pos ;

  if (!freeword())
    return FALSE ;

  if (freekeymatch ((char*) word, kpt, options))
    return TRUE;
 
  if (ambiguouskey)
    messout ("Keyword %s is ambiguous",word) ;
  else if (word[0] != '?')
    messout ("Keyword %s does not match",word) ;
 
  pos = keep ;
  return FALSE ;
}
 
/*****************/
 
BOOL freekeymatch (char *cp, KEY *kpt, FREEOPT *options)
{
  char  *io,*iw ;
  int   nopt = (int)options->key ;
  KEY   key ;
 
  ambiguouskey = FALSE;
  if (!nopt || !cp)
    return FALSE ;
 
  while (TRUE)
    { iw = cp ;
      io = (++options)->text ;

      while (freeupper (*iw++) == freeupper(*io++))
	if (!*iw)
	  goto foundit ;
      if (!--nopt)
        return FALSE ;
    }
 
foundit :
  key = options->key ;
 
  if (*io && *io != ' ')		/* not a full word match */
    while (--nopt)	/* check that later options are different */
      { io = (++options)->text ;
	iw = (char*) word ;
	while (freeupper (*iw++) == freeupper (*io++))
	  if (!*iw)
	    { ambiguouskey = TRUE;
	      return FALSE ;
	    }
      }
 
  *kpt = key ;
  return TRUE ;
}
 
/***************************************************/
  /* Return the text corresponding to the key */
char *freekey2text (KEY k, FREEOPT *o)  
{ int i = o->key ; char *title = o->text ;
  if (i<0)
    messcrash("Negative number of options in freekey2text") ;
  while (o++, i--) 
    if (o->key == k)
      return (o->text) ;
  return title ;
}

/***************************************************/
 
BOOL freeselect (KEY *kpt, FREEOPT *options)     /* like the old freemenu */
{
  if (isInteractive)
    printf ("%s > ",options[0].text) ;
  freecard (0) ;                       /* just get a card */
  if (isInteractive)
    while (freestep ('?'))            /* write out options list */
      { int i ;
	for (i = 1 ; i <= options[0].key ; i++)
	  printf ("  %s\n",options[i].text) ;
	printf ("%s > ",options[0].text) ;
	freecard (0) ;
      }
  return freekey (kpt,options) ;
}
  /* same but returns TRUE, -1, if stremlevel drops below level */
BOOL freelevelselect (int level, KEY *kpt, FREEOPT *options)     /* like the old freemenu */
{
  if (isInteractive)
    printf ("%s > ",options[0].text) ;
  if (!freecard (level)) /* try to get another card */
    { *kpt = (KEY)(-1) ;  
      return TRUE ;                       
    }
  if (isInteractive)
    while (freestep ('?'))            /* write out options list */
      { int i ;
	for (i = 1 ; i <= options[0].key ; i++)
	  printf ("  %s\n",options[i].text) ;
	printf ("%s > ",options[0].text) ;
	if (!freecard (level)) /* try to get another card */
	 { *kpt = (KEY)(-1) ;  
	   return TRUE ;                       
	 }
       }
  return freekey (kpt,options) ;
} 

/**************************************/
 
BOOL freequery (char *query)
{
  if (isInteractive)
    { int retval, answer = 0 ;
      printf ("%s (y or n) ",query) ;
      answer = getchar () ;
      retval = (answer == 'y' || answer == 'Y') ? TRUE : FALSE ;
      while (answer != (unsigned char) EOF &&
	     answer != -1 && /* mieg: used not to break on EOF in pipes */
	     answer != '\n')
        answer = getchar () ;
      return retval ;
    }
  else
    return TRUE ;
}
 
/**********/
 
BOOL freeprompt (char *prompt, char *dfault, char *fmt)
{ 
  if (isInteractive)
    printf("%s ? > ",prompt);
  freecard (0) ;                       /* just get a card */
  if (freecheck (fmt))
    return TRUE ;
  else
    { messout ("input mismatch : format '%s' expected, card was\n%s",
	       fmt, card) ;
      return FALSE ;
   }
}
 
/*************************************/
 
int freefmtlength (char *fmt)
 
 {char *cp ;
  int length = 0 ;
 
  if (isdigit((int)*fmt))
   {sscanf (fmt,"%d",&length) ;
    return length ;
   }
 
  for (cp = fmt ; *cp ; ++cp)
    switch (*cp)
     {
case 'i' : case 'f' : case 'd' : length += 8 ; break ;
case 'w' : length += 32 ; break ;
case 't' : length += 80 ; break ;
case 'o' :
      if (*++cp)
        messcrash ("'o' can not end free format %s",fmt) ;
      length += 2 ; break ;
     }
 
  if (!length)
    length = 40 ;
  return length ;
 }
 
/****************/
 
BOOL freecheck (char *fmt)
        /* checks that whatever is in card fits specified format
           note that 't' format option changes card by inserting a '"' */
 {unsigned char *keep = pos ;
  union {int i ; float r ; double d ;}
          target ;
  char *fp ;
  unsigned char *start ;
  int nquote = 1 ;
 
  for (fp = fmt ; *fp ; ++fp)
    switch (*fp)
     {
case 'w' : if (freeword ()) break ; else goto retFALSE ;
case 'i' : if (freeint (&target.i)) break ; else goto retFALSE ;
case 'f' : if (freefloat (&target.r)) break ; else goto retFALSE ;
case 'd' : if (freedouble (&target.d)) break ; else goto retFALSE ;
case 't' :      /* must insert '"' and escape any remaining '"'s or '\'s */
      for (start = pos ; *pos ; ++pos)
        if (*pos == '"' || *pos == '\\')
          ++nquote ;
      *(pos+nquote+1) = '"' ;		/* end of line */
      for ( ; pos >= start ; --pos)
	{ *(pos + nquote) = *pos ;
	  if (*pos == '"' || *pos == '\\')
	    *(pos + --nquote) = '\\' ;
        }
      *start = '"' ;
      goto retTRUE ;
case 'z' : if (freeword ()) goto retFALSE ; else goto retTRUE ;
case 'o' :
      if (!*++fp) messcrash ("'o' can not end free format %s",fmt) ;
      freestep (*fp) ; break ;
case 'b' : break; /* special for graphToggleEditor no check needed  il */
default :
      if (!isdigit((int)*fp) && !isspace((int)*fp))
        messerror ("unrecognised char %d = %c in free format %s",
		   *fp, *fp, fmt) ;
     }
 
retTRUE :
  pos = keep ; return TRUE ;
retFALSE :
  pos = keep ; return FALSE ;
 }
 
/************************ little routines ************************/
 
BOOL freestep (char x)
 {return (*pos && freeupper (*pos) == x && pos++) ;
 }
 
void freenext (void)
 {_losewhite ;
 }
 
char FREE_UPPER[] =
{ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
  16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
  32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,
  48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,
  64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,
  80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,
  96,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,
  80,81,82,83,84,85,86,87,88,89,90,123,124,125,126,127
} ;

char FREE_LOWER[] =
{  0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15, 
  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  
  32,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,  
  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,  
  64,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,  91,  92,  93,  94,  95,
  96,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127
} ;

char* freepos (void)		/* cheat to give pos onwards */
{ return (char*) pos ;
}

#ifdef JUNK
/* we want a more direct reciprocal to free protect */
char* freeunprotect (char *text)
{ int level ; char *cp ;
  static Stack s = 0 ;

  if (!text || !*text) return 0 ;
  s = stackReCreate (s, 80) ;
  level = freesettext (text,"") ;
  freespecial ("\t\\") ;    /* No \n, no subshells, No attach, No %, Nothing */
  freecard(level) ; 
  while ((cp = freeword()))
    { if (stackMark(s)) catText (s, " ") ; 
      catText (s, cp); 
    }
  freeclose (level) ;
  return stackMark (s) ? stackText (s, 0) : "" ; /* is text is not 0, do not return 0 */
}
#endif
char* freeunprotect (char *text)
{
  static char *buf = 0 ;
  char *cp, *cp0, *cq ;
  messfree (buf) ;
  buf = strnew(text ? text : "", 0) ;

  /* remove external space and tabs and first quotes */
  cp = buf ;
  while (*cp == ' ' || *cp == '\t') cp++ ;
  if (*cp == '"') cp++ ;
  while (*cp == ' ' || *cp == '\t') cp++ ;

  cq = cp + strlen(cp) - 1 ;
  while (cq > cp && (*cp == ' ' || *cq == '\t')) *cq-- = 0 ;
  if (*cq == '"') /* remove one unprotected quote */
    {
      int i = 0 ; char *cr = cq - 1 ;
      while (cr > cp && *cr == '\\')
	{ i++ ; cr-- ; }
      if ( i%2 == 0)
	*cq-- = 0 ;  /* discard */
    }
  while (cq > cp && (*cp == ' ' || *cq == '\t')) *cq-- = 0 ;

  /* gobble the \ */
  cp0 = cq = cp-- ;
  while (*++cp)
    switch (*cp)
      {
      case '\\': 
	if (*(cp+1) == '\\') { cp++ ; *cq++ = '\\' ; break ;}
	if (*(cp+1) == '\n') { cp ++ ; break ; } /* skip backsalh-newline */
	if (*(cp+1) == 'n') { cp ++ ; *cq++ = '\n' ; break ; }
	break ;
      default: *cq++ = *cp ;
      }
  *cq = 0 ;   /* terminate the string */
  return cp0 ;
}

char* freeprotect (char* text)	/* freeword will read result back as text */
{
  static Array a = 0 ;
  char *cp, *cq ;
  int base ;

		/* code to make this efficiently reentrant */

  if (a && text >= arrp(a,0,char) && text < arrp(a,arrayMax(a),char))
    { base = text - arrp(a,0,char) ;
      array (a, base+3*(1+strlen(text)), char) = 0 ; /* ensure long enough */
      text = arrp(a,0,char) + base ;            /* may have relocated */
      base += 1 + strlen(text) ;
    }
  else
    { a = arrayReCreate (a, 128, char) ;
      base = 0 ;
      array (a, 2*(1+strlen(text)), char) = 0 ; /* ensure long enough */
    }

  cq = arrp (a, base, char) ;
  *cq++ = '"' ;
  for (cp = text ; *cp ; *cq++ = *cp++)
    { if (*cp == '\\' || *cp == '"' || 		       /* protect these */
	  *cp == '/' || *cp == '%' || *cp == ';' ||
	  *cp == '\t' || *cp == '\n')
	*cq++ = '\\' ;
      if (*cp == '\n') {*cq++ = 'n' ; *cq++ = '\\' ; } /* -> /n/n (text then real) */
    }
  *cq++ = '"' ;
  *cq = 0 ;
  return arrp (a, base, char) ;
}

char* freejavaprotect (char* text)	/* freeword will read result back as text */
{
  static Array a = 0 ;
  char *cp, *cq ;
  int base ;

		/* code to make this efficiently reentrant */

  if (a && text >= arrp(a,0,char) && text < arrp(a,arrayMax(a),char))
    { base = text - arrp(a,0,char) ;
      array (a, base+3*(1+strlen(text)), char) = 0 ; /* ensure long enough */
      text = arrp(a,0,char) + base ;            /* may have relocated */
      base += 1 + strlen(text) ;
    }
  else
    { a = arrayReCreate (a, 128, char) ;
      base = 0 ;
      array (a, 2*(1+strlen(text)), char) = 0 ; /* ensure long enough */
    }

  cq = arrp (a, base, char) ;
  cp = text;
#ifdef JUNK
  while (*cp) {
    if (*cp == '\t' || *cp == '\n' || *cp == '\r') {
      *cq++ = '\\' ;
      switch (*cp) {
      case '\t':
	*cq++ = 't';
	break;
      case '\n':
	*cq++ = 'n';
	break;
      case '\r':
	*cq++ = 'r';
	break;
      default:
	;
      }
      cp++; /* skip this character */
    } 
    else {
      if (*cp == '?') *cq++ = '\\';
      *cq++ = *cp++;
    }
  }
#endif
  while (*cp) 
    switch (*cp)
      {
      case '\n':
	*cq++ = '\\';
	*cq++ = 'n';
	cp++;
	break;
      case '\\': case '?':
	*cq++ = '\\' ;
	/* fall thru */
      default:
	*cq++ = *cp++;
      }
  *cq = 0 ;
  return arrp (a, base, char) ;
}

/*********** end of file *****************/
 
 
