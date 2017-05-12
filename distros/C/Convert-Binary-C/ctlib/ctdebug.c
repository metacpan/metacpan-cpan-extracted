/*******************************************************************************
*
* MODULE: ctdebug.c
*
********************************************************************************
*
* DESCRIPTION: Debugging support
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifdef CTLIB_DEBUGGING

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

/*===== LOCAL INCLUDES =======================================================*/

#include "ctdebug.h"

/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

void        (*g_CT_dbfunc)(const char *, ...) = NULL;
unsigned long g_CT_dbflags                    = 0;

/*===== STATIC VARIABLES =====================================================*/

static void (*gs_vprintf)(const char *, va_list *) = NULL;

/*===== STATIC FUNCTIONS =====================================================*/

/*===== FUNCTIONS ============================================================*/

#ifdef CTLIB_FORMAT_CHECK
void CT_dbfunc_check( const char *str __attribute(( __unused__ )), ... )
{
  fprintf( stderr, "compiled with CTLIB_FORMAT_CHECK, please don't run\n" );
  abort();
}
#endif

/*******************************************************************************
*
*   ROUTINE: SetDebugCType
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int SetDebugCType( void (*dbfunc)(const char *, ...),
                   void (*dbvprintf)(const char *, va_list *),
                   unsigned long dbflags )
{
  g_CT_dbfunc  = dbfunc;
  gs_vprintf   = dbvprintf;
  g_CT_dbflags = dbflags;
  return 1;
}

/*******************************************************************************
*
*   ROUTINE: BisonDebugFunc
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void BisonDebugFunc( void *dummy, const char *fmt, ... )
{
  if( dummy != NULL && gs_vprintf != NULL ) {
    va_list l;
    va_start( l, fmt );
    gs_vprintf( fmt, &l );
    va_end( l );
  }
}

#endif /* CTLIB_DEBUGGING */

