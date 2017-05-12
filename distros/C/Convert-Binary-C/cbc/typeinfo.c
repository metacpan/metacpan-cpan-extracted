/*******************************************************************************
*
* MODULE: typeinfo.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C type information
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
#include "cbc/typeinfo.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static SV *get_type_spec_def(pTHX_ const CParseConfig *pCfg, const TypeSpec *pTSpec);
static SV *get_enumerators_def(pTHX_ LinkedList enumerators);
static SV *get_declarators_def(pTHX_ LinkedList declarators);
static SV *get_struct_declarations_def(pTHX_ const CParseConfig *pCfg, LinkedList declarations);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_type_spec_def
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

static SV *get_type_spec_def(pTHX_ const CParseConfig *pCfg, const TypeSpec *pTSpec)
{
  u_32 flags = pTSpec->tflags;

  if (flags & T_TYPE)
  {
    Typedef *pTypedef= (Typedef *) pTSpec->ptr;

    if (pTypedef && pTypedef->pDecl->identifier[0])
      return newSVpv(pTypedef->pDecl->identifier, 0);
    else
      return NEW_SV_PV_CONST("<NULL>");
  }

  if (flags & T_ENUM)
  {
    EnumSpecifier *pEnumSpec = (EnumSpecifier *) pTSpec->ptr;

    if (pEnumSpec)
    {
      if (pEnumSpec->identifier[0])
        return newSVpvf("enum %s", pEnumSpec->identifier);
      else
        return get_enum_spec_def(aTHX_ pCfg, pEnumSpec);
    }
    else
      return NEW_SV_PV_CONST("enum <NULL>");
  }

  if (flags & T_COMPOUND)
  {
    Struct *pStruct = (Struct *) pTSpec->ptr;
    const char *type = flags & T_UNION ? "union" : "struct";

    if (pStruct)
    {
      if (pStruct->identifier[0])
        return newSVpvf("%s %s", type, pStruct->identifier);
      else
        return get_struct_spec_def(aTHX_ pCfg, pStruct);
    }
    else
      return newSVpvf("%s <NULL>", type);
  }

  {
    SV *sv = NULL;

    get_basic_type_spec_string(aTHX_ &sv, flags);

    return sv ? sv : NEW_SV_PV_CONST("<NULL>");
  }
}

/*******************************************************************************
*
*   ROUTINE: get_enumerators_def
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

static SV *get_enumerators_def(pTHX_ LinkedList enumerators)
{
  ListIterator ei;
  Enumerator *pEnum;
  HV *hv = newHV();

  LL_foreach(pEnum, ei, enumerators)
  {
    SV *val = newSViv(pEnum->value.iv);
    if (hv_store(hv, pEnum->identifier, CTT_IDLEN(pEnum), val, 0) == NULL)
      SvREFCNT_dec(val);
  }

  return newRV_noinc((SV *) hv);
}

/*******************************************************************************
*
*   ROUTINE: get_declarators_def
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

static SV *get_declarators_def(pTHX_ LinkedList declarators)
{
  ListIterator di;
  Declarator *pDecl;
  AV *av = newAV();

  LL_foreach(pDecl, di, declarators)
  {
    HV *hv = newHV();
    Value *pValue;

    if (pDecl->bitfield_flag)
    {
      HV_STORE_CONST(hv, "declarator", newSVpvf("%s:%d",
                     pDecl->identifier[0] != '\0' ? pDecl->identifier : "",
                     pDecl->ext.bitfield.bits));
    }
    else
    {
      SV *sv = newSVpvf("%s%s", pDecl->pointer_flag ? "*" : "", pDecl->identifier);

      if (pDecl->array_flag)
      {
        ListIterator ai;

        LL_foreach(pValue, ai, pDecl->ext.array)
        {
          if (pValue->flags & V_IS_UNDEF)
            sv_catpvn(sv, "[]", 2);
          else
            sv_catpvf(sv, "[%ld]", pValue->iv);
        }
      }

      HV_STORE_CONST(hv, "declarator", sv);
      HV_STORE_CONST(hv, "offset", newSViv(pDecl->offset));
      HV_STORE_CONST(hv, "size", newSViv(pDecl->size));
    }

    av_push(av, newRV_noinc((SV *) hv));
  }

  return newRV_noinc((SV *) av);
}

/*******************************************************************************
*
*   ROUTINE: get_struct_declarations_def
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

static SV *get_struct_declarations_def(pTHX_ const CParseConfig *pCfg, LinkedList declarations)
{
  ListIterator sdi;
  StructDeclaration *pStructDecl;
  AV *av = newAV();

  LL_foreach(pStructDecl, sdi, declarations)
  {
    HV *hv = newHV();

    HV_STORE_CONST(hv, "type", get_type_spec_def(aTHX_ pCfg, &pStructDecl->type));

    if (pStructDecl->declarators)
      HV_STORE_CONST(hv, "declarators",
                         get_declarators_def(aTHX_ pStructDecl->declarators));

    av_push(av, newRV_noinc((SV *) hv));
  }

  return newRV_noinc((SV *) av);
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_typedef_def
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

SV *get_typedef_def(pTHX_ const CParseConfig *pCfg, const Typedef *pTypedef)
{
  Declarator *pDecl = pTypedef->pDecl;
  Value *pValue;

  HV *hv = newHV();
  SV *sv = newSVpvf("%s%s", pDecl->pointer_flag ? "*" : "", pDecl->identifier);

  if (pDecl->array_flag)
  {
    ListIterator ai;

    LL_foreach(pValue, ai, pDecl->ext.array)
    {
      if (pValue->flags & V_IS_UNDEF)
        sv_catpvn(sv, "[]", 2);
      else
        sv_catpvf(sv, "[%ld]", pValue->iv);
    }
  }

  HV_STORE_CONST(hv, "declarator", sv);
  HV_STORE_CONST(hv, "type", get_type_spec_def(aTHX_ pCfg, pTypedef->pType));

  return newRV_noinc((SV *) hv);
}

/*******************************************************************************
*
*   ROUTINE: get_enum_spec_def
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

SV *get_enum_spec_def(pTHX_ const CParseConfig *pCfg, const EnumSpecifier *pEnumSpec)
{
  HV *hv = newHV();

  if (pEnumSpec->identifier[0])
    HV_STORE_CONST(hv, "identifier", newSVpv(pEnumSpec->identifier, 0));

  if (pEnumSpec->enumerators)
  {
    HV_STORE_CONST(hv, "sign", newSViv(pEnumSpec->tflags & T_SIGNED ? 1 : 0));
    HV_STORE_CONST(hv, "size", newSViv(GET_ENUM_SIZE(pCfg, pEnumSpec)));
    HV_STORE_CONST(hv, "enumerators",
                       get_enumerators_def(aTHX_ pEnumSpec->enumerators));
  }

  HV_STORE_CONST(hv, "context", newSVpvf("%s(%lu)",
                     pEnumSpec->context.pFI->name, pEnumSpec->context.line));

  return newRV_noinc((SV *) hv);
}

/*******************************************************************************
*
*   ROUTINE: get_struct_spec_def
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

SV *get_struct_spec_def(pTHX_ const CParseConfig *pCfg, const Struct *pStruct)
{
  HV *hv = newHV();
  SV *type;

  if (pStruct->identifier[0])
    HV_STORE_CONST(hv, "identifier", newSVpv(pStruct->identifier, 0));

  if (pStruct->tflags & T_UNION)
    type = NEW_SV_PV_CONST("union");
  else
    type = NEW_SV_PV_CONST("struct");

  HV_STORE_CONST(hv, "type", type);

  if (pStruct->declarations)
  {
    HV_STORE_CONST(hv, "size", newSViv(pStruct->size));
    HV_STORE_CONST(hv, "align", newSViv(pStruct->align));
    HV_STORE_CONST(hv, "pack", newSViv(pStruct->pack));

    HV_STORE_CONST(hv, "declarations",
                       get_struct_declarations_def(aTHX_ pCfg, pStruct->declarations));
  }

  HV_STORE_CONST(hv, "context", newSVpvf("%s(%lu)",
                     pStruct->context.pFI->name, pStruct->context.line));

  return newRV_noinc((SV *) hv);
}

