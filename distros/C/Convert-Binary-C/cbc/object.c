/*******************************************************************************
*
* MODULE: object.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C object
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

#include "util/hash.h"
#include "util/list.h"
#include "ctlib/ctparse.h"
#include "cbc/basic.h"
#include "cbc/cbc.h"
#include "cbc/object.h"
#include "cbc/hook.h"
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
*   ROUTINE: cbc_new
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

CBC *cbc_new(pTHX)
{
  SV  *sv;
  CBC *THIS;
  
  Newz(0, THIS, 1, CBC);
  
  sv = newSViv(PTR2IV(THIS));
  SvREADONLY_on(sv);
  
  THIS->hv = newHV();
  
  if (hv_store(THIS->hv, "", 0, sv, 0) == NULL)
    fatal("Couldn't store THIS into object.");
  
  THIS->enumType                      = CBC_DEFAULT_ENUMTYPE;
  THIS->ixhash                        = NULL;

  THIS->basic                         = basic_types_new();

  THIS->cfg.layout.ptr_size           = CBC_DEFAULT_PTR_SIZE;
  THIS->cfg.layout.enum_size          = CBC_DEFAULT_ENUM_SIZE;
  THIS->cfg.layout.int_size           = CBC_DEFAULT_INT_SIZE;
  THIS->cfg.layout.char_size          = CBC_DEFAULT_CHAR_SIZE;
  THIS->cfg.layout.short_size         = CBC_DEFAULT_SHORT_SIZE;
  THIS->cfg.layout.long_size          = CBC_DEFAULT_LONG_SIZE;
  THIS->cfg.layout.long_long_size     = CBC_DEFAULT_LONG_LONG_SIZE;
  THIS->cfg.layout.float_size         = CBC_DEFAULT_FLOAT_SIZE;
  THIS->cfg.layout.double_size        = CBC_DEFAULT_DOUBLE_SIZE;
  THIS->cfg.layout.long_double_size   = CBC_DEFAULT_LONG_DOUBLE_SIZE;
  THIS->cfg.layout.alignment          = CBC_DEFAULT_ALIGNMENT;
  THIS->cfg.layout.compound_alignment = CBC_DEFAULT_COMPOUND_ALIGNMENT;
  THIS->cfg.layout.byte_order         = CBC_DEFAULT_BYTEORDER;
  THIS->cfg.layout.bflayouter         = bl_create("Generic");

  THIS->cfg.get_type_info             = get_type_info_generic;
  THIS->cfg.layout_compound           = layout_compound_generic;
  THIS->cfg.includes                  = LL_new();
  THIS->cfg.defines                   = LL_new();
  THIS->cfg.assertions                = LL_new();
  THIS->cfg.disabled_keywords         = LL_new();
  THIS->cfg.keyword_map               = HT_new(1);
  THIS->cfg.keywords                  = HAS_ALL_KEYWORDS;
  THIS->cfg.has_cpp_comments          = 1;
  THIS->cfg.has_macro_vaargs          = 1;
  THIS->cfg.has_std_c                 = 1;
  THIS->cfg.has_std_c_hosted          = 1;
  THIS->cfg.is_std_c_hosted           = 1;
  THIS->cfg.std_c_version             = 199901L;

  init_parse_info(&THIS->cpi);

  return THIS;
}

/*******************************************************************************
*
*   ROUTINE: cbc_delete
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

void cbc_delete(pTHX_ CBC *THIS)
{
  free_parse_info(&THIS->cpi);

  LL_destroy(THIS->cfg.includes,          (LLDestroyFunc) string_delete);
  LL_destroy(THIS->cfg.defines,           (LLDestroyFunc) string_delete);
  LL_destroy(THIS->cfg.assertions,        (LLDestroyFunc) string_delete);
  LL_destroy(THIS->cfg.disabled_keywords, (LLDestroyFunc) string_delete);

  basic_types_delete(THIS->basic);

  HT_destroy(THIS->cfg.keyword_map, NULL);

  THIS->cfg.layout.bflayouter->m->destroy(THIS->cfg.layout.bflayouter);

  Safefree(THIS);
}

/*******************************************************************************
*
*   ROUTINE: cbc_clone
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

CBC *cbc_clone(pTHX_ const CBC *THIS)
{
  SV  *sv;
  CBC *clone;

  Newz(0, clone, 1, CBC);
  Copy(THIS, clone, 1, CBC);

  clone->cfg.includes          = clone_string_list(THIS->cfg.includes);
  clone->cfg.defines           = clone_string_list(THIS->cfg.defines);
  clone->cfg.assertions        = clone_string_list(THIS->cfg.assertions);
  clone->cfg.disabled_keywords = clone_string_list(THIS->cfg.disabled_keywords);

  clone->basic = basic_types_clone(THIS->basic);

  clone->cfg.keyword_map = HT_clone(THIS->cfg.keyword_map, NULL);

  clone->cfg.layout.bflayouter =
      THIS->cfg.layout.bflayouter->m->clone(THIS->cfg.layout.bflayouter);

  init_parse_info(&clone->cpi);
  clone_parse_info(&clone->cpi, &THIS->cpi);

  sv = newSViv(PTR2IV(clone));
  SvREADONLY_on(sv);

  clone->hv = newHV();

  if (hv_store(clone->hv, "", 0, sv, 0) == NULL)
    fatal("Couldn't store THIS into object.");

  return clone;
}

/*******************************************************************************
*
*   ROUTINE: cbc_bless
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

SV *cbc_bless(pTHX_ CBC *THIS, const char *CLASS)
{
  SV *sv;

  sv = newRV_noinc((SV *) THIS->hv);
  sv_bless(sv, gv_stashpv(CONST_CHAR(CLASS), 0));

  return sv;
}

