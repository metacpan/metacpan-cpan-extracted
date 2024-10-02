/*******************************************************************************
*
* MODULE: debug.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C debugging stuff
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifdef CBC_DEBUGGING

/*===== GLOBAL INCLUDES ======================================================*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/ctdebug.h"
#include "util/hash.h"
#include "util/memalloc.h"
#include "cbc/cbc.h"
#include "cbc/debug.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

#ifndef PERLIO_IS_STDIO
# ifdef fprintf
#  undef fprintf
# endif
# define fprintf PerlIO_printf
# ifdef vfprintf
#  undef vfprintf
# endif
# define vfprintf PerlIO_vprintf
# ifdef stderr
#  undef stderr
# endif
# define stderr PerlIO_stderr()
# ifdef fopen
#  undef fopen
# endif
# define fopen PerlIO_open
# ifdef fclose
#  undef fclose
# endif
# define fclose PerlIO_close
#endif


/*===== TYPEDEFS =============================================================*/

#ifdef PerlIO
typedef PerlIO * DebugStream;
#else
typedef FILE * DebugStream;
#endif


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void debug_vprintf(const char *f, va_list *l);
static void debug_printf(const char *f, ...);
static void debug_printf_ctlib(const char *f, ...);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

static DebugStream gs_DB_stream;


/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: debug_*
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Debug output routines.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static void debug_vprintf(const char *f, va_list *l)
{
  dTHX;
  vfprintf(gs_DB_stream, f, *l);
}

static void debug_printf(const char *f, ...)
{
  dTHX;
  va_list l;
  va_start(l, f);
  vfprintf(gs_DB_stream, f, l);
  va_end(l);
}

static void debug_printf_ctlib(const char *f, ...)
{
  dTHX;
  va_list l;
  va_start(l, f);
  debug_printf("DBG: ");
  vfprintf(gs_DB_stream, f, l);
  debug_printf("\n");
  va_end(l);
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: set_debug_options
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
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

void set_debug_options(pTHX_ const char *dbopts)
{
  unsigned long memflags, hashflags, dbgflags;

  if (strEQ(dbopts, "all"))
  {
    memflags = hashflags = dbgflags = 0xFFFFFFFF;
  }
  else
  {
    memflags = hashflags = dbgflags = 0;

    while (*dbopts)
    {
      switch (*dbopts)
      {
        case 'm': memflags  |= DB_MEMALLOC_TRACE;  break;
        case 'M': memflags  |= DB_MEMALLOC_TRACE
                            |  DB_MEMALLOC_ASSERT; break;

        case 'h': hashflags |= DB_HASH_MAIN;       break;

        case 'd': dbgflags  |= DB_CTLIB_MAIN;      break;
        case 'p': dbgflags  |= DB_CTLIB_PARSER;    break;
        case 'l': dbgflags  |= DB_CTLIB_CLEXER;    break;
        case 'y': dbgflags  |= DB_CTLIB_YACC;      break;
        case 'r': dbgflags  |= DB_CTLIB_PRAGMA;    break;
        case 'c': dbgflags  |= DB_CTLIB_CTLIB;     break;
        case 'H': dbgflags  |= DB_CTLIB_HASH;      break;
        case 't': dbgflags  |= DB_CTLIB_TYPE;      break;
        case 'P': dbgflags  |= DB_CTLIB_PREPROC;   break;

        default:
          Perl_croak(aTHX_ "Unknown debug option '%c'", *dbopts);
          break;
      }
      dbopts++;
    }
  }

  if (!SetDebugMemAlloc(debug_printf, memflags))
    fatal("Cannot enable memory debugging");

  if (!SetDebugHash(debug_printf, hashflags))
    fatal("Cannot enable hash debugging");

  if (!SetDebugCType(debug_printf_ctlib, debug_vprintf, dbgflags))
    fatal("Cannot enable debugging");
}

/*******************************************************************************
*
*   ROUTINE: set_debug_file
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
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

void set_debug_file(pTHX_ const char *dbfile)
{
  if (gs_DB_stream != stderr && gs_DB_stream != NULL)
  {
    fclose(gs_DB_stream);
    gs_DB_stream = NULL;
  }

  gs_DB_stream = dbfile ? fopen(dbfile, "w") : stderr;

  if (gs_DB_stream == NULL)
  {
    WARN((aTHX_ "Cannot open '%s', defaulting to stderr", dbfile));
    gs_DB_stream = stderr;
  }
}

/*******************************************************************************
*
*   ROUTINE: init_debugging
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
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

void init_debugging(pTHX)
{
  gs_DB_stream = stderr;
}

#endif /* CBC_DEBUGGING */

