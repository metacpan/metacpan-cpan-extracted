/*  Last edited: Dec 21 13:45 1998 (fw) */

/* $Id: regular.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

/***************************************************************
 *  File regular.h  : header file for ACEDB utility functions                    
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1994
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * HISTORY:
 * Last edited: Aug 20 11:50 1997 (rbrusk)
 * * Sep  9 16:54 1998 (edgrif): Add messErrorInit decl.
 * * Sep  9 14:31 1998 (edgrif): Add filGetFilename decl.
 * * Aug 20 11:50 1998 (rbrusk): AUL_FUNC_DCL
 * * Sep  3 11:50 1998 (edgrif): Add macro version of messcrash to give
 *              file/line info for debugging.
 * Created: 1991 (rd)
 *-------------------------------------------------------------------
 */

#ifndef DEF_REGULAR_H
#define DEF_REGULAR_H

				/* library EXPORT/IMPORT symbols */
#if defined (WIN32)
#include "win32libspec.h"  /* must come before mystdlib.h...*/
#else
#define UTIL_FUNC_DCL
#define UTIL_VAR_DCL	extern
#define UTIL_FUNC_DEF
#define UTIL_VAR_DEF
#endif

#include "mystdlib.h"   /* contains full prototypes of system calls */

#if defined(WIN32)
#if defined(_DEBUG)
#define MEM_DEBUG /* must be defined here, before acelibspec.h */
#include <crtdbg.h>
#endif
UTIL_VAR_DCL char* linkDate ;
UTIL_VAR_DCL int isInteractive ;      /* can set FALSE, i.e. in tace */
#endif

#ifdef FALSE
  typedef int BOOL ;
#else
  typedef enum {FALSE=0,TRUE=1} BOOL ;
#endif



typedef unsigned char UCHAR ; /* for convenience */

typedef unsigned int KEY ;

typedef void (*VoidRoutine)(void) ;
typedef void (*Arg1Routine)(void *arg1) ;

/* magic_t : the type that all magic symbols are declared of.
   They become magic (i.e. unique) by using the pointer
   to that unique symbol, which has been placed somewhere
   in the address space by the compiler */
/* type-magics and associator codes are defined at
   magic_t MYTYPE_MAGIC = "MYTYPE";
   The address of the string is then used as the unique 
   identifier (as type->magic or graphAssXxx-code), and the
   string can be used during debugging */
typedef char* magic_t;



typedef struct freestruct
  { KEY  key ;
    char *text ;
  } FREEOPT ;


/*---------------------------------------------------------------------*/
/* The free package for reading from files/stdout, see freesubs.c      */
/*                                                                     */

UTIL_FUNC_DCL void freeinit (void) ;
UTIL_FUNC_DCL int freeCurrLevel(void) ;			    /* Returns current level. */
UTIL_FUNC_DCL char* freecard (int level) ;	/* 0 if below level (returned by freeset*) */
UTIL_FUNC_DCL void freecardback (void) ;  /* goes back one card */
UTIL_FUNC_DCL void freeforcecard (char *string);
UTIL_FUNC_DCL int  freesettext (char *string, char *parms) ; /* returns level to be used in freecard () */
UTIL_FUNC_DCL int  freesetfile (FILE *fil, char *parms) ;
UTIL_FUNC_DCL int  freesetpipe (FILE *fil, char *parms) ;  /* will call pclose */
UTIL_FUNC_DCL void freeclose(int level) ; /* closes the above */
UTIL_FUNC_DCL void freespecial (char *set) ;	/* set of chars to be recognized from "\n;/%\\@$" */
UTIL_FUNC_DCL BOOL freeread (FILE *fil) ;	/* returns FALSE if EOF */
UTIL_FUNC_DCL int  freeline (FILE *fil) ;	/* line number in file */
UTIL_FUNC_DCL int  freestreamline (int level) ;/* line number in stream(level)*/
UTIL_FUNC_DCL char *freeword (void) ;

#if defined(WIN32)  /* A variation to correctly parse MS DOS/Windows pathnames */
UTIL_FUNC_DCL   char *freepath (void) ;
#else	/* NOT defined(WIN32) */
#define freepath freeword  /* freeword() works fine if not in WIN32 */
#endif	/* defined(WIN32) */

UTIL_FUNC_DCL char *freewordcut (char *cutset, char *cutter) ;
UTIL_FUNC_DCL void freeback (void) ;		/* goes back one word */
UTIL_FUNC_DCL BOOL freeint (int *p) ;
UTIL_FUNC_DCL BOOL freefloat (float *p) ;
UTIL_FUNC_DCL BOOL freedouble (double *p) ;
UTIL_FUNC_DCL BOOL freekey (KEY *kpt, FREEOPT *options) ;
UTIL_FUNC_DCL BOOL freekeymatch (char *text, KEY *kpt, FREEOPT *options) ;
UTIL_FUNC_DCL void freemenu (void (*proc)(KEY), FREEOPT *options) ;
UTIL_FUNC_DCL char *freekey2text (KEY k, FREEOPT *o)  ;  /* Return text corresponding to key */
UTIL_FUNC_DCL BOOL freeselect (KEY *kpt, FREEOPT *options) ;
UTIL_FUNC_DCL BOOL freelevelselect (int level,
				    KEY *kpt, FREEOPT *options);
UTIL_FUNC_DCL void freedump (FREEOPT *options) ;
UTIL_FUNC_DCL BOOL freestep (char x) ;
UTIL_FUNC_DCL void freenext (void) ;
UTIL_FUNC_DCL BOOL freeprompt (char *prompt, char *dfault, char *fmt) ;/* gets a card */
UTIL_FUNC_DCL BOOL freecheck (char *fmt) ;	/* checks remaining card fits fmt */
UTIL_FUNC_DCL int  freefmtlength (char *fmt) ;
UTIL_FUNC_DCL BOOL freequery (char *query) ;
UTIL_FUNC_DCL char *freepos (void) ;		/* pointer to present position in card */
UTIL_FUNC_DCL char *freeprotect (char* text) ; /* protect so freeword() reads correctly */
UTIL_FUNC_DCL char* freeunprotect (char *text) ; /* reverse of protect, removes \ etc */

UTIL_VAR_DCL char FREE_UPPER[] ;
#define freeupper(x)	(FREE_UPPER[(x) & 0xff])  /* table is only 128 long */

UTIL_VAR_DCL char FREE_LOWER[] ;
#define freelower(x)	(FREE_LOWER[(x) & 0xff])




/**********************************************************************/
/******************** message routines - messubs.c ********************/
/**********************************************************************/

/* 'Internal' functions, do not call directly.                               */
UTIL_FUNC_DCL void uMessSetErrorOrigin(char *filename, int line_num) ;
UTIL_FUNC_DCL void uMessCrash(char *format, ...) ;

/* External Interface.                                                       */
/* Note that messcrash is a macro and that it makes use of the ',' operator  */
/* in C. This means that the messcrash macro will only produce a single C    */
/* statement and hence can be used within brackets etc. and will not break   */
/* existing code, e.g.                                                       */
/*                     funcblah(messcrash("hello")) ;                        */
/* will become:                                                              */
/* funcblah(uMessSetErrorOrigin(__FILE__, __LINE__), uMessCrash("hello")) ;  */
/*                                                                           */

UTIL_FUNC_DEF void messErrorInit (char *progname) ; /* Record the
					 applications name for use
					 in error messages, etc */
UTIL_FUNC_DEF char *messGetErrorProgram (void) ; /* Returns the
						    application name */

UTIL_FUNC_DCL char *messprintf (char *format, ...) ;	  
				/* sprintf into (static!) string */
				/* !!!! beware finite buffer size !!!! */

UTIL_FUNC_DCL void messbeep (void) ; /* make a beep */

UTIL_FUNC_DCL void messout (char *format, ...) ;  /* simple message */
UTIL_FUNC_DCL void messdump (char *format, ...) ; /* write to log file */
UTIL_FUNC_DCL void messerror (char *format, ...) ; /* error message and write to log file */
UTIL_FUNC_DCL void messExit(char *format, ...) ;  /* error message, write to log file & exit */
#define messcrash   uMessSetErrorOrigin(__FILE__, __LINE__), uMessCrash
						  /* abort - but see below */
UTIL_FUNC_DCL BOOL messQuery (char *text,...) ;	  /* ask yes/no question */
UTIL_FUNC_DCL BOOL messPrompt (char *prompt, char *dfault, char *fmt) ;
	/* ask for data satisfying format get results via freecard() */

UTIL_FUNC_DCL char* messSysErrorText (void) ; 
	/* wrapped system error message for use in messerror/crash() */

UTIL_FUNC_DCL int messErrorCount (void);
	/* return numbers of error so far */

UTIL_FUNC_DCL BOOL messIsInterruptCalled (void);
	/* return TRUE if an interrupt key has been pressed */

/**** registration of callbacks for messubs ****/

typedef void (*OutRoutine)(char*) ;
typedef BOOL (*QueryRoutine)(char*) ;
typedef BOOL (*PromptRoutine)(char*, char*, char*) ;
typedef BOOL (*IsInterruptRoutine)(void) ;

UTIL_FUNC_DCL VoidRoutine	messBeepRegister (VoidRoutine func) ;
UTIL_FUNC_DCL OutRoutine	messOutRegister (OutRoutine func) ;
UTIL_FUNC_DCL OutRoutine	messDumpRegister (OutRoutine func) ;
UTIL_FUNC_DCL OutRoutine	messErrorRegister (OutRoutine func) ;
UTIL_FUNC_DCL OutRoutine	messExitRegister (OutRoutine func) ;
UTIL_FUNC_DCL OutRoutine	messCrashRegister (OutRoutine func) ;
UTIL_FUNC_DCL QueryRoutine	messQueryRegister (QueryRoutine func) ;
UTIL_FUNC_DCL PromptRoutine	messPromptRegister (PromptRoutine func) ;
UTIL_FUNC_DCL IsInterruptRoutine messIsInterruptRegister (IsInterruptRoutine func) ;

/**** routines to catch crashes if necessary, e.g. when acedb dumping ****/

#include <setjmp.h>

UTIL_FUNC_DCL jmp_buf*	messCatchCrash (jmp_buf* ) ;
UTIL_FUNC_DCL jmp_buf*	messCatchError (jmp_buf* ) ;
UTIL_FUNC_DCL char*	messCaughtMessage (void) ;

  /* if a setjmp() stack context is set using messCatch*() then rather than
     exiting or giving an error message, messCrash() and messError() will
     longjmp() back to the context.
     messCatch*() return the previous value. Use argument = 0 to reset.
     messCaughtMessage() can be called from the jumped-to routine to get
     the error message that would have been printed.
  */

/********************************************************************/
/************** memory management - memsubs.c ***********************/
/********************************************************************/

typedef struct _STORE_HANDLE_STRUCT *STORE_HANDLE ; /* opaque outside memsubs.c */

UTIL_FUNC_DCL STORE_HANDLE handleHandleCreate (STORE_HANDLE handle) ;
#define handleCreate() handleHandleCreate(0)
#define handleDestroy(handle) messfree(handle)

#if defined(WIN32) && defined(_DEBUG)
#define MEM_DEBUG
#include <crtdbg.h>
#endif

#if !defined(MEM_DEBUG)

UTIL_FUNC_DCL void *handleAlloc (void (*final)(void *), STORE_HANDLE handle, int size) ;
    /* handleAlloc is deprecated, use halloc, and blockSetFinalize instead */
UTIL_FUNC_DCL void *halloc(int size, STORE_HANDLE handle) ;
UTIL_FUNC_DCL char *strnew(char *old, STORE_HANDLE handle) ;

#else		/* MEM_DEBUG from rbrusk */

void *halloc_dbg(int size, STORE_HANDLE handle, const char *hfname, int hlineno) ;
UTIL_FUNC_DCL void *handleAlloc_dbg(void (*final)(void *), STORE_HANDLE handle, int size,
					  const char *hfname, int hlineno) ;
UTIL_FUNC_DCL char *strnew_dbg(char *old, STORE_HANDLE handle, const char *hfname, int hlineno) ;
#define halloc(s, h) halloc_dbg(s, h, __FILE__, __LINE__)
#define handleAlloc(f, h, s) handleAlloc_dbg(f, h, s, __FILE__, __LINE__)
#define strnew(o, h) strnew_dbg(o, h, __FILE__, __LINE__)
#define messalloc_dbg(size,fname,lineno) halloc_dbg(size, 0, fname, lineno)

#endif

UTIL_FUNC_DCL void blockSetFinalise(void *block, void (*final)(void *)) ;
UTIL_FUNC_DCL void handleSetFinalise(STORE_HANDLE handle, void (*final)(void *), void *arg) ;
UTIL_FUNC_DCL void handleInfo (STORE_HANDLE handle, int *number, int *size) ;
#define messalloc(size) halloc(size, 0)
UTIL_FUNC_DCL void umessfree (void *cp) ;
#define messfree(cp)  ((cp) ? umessfree((void*)(cp)),(cp)=0,TRUE : FALSE)
UTIL_FUNC_DCL void messalloccheck (void) ;	/* can be used anywhere - does nothing
				   unless MALLOC_CHECK set in messubs.c */
UTIL_FUNC_DCL int messAllocStatus (int *np) ; /* returns number of outstanding allocs
				   *np is total mem if MALLOC_CHECK */

UTIL_FUNC_DCL int regExpMatch (char *cp,char *tp) ; /* in messubs.c CLH 5/23/95 */

/********************************************************************/
/******** growable arrays and flexible stacks - arraysub.c **********/
/********************************************************************/

/* to be included after the declarations of STORE_HANDLE etc. */
#include "array.h"

/********************************************************************/
/************** file opening/closing from filsubs.c *****************/
/********************************************************************/

UTIL_FUNC_DCL void filAddPath (char *path) ;	/* Adds a set of pathnames to the pathname stack */
UTIL_FUNC_DCL void filAddDir (char *dir) ;	/* Adds a single pathname to the pathname stack */

/* returns an absolute path string for dir in relation to user's CWD */
/* returns pointer to internal static */
UTIL_FUNC_DCL char *filGetFullPath (char *dir);

/* returns filename part of a pathname. */
/* returns pointer to internal static */
UTIL_FUNC_DCL char *filGetFilename(char *path);

/* returns the file-extension part of a path or file-name */
/* returns pointer to internal static */
UTIL_FUNC_DCL char *filGetExtension(char *path);

UTIL_FUNC_DCL char *filName (char *name, char *ending, char *spec) ;
UTIL_FUNC_DCL char *filStrictName (char *name, char *ending, char *spec) ;

/* determines time since last modification, FALSE if no file */
UTIL_FUNC_DCL BOOL  filAge (char *name, char *ending,
			    int *diffYears, int *diffMonths, int *diffDays,
			    int *diffHours, int *diffMins, int *diffSecs);

UTIL_FUNC_DCL FILE *filopen (char *name, char *ending, char *spec) ;
UTIL_FUNC_DCL FILE *filmail (char *address) ;
UTIL_FUNC_DCL void filclose (FILE* fil) ;

UTIL_FUNC_DCL BOOL filremove (char *name, char *ending) ;

UTIL_FUNC_DCL FILE *filtmpopen (char **nameptr, char *spec) ;
UTIL_FUNC_DCL BOOL filtmpremove (char *name) ;
UTIL_FUNC_DCL void filtmpcleanup (void) ;

/* file chooser */
typedef FILE* (*QueryOpenRoutine)(char*, char*, char*, char*, char*) ;
UTIL_FUNC_DCL QueryOpenRoutine filQueryOpenRegister (QueryOpenRoutine new);
		/* allow graphic file choosers to be registered */

UTIL_FUNC_DCL FILE *filqueryopen (char *dirname, char *filname,
				  char *ending, char *spec, char *title);

	/* if dirname is given it should be DIR_BUFFER_SIZE long
	     and filname FILE_BUFFER_SIZE long
	   if not given, then default (static) buffers will be used */


/* directory access */
UTIL_FUNC_DCL Array filDirectoryCreate (char *dirName,
					char *ending, 
					char *spec);

UTIL_FUNC_DCL void filDirectoryDestroy (Array filDirArray);

/*******************************************************************/
/************* randsubs.c random number generator ******************/

UTIL_FUNC_DCL double randfloat (void) ;
UTIL_FUNC_DCL double randgauss (void) ;
UTIL_FUNC_DCL int randint (void) ;
UTIL_FUNC_DCL void randsave (int *arr) ;
UTIL_FUNC_DCL void randrestore (int *arr) ;


/* Unix debugging.                                                           */
/* put "break invokeDebugger" in your favourite debugger init file */
/* this function is empty, it is defined in messubs.c used in
   messerror, messcrash and when ever you need it.
*/
UTIL_FUNC_DCL void invokeDebugger(void) ;




/*******************************************************************/
/************* some WIN32 debugging utilities **********************/

#if defined (WIN32)
#if defined(_DEBUG)
/* See win32util.cpp for these functions */
UTIL_FUNC_DCL const char *dbgPos( const char *caller, int lineno, const char *called ) ;
UTIL_FUNC_DCL void WinTrace(char *prompt, unsigned long code) ;
UTIL_FUNC_DCL void AceASSERT(int condition) ;
UTIL_FUNC_DCL void NoMemoryTracking() ;
#else   /* !defined(_DEBUG) */
#define dbgPos(c,l,fil)   (const char *)(fil)
#endif	/* !defined(_DEBUG) */
#endif	/* defined(WIN32) */

#endif /* defined(DEF_REGULAR_H) */

/******************************* End of File **********************************/
