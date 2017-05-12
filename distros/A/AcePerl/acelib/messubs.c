/*  File: messubs.c
 *  Author: Richard Durbin (rd@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1992
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: low level: encapsulates vararg messages, *printf,
 *			crash handler,
 *
 * Exported functions: see regular.h
 *
 * HISTORY:
 * Last edited: Nov 27 15:36 1998 (fw)
 * * Nov 19 13:26 1998 (edgrif): Removed the test for errorCount and messQuery
 *              in messerror, really the wrong place.
 * * Oct 22 15:26 1998 (edgrif): Replaced strdup's with strnew.
 * * Oct 21 15:07 1998 (edgrif): Removed messErrorCount stuff from graphcon.c
 *              and added to messerror (still not perfect), this was a new.
 *              bug in the message system.
 * * Sep 24 16:47 1998 (edgrif): Remove references to ACEDB in messages,
 *              change messExit prefix to "EXIT: "
 * * Sep 22 14:35 1998 (edgrif): Correct errors in buffer usage by message
 *              outputting routines and message formatting routines.
 * * Sep 11 09:22 1998 (edgrif): Add messExit routine.
 * * Sep  9 16:52 1998 (edgrif): Add a messErrorInit function to allow an
 *              application to register its name for use in crash messages.
 * * Sep  3 11:32 1998 (edgrif): Rationalise strings used as prefixes for
 *              messages. Add support for new messcrash macro to replace
 *              messcrash routine, this includes file/line info. for
 *              debugging (see regular.h for macro def.) and a new
 *              uMessCrash routine.
 * * Aug 25 14:51 1998 (edgrif): Made BUFSIZE enum (shows up in debugger).
 *              Rationalise the use of va_xx calls into a single macro/
 *              function and improve error checking on vsprintf.
 *              messdump was writing into messbuf half way up, I've stopped
 *              this and made two buffers of half the original size, one for
 *              messages and one for messdump.
 * * Aug 21 13:43 1998 (rd): major changes to make clean from NON_GRAPHICS
 *              and ACEDB.  Callbacks can be registered for essentially
 *              all functions.  mess*() versions continue to centralise
 *              handling of ... via stdarg.
 * * Aug 20 17:10 1998 (rd): moved memory handling to memsubs.c
 * * Jul  9 11:54 1998 (edgrif): 
 *              Fixed problem with SunOS not having strerror function, system
 *              is too old to have standard C libraries, have reverted to
 *              referencing sys_errlist for SunOS only.
 *              Also fixed problem with getpwuid in getLogin function, code
 *              did not check return value from getpwuid function.
 * * Jul  7 10:36 1998 (edgrif):
 *      -       Replaced reference to sys_errlist with strerror function.
 * * DON'T KNOW WHO MADE THESE CHANGES...NO RECORD IN HEADER....(edgrif)
 *      -       newformat added for the log file on mess dump.
 *      -       Time, host and pid are now always the first things written.
 *      -       This is for easier checking og the log.wrm with scripts etc.
 *      -       Messquery added for > 50 minor errors to ask if user wants to crash.
 *      -       Made user,pid and host static in messdump.
 * * Dec  3 15:52 1997 (rd)
 * 	-	messout(): defined(_WINDOW) =>!defined(NON_GRAPHIC)
 * * Dec 16 17:26 1996 (srk)
 * * Aug 15 13:29 1996 (srk)
 *	-	WIN32 and MACINTOSH: seteuid() etc. are stub functions
 * * Jun 6 10:50 1996 (rbrusk): compile error fixes
 * * Jun  4 23:31 1996 (rd)
 * Created: Mon Jun 29 14:15:56 1992 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: messubs.c,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#include <assert.h>
#include <errno.h>
#include "regular.h"
#include "freeout.h"				  /* messbeep uses freeOutF */



/* This is horrible...a hack for sunos which is not standard C compliant.    */
/* to allow accessing system library error messages, will disappear....      */
#ifdef SUN
extern const char *sys_errlist[] ;
#endif


/* Mac has its own routine for crashing, see messcrash for usage.            */
#if !defined(MACINTOSH) 
extern void crashOut (char* text) ;
#endif



/* This buffer is used only by the routines that OUTPUT a message. Routines  */
/* that format messages into buffers (e.g. messprintf, messSysErrorText)     */
/* have their own buffers. Note that there is a problem here in that this    */
/* buffer can be overflowed, unfortunately because we use vsprintf to do     */
/* our formatting, this can only be detected after the event.                */
/*                                                                           */
/* Constraints on message buffer size - applicable to ALL routines that      */
/* format externally supplied strings.                                       */
/*                                                                           */
/* BUFSIZE:  size of message buffers (messbuf, a global buffer for general   */
/*           message stuff and a private ones in messdump & messprintf).     */
/* PREFIX:   length of message prefix (used to report details such as the    */
/*           file/line info. for where the error occurred.                   */
/* MAINTEXT: space left in buffer is the rest after the prefix and string    */
/*           terminator (NULL) are subtracted.                               */
/* Is there an argument for putting this buffer size in regular.h ??         */
/*                                                                           */
enum {BUFSIZE = 32768, PREFIXSIZE = 1024, MAINTEXTSIZE = BUFSIZE - PREFIXSIZE - 1} ;

static char messbuf[BUFSIZE] ;



/* Macro to format strings using va_xx calls, it calls uMessFormat whose     */
/* prototype is given below.                                                 */
/*                                                                           */
/* Arguments to the macro must have the following types:                     */
/*                                                                           */
/*   FORMAT_ARGS:   va_list used to get the variable argument list.          */
/*        FORMAT:   char *  to a string containing the printf format string. */
/*    TARGET_PTR:   char *  the formatted string will be returned in this    */
/*                          string pointer, N.B. do not put &TARGET_PTR      */
/*        PREFIX:   char *  to a string to be used as a prefix to the rest   */
/*                          of the string, or NULL.                          */
/*        BUFFER:   char *  the buffer where the formatting will take place, */
/*                          if NULL then the global messbuf buffer will be   */
/*                          used.                                            */
/*        BUFLEN:   unsigned                                                 */
/*                     int  the length of the buffer given by BUFFER (ignored*/
/*                          if BUFFER is NULL.                               */
/*                                                                           */
#define ACEFORMATSTRING(FORMAT_ARGS, FORMAT, TARGET_PTR, PREFIX, BUFFER, BUFLEN)  \
va_start(FORMAT_ARGS, FORMAT) ;                                                   \
TARGET_PTR = uMessFormat(FORMAT_ARGS, FORMAT, PREFIX, BUFFER, BUFLEN) ;           \
va_end(FORMAT_ARGS) ;

static char *uMessFormat(va_list args, char *format, char *prefix,
			 char *buffer, unsigned int buflen) ;


/* Some standard defines for titles/text for messages:                       */
/*                                                                           */
#define ERROR_PREFIX "ERROR: "
#define EXIT_PREFIX "EXIT: "
#define CRASH_PREFIX_FORMAT "FATAL ERROR reported by %s at line %d: "
#define FULL_CRASH_PREFIX_FORMAT "FATAL ERROR reported by program %s, in file %s, at line %d: "
#if defined(MACINTOSH)
#define SYSERR_FORMAT "system error %d"
#else
#define SYSERR_FORMAT "system error %d - %s"
#endif
#define PROGNAME "The program"

/* messcrash now reports the file/line no. where the messcrash was issued    */
/* as an aid to debugging. We do this using a static structure which holds   */
/* the information and a macro version of messcrash (see regular.h), the     */
/* structure elements are retrieved using access functions.                  */
typedef struct _MessErrorInfo
  {
  char *progname ;				  /* Name of executable reporting error. */
  char *filename ;				  /* Filename where error reported */
  int line_num ;				  /* Line number of file where error
						     reported. */
  } MessErrorInfo ;

static MessErrorInfo messageG = {NULL, NULL, 0} ;

static int messGetErrorLine() ;
static char *messGetErrorFile() ;


/* Keeps a running total of errors so far (incremented whenever messerror is */
/* called).                                                                  */
static int errorCount_G = 0 ;


/* Function pointers for application supplied routines that are called when  */
/* ever messerror or messcrash are called, enables application to take       */
/* action on all such errors.                                                */
static jmp_buf *errorJmpBuf = 0 ;
static jmp_buf *crashJmpBuf = 0 ;



/***************************************************************/
/********* call backs and functions to register them ***********/

static VoidRoutine	  beepRoutine = 0 ;
static OutRoutine	  outRoutine = 0 ;
static OutRoutine	  dumpRoutine = 0 ;
static OutRoutine	  errorRoutine = 0 ;
static OutRoutine	  exitRoutine = 0 ;
static OutRoutine	  crashRoutine = 0 ;
static QueryRoutine	  queryRoutine = 0 ;
static PromptRoutine	  promptRoutine = 0 ;
static IsInterruptRoutine isInterruptRoutine = 0 ;

UTIL_FUNC_DEF VoidRoutine messBeepRegister (VoidRoutine func)
{ VoidRoutine old = beepRoutine ; beepRoutine = func ; return old ; }

UTIL_FUNC_DEF OutRoutine messOutRegister (OutRoutine func)
{ OutRoutine old = outRoutine ; outRoutine = func ; return old ; }

UTIL_FUNC_DEF OutRoutine messDumpRegister (OutRoutine func)
{ OutRoutine old = dumpRoutine ; dumpRoutine = func ; return old ; }

UTIL_FUNC_DEF OutRoutine messErrorRegister (OutRoutine func)
{ OutRoutine old = errorRoutine ; errorRoutine = func ; return old ; }

UTIL_FUNC_DEF OutRoutine messExitRegister (OutRoutine func)
{ OutRoutine old = exitRoutine ; exitRoutine = func ; return old ; }

UTIL_FUNC_DEF OutRoutine messCrashRegister (OutRoutine func)
{ OutRoutine old = crashRoutine ; crashRoutine = func ; return old ; }

UTIL_FUNC_DEF QueryRoutine messQueryRegister (QueryRoutine func)
{ QueryRoutine old = queryRoutine ; queryRoutine = func ; return old ; }

UTIL_FUNC_DEF PromptRoutine messPromptRegister (PromptRoutine func)
{ PromptRoutine old = promptRoutine ; promptRoutine = func ; return old ; }

UTIL_FUNC_DEF IsInterruptRoutine messIsInterruptRegister (IsInterruptRoutine func)
{ IsInterruptRoutine old = isInterruptRoutine ; isInterruptRoutine = func ; return old ; }



/***************************************************/
UTIL_FUNC_DEF BOOL messIsInterruptCalled (void)
{
  if (isInterruptRoutine)
    return (*isInterruptRoutine)() ;

  /* unless a routine is registered, we assume no interrupt
     (e.g. F4 keypress in graph-window) has been called */
  return FALSE;
}


/* The message output routines.                                              */
/*                                                                           */
/*                                                                           */


/***************************************************/
UTIL_FUNC_DEF void messbeep (void)
{
  if (beepRoutine)
    (*beepRoutine)() ;
  else
    { freeOutf ("%c",0x07) ;  /* bell character, I hope */
      fflush (stdout) ;	/* added by fw 02.Feb 1994 */
    }
}


/*******************************/
UTIL_FUNC_DEF void messout (char *format,...)
{
  va_list args ;
  char *mesg_buf ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, NULL, NULL, 0)

  if (outRoutine)
    (*outRoutine)(mesg_buf) ;
  else
    fprintf (stdout, "//!! %s\n", mesg_buf) ;

}

/*****************************/

UTIL_FUNC_DEF BOOL messPrompt (char *prompt, char *dfault, char *fmt)
{ 
  BOOL answer ;
  
  if (promptRoutine)
    answer = (*promptRoutine)(prompt, dfault, fmt) ;
  else
    answer = freeprompt (prompt, dfault, fmt) ;

  return answer ;
}

/*****************************/

UTIL_FUNC_DEF BOOL messQuery (char *format,...)
{ 
  BOOL answer ;
  char *mesg_buf = NULL ;
  va_list args ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, NULL, NULL, 0)

  if (queryRoutine)
    answer = (*queryRoutine)(mesg_buf) ;
  else
    answer = freequery (mesg_buf) ;

  return answer ;
}

/*****************************************************************/

UTIL_FUNC_DEF void messdump (char *format,...)
{
  static char dumpbuf[BUFSIZE] ;		  /* BEWARE limited buffer size. */
  char *mesg_buf ;
  va_list args ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, NULL, &dumpbuf[0], BUFSIZE)

  strcat (mesg_buf, "\n") ;			  /* assume we are writing to a file */

  if (dumpRoutine)
    (*dumpRoutine)(mesg_buf) ;
}


/*****************************************/


/* Access function for returning running error total.                        */
UTIL_FUNC_DEF int messErrorCount (void) { return errorCount_G ; }


/* Output a non-fatal error message, for all messages a call to messdump is  */
/* made which may result in the message being logged. The single error count */
/* is also incremented so that functions can use this to check how many      */
/* errors have been recorded so far.                                         */
UTIL_FUNC_DEF void messerror (char *format, ...)
{
  char *prefix = ERROR_PREFIX ;
  char *mesg_buf = NULL ;
  va_list args ;

  /* always increment the error count.                                       */
  ++errorCount_G ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, prefix, NULL, 0) ;

  /* If application registered an error handler routine, call it.            */
  if (errorJmpBuf)
    longjmp (*errorJmpBuf, 1) ;

  /* Log the message.                                                        */
  messdump(mesg_buf) ;

  /* Now report the error to the user.                                       */
  if (errorRoutine)
    (*errorRoutine)(mesg_buf) ;
  else
    fprintf (stderr, "%s\n", mesg_buf) ;

  invokeDebugger () ;
}



/*******************************/

/* Use this function for errors that while being unrecoverable are not a     */
/* problem with the acedb code, e.g. if the user starts xace without         */
/* specifying a database.                                                    */
/* Note that there errors are logged but that this routine will exit without */
/* any chance to interrupt it (e.g. the crash routine in uMessCrash), this   */
/* could be changed to allow the application to register an exit handler.    */
/*                                                                           */
UTIL_FUNC_DEF void messExit(char *format, ...)
  {
  char *prefix = EXIT_PREFIX ;
  char *mesg_buf = NULL ;
  va_list args ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, prefix, NULL, 0) ;

  if (exitRoutine)
    (*exitRoutine)(mesg_buf) ;
  else
    fprintf (stderr, "%s\n", mesg_buf) ;

#if defined(MACINTOSH)
  crashOut(mesg_buf) ;
#else
  messdump(mesg_buf) ;

  exit(EXIT_FAILURE) ;
#endif

  return ;					  /* Should never get here. */
  }


/*******************************/

/* This is the routine called by the messcrash macro (see regular.h) which   */
/* actually does the message/handling and exit.                              */
/* This routine may encounter errors itself, in which case it will attempt   */
/* to call itself to report the error. To avoid infinite recursion we limit  */
/* this to just one reporting of an internal error and then we abort.        */
/*                                                                           */
UTIL_FUNC_DEF void uMessCrash(char *format, ...)
  {
  enum {MAXERRORS = 1} ;
  static int internalErrors = 0 ;
  static char prefix[1024] ;
  int rc ;
  char *mesg_buf = NULL ;
  va_list args ;

  /* Check for recursive calls and abort if necessary.                       */
  if (internalErrors > MAXERRORS) 
    {
      fprintf (stderr, "%s : fatal internal error, abort", 
	       messageG.progname);
      abort() ;
    }
  else internalErrors++ ;

  /* Construct the message prefix, adding the program name if possible.      */
  if (messGetErrorProgram() == NULL)
       rc = sprintf(prefix, CRASH_PREFIX_FORMAT, messGetErrorFile(), messGetErrorLine()) ;
  else
       rc = sprintf(prefix, FULL_CRASH_PREFIX_FORMAT,
		    messGetErrorProgram(), messGetErrorFile(), messGetErrorLine()) ;
  if (rc < 0) messcrash("sprintf failed") ;


  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, prefix, NULL, 0) ;


  if (crashJmpBuf)		/* throw back up to the function that registered it */
    longjmp(*crashJmpBuf, 1) ;

  
#if defined(MACINTOSH)
  crashOut(mesg_buf) ;
#else
  messdump(mesg_buf) ;

  if (crashRoutine)
    (*crashRoutine)(mesg_buf) ;
  else
    fprintf(stderr, "%s\n", mesg_buf) ;

  invokeDebugger() ;

  exit(EXIT_FAILURE) ;
#endif

  return ;					  /* Should never get here. */
  }





/******* interface to crash/error trapping *******/

UTIL_FUNC_DEF jmp_buf* messCatchError (jmp_buf* new)
{
  jmp_buf* old = errorJmpBuf ;
  errorJmpBuf = new ;
  return old ;
}

UTIL_FUNC_DEF jmp_buf* messCatchCrash (jmp_buf* new)
{
  jmp_buf* old = crashJmpBuf ;
  crashJmpBuf = new ;
  return old ;
}

UTIL_FUNC_DEF char* messCaughtMessage (void) { return messbuf ; }



/* Message formatting routines.                                              */
/*                                                                           */
/*                                                                           */

/* This function writes into its own buffer, note that this has finite size  */
/* see top of file: BUFSIZE, also note that subsequent calls will overwrite  */
/* this buffer.                                                              */
/*                                                                           */
UTIL_FUNC_DEF char *messprintf (char *format, ...)
  {
  static char buffer[BUFSIZE] ;
  char *mesg_buf ;
  va_list args ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, NULL, &buffer[0], BUFSIZE)

  return mesg_buf ;
}


/* Used internally for formatting into a specified buffer.                   */
/* (currently only used as a cover function to enable us to use ACEFORMAT-   */
/* STRING from messSysErrorText)                                             */
static char *printToBuf(char *buffer, unsigned int buflen, char *format, ...)
  {
  char *mesg_buf ;
  va_list args ;

  /* Format the message string.                                              */
  ACEFORMATSTRING(args, format, mesg_buf, NULL, buffer, buflen)

  return mesg_buf ;
  }



/* Return the string for a given errno from the standard C library.          */
/*                                                                           */
UTIL_FUNC_DEF char* messSysErrorText (void)
  {
  enum {ERRBUFSIZE = 2000} ;				    /* Should be enough. */
  static char errmess[ERRBUFSIZE] ;
  char *mess ;

#ifdef SUN
  /* horrible hack for Sunos/Macs(?) which are not standard C compliant */
  mess = printToBuf(&errmess[0], ERRBUFSIZE, SYSERR_FORMAT, errno, sys_errlist[errno]) ;
#elif defined(MACINTOSH)
  mess = printToBuf(&errmess[0], ERRBUFSIZE, SYSERR_FORMAT, errno) ;
#else
  mess = printToBuf(&errmess[0], ERRBUFSIZE, SYSERR_FORMAT, errno, strerror(errno)) ;
#endif

  return mess ;
  }


/************************* message formatting ********************************/
/* This routine does the formatting of the message string using vsprintf,    */
/* it copes with the format string accidentally being our internal buffer.   */
/*                                                                           */
/* This routine does its best to check that the vsprintf is successful, if   */
/* not the routine bombs out with an error message. Note that num_bytes is   */
/* the return value from vsprintf.                                           */
/* Failures trapped:                                                         */
/*              num_bytes < 0  =>  vsprintf failed, reason is reported.      */
/*    num_bytes + 1 > BUFSIZE  =>  our internal buffer size was exceeded.    */
/*                                 (vsprintf returns number of bytes written */
/*                                  _minus_ terminating NULL)                */
/*                                                                           */
static char *uMessFormat(va_list args, char *format, char *prefix,
			 char *buffer, unsigned int buflen)
{
  char *buf_ptr ;
  unsigned int buf_len ;
  int prefix_len ;


  /* Check arguments.                                                        */
  if (format == NULL)
    { 
      fprintf(stderr, "uMessFormat() : "
	      "invalid call, no format string.\n") ;
      invokeDebugger();
      exit (EXIT_FAILURE);
    }

  if (prefix == NULL) 
    prefix_len = 0 ;
  else
    {
      prefix_len = strlen(prefix) ;
      if ((prefix_len + 1) > PREFIXSIZE) 
	{
	  fprintf (stderr, "uMessFormat() : "
		   "prefix string is too long.\n") ;
	  invokeDebugger();
	  exit (EXIT_FAILURE);
	}
    }

  /* If they supply their own buffer to receive the formatted 
     message then use this, otherwise use the global messbuf buffer. */
  if (buffer != NULL)
    {
      buf_ptr = buffer ;
      buf_len = buflen ;
      if (buf_len == 0) 
	{
	  fprintf (stderr, "uMessFormat() : "
		   "zero length buffer supplied for message format.\n") ;
	  invokeDebugger();
	  exit (EXIT_FAILURE);
	}
    }
  else
    {
      buf_ptr = &messbuf[0] ;
      buf_len = BUFSIZE ;
    }

  /* Add the prefix if there is one. */
  if (prefix != NULL)
    {
      if (strcpy (buf_ptr, prefix) == NULL) 
	{
	  fprintf (stderr, "uMessFormat() : strcpy failed\n") ;
	  invokeDebugger();
	  exit (EXIT_FAILURE);
	}
    }
  

  /* CHECK PERFORMANCE ISSUES....how is database dumped/logged.              */

  /* Fred has suggested that we could do a vprintf to /dev/null and see how  */
  /* many bytes that is then we could get away from a fixed internal buffer  */
  /* at all....but watch out, if messdump say is in a tight loop then this   */
  /* will kill performance...                                                */
  /* We could add a #define to allow a check to be included for debug code.  */
  /*                                                                         */


  /* Do the format. */

#ifdef SUN
  {
    char *return_str;

    /* NOTE, that SUNs vsprintf returns a char* */
    return_str = vsprintf((buf_ptr + prefix_len), format, args) + prefix_len + 1 ;
    
    /* Check the result. */
    if (!return_str)
      {
	fprintf(stderr, "uMessFormat() : "
		"vsprintf failed: %s\n", messSysErrorText()) ;
	invokeDebugger();
	exit (EXIT_FAILURE);
      }
    else if (strlen(return_str) > buf_len)
      {
	fprintf (stderr, "uMessFormat() : "
		 "messubs internal buffer size (%d) exceeded, "
		 "a total of %ld bytes were written\n",
		 buf_len, strlen(return_str)) ;  
	invokeDebugger();
	exit (EXIT_FAILURE);
      }
  }
#else  /* !SUN */
  {
    /* all other System's vsprintf returns an integer, of how many bytes have been written */
    int num_bytes = vsprintf((buf_ptr + prefix_len), format, args) + prefix_len + 1 ;
    
    /* Check the result.                                                       */
    if (num_bytes < 0)
      {
	fprintf(stderr, "uMessFormat() : "
		"vsprintf failed: %s\n", messSysErrorText()) ;
	invokeDebugger();
	exit (EXIT_FAILURE);
      }
    else if (num_bytes > buf_len)
      {
	fprintf (stderr, "uMessFormat() : "
		 "messubs internal buffer size (%d) exceeded, "
		 "a total of %d bytes were written\n",
		 buf_len, num_bytes) ;  
	invokeDebugger();
	exit (EXIT_FAILURE);
      }
  }
#endif /* !SUN */

  return(buf_ptr) ;
  }


/********************** crash file/line info routines ************************/
/* When the acedb needs to crash because there has been an unrecoverable     */
/* error we want to output the file and line number of the code that         */
/* detected the error. Here are the functions to do it.                      */
/*                                                                           */

/* Applications can optionally initialise the error handling section of the  */
/* message package, currently the program name can be set (argv[0] in the    */
/* main routine) as there is no easy way to get at this at run time except   */
/* from the main.                                                            */
/*                                                                           */
UTIL_FUNC_DEF void messErrorInit(char *progname)
  {

  if (progname != NULL) messageG.progname = strnew(filGetFilename(progname), 0) ;

  return ;
  }

/* This function is called by the messcrash macro which inserts the file and */
/* line information using the __FILE__ & __LINE__ macros.                    */
/*                                                                           */
UTIL_FUNC_DEF void uMessSetErrorOrigin(char *filename, int line_num)
{
  
  assert(filename != NULL && line_num != 0) ;
  
  /* We take the basename here because __FILE__ can be a path rather than    */
  /* just a filename, depending on how a module was compiled.                */
  messageG.filename = strnew(filGetFilename(filename), 0) ;
  
  messageG.line_num = line_num ;
}

/* mieg: protected these func against bad return, was crashing solaris server */
/* Access functions for message error data.                                  */
UTIL_FUNC_DEF char *messGetErrorProgram()
{
  return messageG.progname ?  messageG.progname : "programme_name_unknown"  ;
}  

static char *messGetErrorFile()
{
  return messageG.filename ? messageG.filename  : "file_name_unknown" ; 
}  

static int messGetErrorLine()
{
  return messageG.line_num ;
}  


/*****************************/

/* put "break invokeDebugger" in your favourite debugger init file */

UTIL_FUNC_DEF void invokeDebugger (void) 
{
  static BOOL reentrant = FALSE ;

  if (!reentrant)
    { reentrant = TRUE ;
      messalloccheck() ;
      reentrant = FALSE ;
    }
}




/*************************************************************************/
/************************** orphan function ******************************/

/* match to reg expression 

   returns 0 if not found
           1 + pos of first sigificant match (i.e. not a *) if found
*/

UTIL_FUNC_DEF int regExpMatch (char *cp,char *tp)
{
  char *c=cp, *t=tp;
  char *ts=0, *cs=0, *s = 0 ;
  int star=0;

  while (TRUE)
    switch(*t)
      {
      case '\0':
 	if(!*c)
	  return  ( s ? 1 + (s - cp) : 1) ;
	if (!star)
	  return 0 ;
        /* else not success yet go back in template */
	t=ts; c=cs+1;
	if(ts == tp) s = 0 ;
	break ;
      case '?' :
	if (!*c)
	  return 0 ;
	if(!s) s = c ;
        t++ ;  c++ ;
        break;
      case '*' :
        ts=t;
        while( *t == '?' || *t == '*')
          t++;
        if (!*t)
          return s ? 1 + (s-cp) : 1 ;
        while (freeupper(*c) != freeupper(*t))
          if(*c)
            c++;
          else
            return 0 ;
        star=1;
        cs=c;
	if(!s) s = c ;
        break;
      case 'A' :
	if (!*c || (*c < 'A' || *c > 'Z'))
	  return 0 ;
	if(!s) s = c ;
        t++ ;  c++ ;
        break;
      default  :
        if (freeupper(*t++) != freeupper(*c++))
          { if(!star)
              return 0 ;
            t=ts; c=cs+1;
	    if(ts == tp) s = 0 ;
          }
	else
	  if(!s) s = c - 1 ;
        break;
      }
}

/***************** another orphan function *********************/

#ifdef SGI			/* work around SGI library bug */
#include "math.h"
UTIL_FUNC_DEF double log10 (double x) { return log(x) / 2.3025851 ; }
#endif

/**** end of file ****/
