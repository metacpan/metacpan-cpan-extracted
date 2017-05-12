/*  File: version.h
 *  Author: Ed Griffiths (edgrif@sanger.ac.uk)
 *  Copyright (c) J Thierry-Mieg and R Durbin, 1998
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (Sanger Centre, UK) rd@sanger.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.crbm.cnrs-mop.fr
 *
 * Description: Macros to support version numbering of libraries and
 *              applications in acedb.
 * Exported functions:
 * HISTORY:
 * Last edited: Dec 10 13:32 1998 (edgrif)
 * * Dec  3 14:37 1998 (edgrif): Set up macros to insert copyright strings.
 * Created: Tue Dec  1 13:29:08 1998 (edgrif)
 * CVS info:   $Id: version.h,v 1.1 2002/11/14 20:00:06 lstein Exp $
 *-------------------------------------------------------------------
 */

#ifndef UT_VERSION_H
#define UT_VERSION_H


/* Tools for creating version strings in an application or library.          */
/*                                                                           */


/* This macro creates a routine that must be provided by all applications    */
/* that use the ACECB kernel code or libace. libace routines expect to be    */
/* able to query the date on which the applications main routine was         */
/* compiled so that this information can be displayed to the user.           */
/* The function must have this prototype and must return a string that gives */
/* the build date:                                                           */
/*                                                                           */
char *utAppGetCompileDate(void) ;
/* The acedb                                                                 */
/* makefile is arranged so that the main routine is recompiled every time    */
/* the application is relinked. This means that the date represents the      */
/* 'build' date of the application.                                          */
/*                                                                           */
/* Code the macro by simply putting it in the .c file that contains the      */
/* main function of the application, it's probably best to put it just       */
/* before or after the main function. Do not put a terminating ';' after     */
/* the macro, this will cause a compile error.                               */
/*                                                                           */
#define UT_COMPILE_PHRASE "compiled on:"

#define UT_MAKE_GETCOMPILEDATEROUTINE()                                      \
char *utAppGetCompileDate(void) { return UT_COMPILE_PHRASE " " __DATE__ " " __TIME__ ; }



/* These tools assume that various numbers/strings are defined, e.g.         */
/*                                                                           */
/* #define SOME_TITLE   "UT library"         (definitive name for library)   */
/* #define SOME_DESC    "brief description"  (purpose of library - one liner)*/
/* #define SOME_VERSION 1                    (major version)                 */
/* #define SOME_RELEASE 0                    (minor version)                 */
/* #define SOME_UPDATE  1                    (latest fix number)             */
/*                                                                           */

/* 1) Use UT_MAKESTRING to make strings out of #define'd numbers.            */
/*    (required because of the way ANSI preprocessor handles strings)        */
/*    e.g. UT_MAKESTRING(6)  produces "6"                                    */
/*                                                                           */
#define UT_PUTSTRING(x) #x
#define UT_MAKESTRING(x) UT_PUTSTRING(x)

/* 2) Make a single version number out of the version, release and update    */
/*    numbers.                                                               */
/* NOTE that there will be no more than 100 (i.e. 0 - 99) revisions per      */
/* version, or updates per revision, otherwise version will be wrong.        */
/*                                                                           */
#define UT_MAKE_VERSION_NUMBER(VERSION, RELEASE, UPDATE) \
((VERSION * 10000) + (RELEASE * 100) + UPDATE)

/* 3) Make a version string containing the title of the application/library  */
/*    and the version, release and update numbers.                           */
/*                                                                           */
#define UT_MAKE_VERSION_STRING(TITLE, VERSION, RELEASE, UPDATE) \
TITLE " - " UT_MAKESTRING(VERSION) "." UT_MAKESTRING(RELEASE) "." UT_MAKESTRING(UPDATE)


/* 4) Macro for creating a standard copyright string to be inserted into    */
/*    compiled applications and libraries. The macro ensures a common       */
/*    format for version numbers etc.                                       */
/*                                                                           */
/* The macro is a statement, NOT an expression, but does NOT require a       */
/* terminating semi-colon. The macro should be coded like this:              */
/*                                                                           */
/*    UT_COPYRIGHT_STRING(prefix, title, description)                        */
/*                                                                           */
/*    where  prefix is some a string locally used to prefix variables        */
/*    where  title is a string of the form   "Appname  1.0.1"                */
/*      and  description is of the form  "Application to blah, blah."        */
/*                                                                           */
#define UT_COPYRIGHT()                                                               \
"@(#) Copyright (c):  J Thierry-Mieg and R Durbin, 1998 \n"                          \
"@(#) \n"                                                                            \
"@(#) This file contains the above Sanger Informatics Group library, \n"             \
"@(#) written by   Richard Durbin (Sanger Centre, UK) rd@sanger.ac.uk \n"            \
"@(#)              Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.crbm.cnrs-mop.fr \n" \
"@(#)              Ed Griffiths (Sanger Centre, UK) edgrif@sanger.ac.uk \n"          \
"@(#)              Fred Wobus (Sanger Centre, UK) fw@sanger.ac.uk \n"                \
"@(#) You may redistribute this software subject to the conditions in the \n"        \
"@(#) accompanying copyright file. Anyone interested in obtaining an up to date \n"  \
"@(#) version should contact one of the authors at the above email addresses. \n"


#define UT_COPYRIGHT_STRING(TITLE, VERSION, RELEASE, UPDATE, DESCRIPTION_STRING)     \
static const char *ut_copyright_string =                                             \
"@(#) \n"                                                                            \
"@(#) --------------------------------------------------------------------------\n"  \
"@(#) Title/Version:  "UT_MAKE_VERSION_STRING(TITLE, VERSION, RELEASE, UPDATE)"\n"   \
"@(#)      Compiled:  "__DATE__" "__TIME__"\n"                                       \
"@(#)   Description:  " DESCRIPTION_STRING"\n"                                       \
UT_COPYRIGHT()                                                                       \
"@(#) --------------------------------------------------------------------------\n"  \
"@(#) \n" ;


#endif	/* UT_VERSION_H */
