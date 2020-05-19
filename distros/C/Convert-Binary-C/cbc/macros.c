/*******************************************************************************
*
* MODULE: macros.c
*
********************************************************************************
*
* DESCRIPTION: Handle macro lists
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/macros.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void get_names_callback(const CMacroInfo *pmi);
static void get_defs_callback(const CMacroInfo *pmi);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_names_callback
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
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

struct get_names_cb_arg
{
#ifdef PERL_IMPLICIT_CONTEXT
  void *interp;
#endif
  size_t count;
  LinkedList ll;
};

static void get_names_callback(const CMacroInfo *pmi)
{
  struct get_names_cb_arg *a = pmi->arg;

  if (a->ll)
  {
    dTHXa(a->interp);
    LL_push(a->ll, newSVpv(pmi->name, 0));
  }
  else
  {
    a->count++;
  }
}

/*******************************************************************************
*
*   ROUTINE: get_defs_callback
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
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

struct get_defs_cb_arg
{
#ifdef PERL_IMPLICIT_CONTEXT
  void *interp;
#endif
  LinkedList ll;
};

static void get_defs_callback(const CMacroInfo *pmi)
{
  struct get_defs_cb_arg *a = pmi->arg;
  dTHXa(a->interp);
  LL_push(a->ll, newSVpv(pmi->definition, pmi->definition_len));
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: macros_get_names
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
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

LinkedList macros_get_names(pTHX_ CParseInfo *pCPI, size_t *count)
{
  struct get_names_cb_arg a;

#ifdef PERL_IMPLICIT_CONTEXT
  a.interp = aTHX;
#endif

  if (count)
  {
    a.ll = NULL;
    a.count = 0;
  }
  else
  {
    a.ll = LL_new();
  }

  macro_iterate_defs(pCPI, get_names_callback, &a, 0);

  if (count)
  {
    *count = a.count;
  }

  return a.ll;
}

/*******************************************************************************
*
*   ROUTINE: macros_get_definitions
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
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

LinkedList macros_get_definitions(pTHX_ CParseInfo *pCPI)
{
  struct get_defs_cb_arg a;

#ifdef PERL_IMPLICIT_CONTEXT
  a.interp = aTHX;
#endif

  a.ll = LL_new();

  macro_iterate_defs(pCPI, get_defs_callback, &a, CMIF_WITH_DEFINITION);

  return a.ll;
}

