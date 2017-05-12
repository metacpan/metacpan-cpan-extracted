/*******************************************************************************
*
* MODULE: idl.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C identifier lists
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
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

#include "cbc/cbc.h"
#include "cbc/idl.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: idl_to_str
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jul 2003
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

const char *idl_to_str(pTHX_ IDList *idl)
{
  SV *sv;
  unsigned i;
  struct IDList_list *cur;

  sv = sv_2mortal(newSVpvn("", 0));
  cur = idl->list;

  for (i = 0; i < idl->count; ++i, ++cur)
  {
    switch (cur->choice)
    {
      case IDL_ID:
        if (i == 0)
          sv_catpv(sv, CONST_CHAR(cur->val.id));
        else
          sv_catpvf(sv, ".%s", cur->val.id);
        break;

      case IDL_IX:
        sv_catpvf(sv, "[%ld]", cur->val.ix);
        break;

      default:
        fatal("invalid choice (%d) in idl_to_str()", (int) cur->choice);
        break;
    }
  }

  return SvPV_nolen(sv);
}

