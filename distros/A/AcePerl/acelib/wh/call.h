/*  File: call.h
 *  Author: Richard Durbin (rd@sanger.ac.uk)
 *  Copyright (C) J Thierry-Mieg and R Durbin, 1994
 *-------------------------------------------------------------------
 * This file is part of the ACEDB genome database package, written by
 * 	Richard Durbin (MRC LMB, UK) rd@mrc-lmb.cam.ac.uk, and
 *	Jean Thierry-Mieg (CRBM du CNRS, France) mieg@kaa.cnrs-mop.fr
 *
 * Description: Header file for message system to allow calls by name
 * Exported functions:
 * HISTORY:
 * Last edited: Oct 19 11:06 1998 (fw)
 * * Nov  3 16:15 1994 (mieg): callCdScript, first cd to establish 
     the pwd  of the command, needed for ghostview etc.
 * Created: Mon Oct  3 14:57:16 1994 (rd)
 *-------------------------------------------------------------------
 */

/* $Id: call.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */


#ifndef DEF_CALL_H
#define DEF_CALL_H
 
#include "regular.h"

typedef int MESSAGERETURN ;
typedef void (*CallFunc)() ;

void callRegister (char *name, CallFunc func) ;
BOOL call (char *name, ...) ;
BOOL callExists (char *name) ;

int callScript (char *script, char *args) ;
int callCdScript (char *dir, char *script, char *args) ; 
FILE* callScriptPipe (char *script, char *args) ;
FILE* callCdScriptPipe (char *dir, char *script, char *args) ;
BOOL externalAsynchroneCommand (char *command, char *parms,
                                void *look, void(*g)(FILE *f, void *lk)) ;
void externalFileDisplay (char *title, FILE *f, Stack s) ;
void externalPipeDisplay (char *title, FILE *f, Stack s) ;
void acedbMailComments(void) ;
void externalCommand (char* command) ;

#endif

