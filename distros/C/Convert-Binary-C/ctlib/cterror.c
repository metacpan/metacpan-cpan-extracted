/*******************************************************************************
*
* MODULE: cterror.c
*
********************************************************************************
*
* DESCRIPTION: Error reporting for the ctlib
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

/*===== LOCAL INCLUDES =======================================================*/

#include "cterror.h"
#include "util/memalloc.h"

#include "ucpp/cpp.h"
#include "ucpp/mem.h"

#include "cppreent.h"


/*===== DEFINES ==============================================================*/

#define INIT_CHECK                                                             \
          do {                                                                 \
            if (!initialized)                                                  \
            {                                                                  \
              fprintf(stderr, "FATAL: print functions have not been set!\n");  \
              abort();                                                         \
            }                                                                  \
          } while(0)

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static CTLibError *error_new(enum CTErrorSeverity severity, void *str);
static void error_delete(CTLibError *error);
static void push_str(CParseInfo *pCPI, enum CTErrorSeverity severity, void *str);
static void push_verror(CParseInfo *pCPI, enum CTErrorSeverity severity,
                        const char *fmt, va_list *pap);

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

static int initialized = 0;
static PrintFunctions F;

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: error_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

static CTLibError *error_new(enum CTErrorSeverity severity, void *str)
{
  CTLibError *perr;
  const char *string;
  size_t len;

  string = F.cstring(str, &len);
  AllocF(CTLibError *, perr, sizeof(CTLibError));
  AllocF(char *, perr->string, len + 1);
  perr->severity = severity;
  strncpy(perr->string, string, len);
  perr->string[len] = '\0';

  return perr;
}

/*******************************************************************************
*
*   ROUTINE: error_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

static void error_delete(CTLibError *error)
{
  if (error)
  {
    if (error->string)
      Free(error->string);

    Free(error);
  }
}

/*******************************************************************************
*
*   ROUTINE: push_str
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

static void push_str(CParseInfo *pCPI, enum CTErrorSeverity severity, void *str)
{
  if (pCPI == NULL || pCPI->errorStack == NULL)
    F.fatalerr(str);

  LL_push(pCPI->errorStack, error_new(severity, str));
}

/*******************************************************************************
*
*   ROUTINE: push_verror
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

static void push_verror(CParseInfo *pCPI, enum CTErrorSeverity severity,
                        const char *fmt, va_list *pap)
{
  void *str = F.newstr();
  F.vscatf(str, fmt, pap);
  push_str(pCPI, severity, str);
  F.destroy(str);
}

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: set_print_functions
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

void set_print_functions(PrintFunctions *pPF)
{
  if (pPF->newstr   == NULL ||
      pPF->destroy  == NULL ||
      pPF->scatf    == NULL ||
      pPF->vscatf   == NULL ||
      pPF->cstring  == NULL ||
      pPF->fatalerr == NULL)
  {
    fprintf(stderr, "FATAL: all print functions must be set!\n");
    abort();
  }

  F = *pPF;
  initialized = 1;
}

/*******************************************************************************
*
*   ROUTINE: pop_all_errors
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

void pop_all_errors(CParseInfo *pCPI)
{
  LL_flush(pCPI->errorStack, (LLDestroyFunc) error_delete);
}

/*******************************************************************************
*
*   ROUTINE: push_error
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

void push_error(CParseInfo *pCPI, const char *fmt, ...)
{
  va_list ap;
  INIT_CHECK;
  va_start(ap, fmt);
  push_verror(pCPI, CTES_ERROR, fmt, &ap);
  va_end(ap);
}

/*******************************************************************************
*
*   ROUTINE: push_warning
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

void push_warning(CParseInfo *pCPI, const char *fmt, ...)
{
  va_list ap;
  INIT_CHECK;
  va_start(ap, fmt);
  push_verror(pCPI, CTES_WARNING, fmt, &ap);
  va_end(ap);
}

/*******************************************************************************
*
*   ROUTINE: fatal_error
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

void fatal_error(const char *fmt, ...)
{
  va_list ap;
  void *str;

  INIT_CHECK;
  va_start(ap, fmt);
  str = F.newstr();
  F.vscatf(str, fmt, &ap);
  va_end(ap);

  F.fatalerr(str);
}

/*******************************************************************************
*
*   ROUTINE: my_ucpp_ouch
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

void my_ucpp_ouch(pUCPP_ char *fmt, ...)
{
  va_list ap;
  void *str;

  INIT_CHECK;

  va_start(ap, fmt);
  str = F.newstr();
  F.scatf(str, "%s: (FATAL) ", r_current_filename);
  F.vscatf(str, fmt, &ap);
  va_end(ap);

  F.fatalerr(str);
}

/*******************************************************************************
*
*   ROUTINE: my_ucpp_error
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

void my_ucpp_error(pUCPP_ long line, char *fmt, ...)
{
  va_list ap;
  void *str;

  INIT_CHECK;

  va_start(ap, fmt);

  str = F.newstr();

  if (line > 0)
    F.scatf(str, "%s, line %ld: ", r_current_filename, line);
  else if (line == 0)
    F.scatf(str, "%s: ", r_current_filename);

  F.vscatf(str, fmt, &ap);

  if (line >= 0)
  {
    struct stack_context *sc = report_context(aUCPP);
    size_t i;

    for (i = 0; sc[i].line >= 0; i++)
      F.scatf(str, "\n\tincluded from %s:%ld",
              sc[i].long_name ? sc[i].long_name : sc[i].name,
              sc[i].line);

    freemem(sc);
  }

  va_end(ap);

  push_str(r_callback_arg, CTES_ERROR, str);

  F.destroy(str);
}

/*******************************************************************************
*
*   ROUTINE: my_ucpp_warning
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

void my_ucpp_warning(pUCPP_ long line, char *fmt, ...)
{
  va_list ap;
  void *str;

  INIT_CHECK;

  va_start(ap, fmt);

  str = F.newstr();

  if (line > 0)
    F.scatf(str, "%s, line %ld: (warning) ",
            r_current_filename, line);
  else if (line == 0)
    F.scatf(str, "%s: (warning) ", r_current_filename);
  else
    F.scatf(str, "(warning) ");

  F.vscatf(str, fmt, &ap);

  if (line >= 0)
  {
    struct stack_context *sc = report_context(aUCPP);
    size_t i;

    for (i = 0; sc[i].line >= 0; i++)
      F.scatf(str, "\n\tincluded from %s:%ld",
              sc[i].long_name ? sc[i].long_name : sc[i].name,
              sc[i].line);
    freemem(sc);
  }

  va_end(ap);

  push_str(r_callback_arg, CTES_WARNING, str);

  F.destroy(str);
}

