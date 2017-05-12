/*  File: acedb.h
 *  Author: Jean Thierry-Mieg (mieg@mrc-lmb.cam.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1991
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: general include for any acedb code
 *              can only declare general stuff, 
 *              i.e. not graph-specific things
 * HISTORY:
 * Last edited: Dec 17 15:59 1998 (fw)
 * * Nov 18 17:00 1998 (fw): added decl for mainActivityRegister stuff
 * * Nov 18 16:59 1998 (fw): moved pickDraw, getPickArgs to main.h
 *              as they are for graphical versions
 * * Oct 22 11:43 1998 (edgrif): Add dec. of pickDraw.
 * * Sep 17 09:43 1998 (edgrif): Add declaration of pickGetArgs function.
 * * Oct 21 14:01 1991 (mieg): added overflow  protection in KEYMAKE 
 * Created: Mon Oct 21 14:01:19 1991 (mieg)
 *-------------------------------------------------------------------
 */

/* $Id: acedb.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */
 
             /*********************************************/
             /* ACeDB.h                                   */
             /* type definitions and size limits          */
             /*********************************************/
 
#ifndef DEF_ACeDB_h
#define DEF_ACeDB_h
 
#include "regular.h"
#include "mytime.h"		/* not yet included in regular.h */
#include "keyset.h"		/* contains KEYSET */
#include "aceversion.h"

				/* library EXPORT/IMPORT symbols */
#if defined (WIN32)
#include "win32libspec.h"
#else
#define ACEDB_FUNC_DCL
#define ACEDB_VAR_DCL	extern
#define ACEDB_FUNC_DEF
#define ACEDB_VAR_DEF
#endif

/************************************************************/
/* mainActivity () - function called by graphical and 
   non-graphical code but only in programs that call acedbGraphInit()
   the text will be dispatched to mainActivityDisplayInWindow(char*)
   */
void mainActivity(char * text);
OutRoutine mainActivityRegister (OutRoutine func);
/************************************************************/

#define KEYMAKE(t,i)  ((KEY)( (((KEY) (t))<<24) | ( ((KEY) (i)) & 0xffffffL) ))
#define KEYKEY(kk)  ((KEY)( ((KEY) (kk)) & ((KEY) 0xffffffL) ))
#define class(kk)  ((int)( ((KEY) (kk))>>24 ))
 
char* name(KEY k);     /*returns the name or the word "NULL" in case of a wrong key */
char* className(KEY k) ; /* returns the name of the class of key */

KEY str2tag (char* tagName) ;

typedef BOOL (*DisplayFunc)(KEY key, KEY from, BOOL isOld) ;
typedef BOOL (*ParseFunc)(int level, KEY key) ;
typedef BOOL (*DumpFunc)(FILE *f, Stack s, KEY k) ;
typedef BOOL (*KillFunc)(KEY k) ;
typedef void (*BlockFunc)(KEY) ;

#endif
 

 
