/*******************************************************************************
*
* MODULE: type.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C type names
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

#include "cbc/basic.h"
#include "cbc/cbc.h"
#include "cbc/type.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void *get_type_pointer(CBC *THIS, const char *name, const char **pEOS);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_type_pointer
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

static void *get_type_pointer(CBC *THIS, const char *name, const char **pEOS)
{
  const char *c   = name;
  void       *ptr = NULL;
  int         len = 0;
  enum { S_UNKNOWN, S_STRUCT, S_UNION, S_ENUM } type = S_UNKNOWN;

  if (!THIS->cpi.available)
    return NULL;

  while (isSPACE(*c))
    c++;

  if (*c == '\0')
    return NULL;

  switch (c[0])
  {
    case 's':
      if (c[1] == 't' &&
          c[2] == 'r' &&
          c[3] == 'u' &&
          c[4] == 'c' &&
          c[5] == 't' &&
          isSPACE(c[6]))
      {
        type = S_STRUCT;
        c += 6;
      }
      break;

    case 'u':
      if (c[1] == 'n' &&
          c[2] == 'i' &&
          c[3] == 'o' &&
          c[4] == 'n' &&
          isSPACE(c[5]))
      {
        type = S_UNION;
        c += 5;
      }
      break;

    case 'e':
      if (c[1] == 'n' &&
          c[2] == 'u' &&
          c[3] == 'm' &&
          isSPACE(c[4]))
      {
        type = S_ENUM;
        c += 4;
      }
      break;

    default:
      break;
  }

  while (isSPACE(*c))
    c++;

  while (c[len] == '_' || isALNUM(c[len]))
    len++;

  if (len == 0)
    return NULL;

  switch (type)
  {
    case S_STRUCT:
    case S_UNION:
      {
        Struct *pStruct = HT_get(THIS->cpi.htStructs, c, len, 0);
        ptr = (void *) (pStruct && (pStruct->tflags & (type == S_STRUCT
                        ? T_STRUCT : T_UNION)) ? pStruct : NULL);
      }
      break;

    case S_ENUM:
      ptr = HT_get(THIS->cpi.htEnums, c, len, 0);
      break;

    default:
      if ((ptr = HT_get(THIS->cpi.htTypedefs, c, len, 0)) == NULL)
        if ((ptr = HT_get(THIS->cpi.htStructs, c, len, 0)) == NULL)
          ptr = HT_get(THIS->cpi.htEnums, c, len, 0);
      break;
  }

  if (pEOS)
  {
    c += len;

    while (isSPACE(*c))
      c++;

    *pEOS = c;
  }

  return ptr;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_member_info
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
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

int get_member_info(pTHX_ CBC *THIS, const char *name, MemberInfo *pMI, unsigned gmi_flags)
{
  const int do_calc = (gmi_flags & CBC_GMI_NO_CALC) == 0;
  const char *member;
  MemberInfo mi;

  if (get_type_spec(THIS, name, &member, &mi.type) == 0)
    return 0;

  if (pMI)
  {
    pMI->flags  = 0;
    pMI->parent = NULL;

    if (member && *member)
    {
      mi.pDecl = NULL;
      mi.level = 0;
      (void) get_member(aTHX_ &mi, member, pMI, do_calc ? 0 : CBC_GM_NO_OFFSET_SIZE_CALC);
    }
    else if (mi.type.ptr == NULL)
    {
      Declarator *pDecl = basic_types_get_declarator(THIS->basic, mi.type.tflags);

      if (pDecl == NULL)
      {
        SV *str = NULL;
        get_basic_type_spec_string(aTHX_ &str, mi.type.tflags);
        sv_2mortal(str);
        Perl_croak(aTHX_ "Unsupported basic type '%s'", SvPV_nolen(str));
      }

      if (do_calc && pDecl->size < 0)
        (void) THIS->cfg.get_type_info(&THIS->cfg.layout, &mi.type, NULL,
                                       "si", &pDecl->size, &pDecl->item_size);

      pMI->pDecl  = pDecl;
      pMI->type   = mi.type;
      pMI->flags  = 0;
      pMI->level  = 0;
      pMI->offset = 0;
      pMI->size   = do_calc ? pDecl->size : 0;
    }
    else
    {
      void *ptr = mi.type.ptr;  /* TODO: improve this... */

      switch (GET_CTYPE(ptr))
      {
        case TYP_TYPEDEF:
          {
            /* TODO: get rid of get_type_info, add flags to size */
            ErrorGTI err;
            err = THIS->cfg.get_type_info(&THIS->cfg.layout, ((Typedef *) ptr)->pType,
                                          ((Typedef *) ptr)->pDecl,
                                          "sf", &pMI->size, &pMI->flags);

            if (err != GTI_NO_ERROR)
              croak_gti(aTHX_ err, name, 0);
          }
          break;

        case TYP_STRUCT:
          if (((Struct *) ptr)->declarations == NULL)
            CROAK_UNDEF_STRUCT((Struct *) ptr);

          pMI->size  = ((Struct *) ptr)->size;
          pMI->flags = ((Struct *) ptr)->tflags & (T_HASBITFIELD | T_UNSAFE_VAL);
          break;

        case TYP_ENUM:
          pMI->size = GET_ENUM_SIZE(&THIS->cfg, (EnumSpecifier *) ptr);
          break;

        default:
          fatal("get_type_spec returned an invalid type (%d) in "
                "get_member_info( '%s' )", GET_CTYPE(ptr), name);
          break;
      }

      if (!do_calc)
      {
        pMI->size = 0;
      }

      pMI->type   = mi.type;
      pMI->pDecl  = NULL;
      pMI->level  = 0;
      pMI->offset = 0;
    }
  }

  return 1;
}

/*******************************************************************************
*
*   ROUTINE: get_type_spec
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

int get_type_spec(CBC *THIS, const char *name, const char **pEOS, TypeSpec *pTS)
{
  void *ptr = get_type_pointer(THIS, name, pEOS);

  if (ptr == NULL)
  {
    if (pEOS)
      *pEOS = NULL;

    return get_basic_type_spec(name, pTS);
  }

  switch (GET_CTYPE(ptr))
  {
    case TYP_TYPEDEF:
      pTS->tflags = T_TYPE;
      break;

    case TYP_STRUCT:
      pTS->tflags = ((Struct *) ptr)->tflags;
      break;

    case TYP_ENUM:
      pTS->tflags = T_ENUM;
      break;

    default:
      fatal("Invalid type (%d) in get_type_spec( '%s' )", GET_CTYPE(ptr), name);
      break;
  }

  pTS->ptr = ptr;

  return 1;
}

/*******************************************************************************
*
*   ROUTINE: get_type_name_string
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2003
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

SV *get_type_name_string(pTHX_ const MemberInfo *pMI)
{
  SV *sv;

  if (pMI == NULL)
    fatal("get_type_name_string() called with NULL pointer");

  if (pMI->type.ptr == NULL)
  {
    sv = NULL;
    get_basic_type_spec_string(aTHX_ &sv, pMI->type.tflags);
  }
  else
  {
    switch (GET_CTYPE(pMI->type.ptr))
    {
      case TYP_TYPEDEF:
        sv = newSVpv(((Typedef *) pMI->type.ptr)->pDecl->identifier, 0);
        break;

      case TYP_STRUCT:
        {
          Struct *pS = (Struct *) pMI->type.ptr;
          sv = pS->identifier[0] == '\0'
             ? newSVpv(pS->tflags & T_STRUCT ? "struct" : "union", 0)
             : newSVpvf("%s %s", pS->tflags & T_STRUCT
                                 ? "struct" : "union", pS->identifier);
        }
        break;

      case TYP_ENUM:
        {
          EnumSpecifier *pE = (EnumSpecifier *) pMI->type.ptr;
          sv = pE->identifier[0] == '\0'
             ? newSVpvn("enum", 4)
             : newSVpvf("enum %s", pE->identifier);
        }
        break;

      default:
        fatal("GET_CTYPE() returned an invalid type (%d) "
              "in get_type_name_string()", GET_CTYPE(pMI->type.ptr));
        break;
    }
  }

  if (pMI->pDecl != NULL)
  {
    if (pMI->pDecl->bitfield_flag)
      sv_catpvf(sv, " :%d", pMI->pDecl->ext.bitfield.bits);
    else
    {
      if (pMI->pDecl->pointer_flag)
        sv_catpv(sv, " *");

      if (pMI->pDecl->array_flag)
      {
        int level = pMI->level;
        int count = LL_count(pMI->pDecl->ext.array);

        if (level < count)
        {
          sv_catpv(sv, " ");
          while (level < count)
          {
            Value *pValue = LL_get(pMI->pDecl->ext.array, level);

            if (pValue->flags & V_IS_UNDEF)
              sv_catpvn(sv, "[]", 2);
            else
              sv_catpvf(sv, "[%ld]", pValue->iv);

            level++;
          }
        }
      }
    }
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: is_typedef_defined
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

int is_typedef_defined(Typedef *pTypedef)
{
  if (pTypedef->pDecl->pointer_flag)
    return 1;

  while (pTypedef->pType->tflags & T_TYPE)
  {
    pTypedef = (Typedef *) pTypedef->pType->ptr;

    if (pTypedef->pDecl->pointer_flag)
      return 1;
  }

  if (pTypedef->pType->tflags & T_COMPOUND)
    return ((Struct*) pTypedef->pType->ptr)->declarations != NULL;

  if (pTypedef->pType->tflags & T_ENUM)
    return ((EnumSpecifier*) pTypedef->pType->ptr)->enumerators != NULL;

  return 1;
}

/*******************************************************************************
*
*   ROUTINE: check_allowed_types_string
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2006
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

#define CHECK_ALLOWED(flag, string)                                            \
        STMT_START {                                                           \
          if ((allowed_types & ALLOW_ ## flag) == 0)                           \
            return string;                                                     \
          return NULL;                                                         \
        } STMT_END

const char *check_allowed_types_string(const MemberInfo *pMI, U32 allowed_types)
{
  const Declarator *pDecl = pMI->pDecl;
  const TypeSpec   *pType = &pMI->type;
  int               level = 0;

  if (pType->tflags & T_TYPE &&
      (pDecl == NULL || (!pDecl->pointer_flag && !pDecl->array_flag)))
  {
    do
    {
      const Typedef *pTypedef = (Typedef *) pType->ptr;
      pDecl = pTypedef->pDecl;
      pType = pTypedef->pType;
    }
    while (!pDecl->pointer_flag &&
           !pDecl->array_flag &&
           pType->tflags & T_TYPE);
  }
  else
    level = pMI->level;

  if (pDecl != NULL)
  {
    if (pDecl->array_flag && level < LL_count(pDecl->ext.array))
      CHECK_ALLOWED(ARRAYS, "an array type");

    if (pDecl->pointer_flag)
      CHECK_ALLOWED(POINTERS, "a pointer type");
  }

  if (pType->ptr == NULL)
    CHECK_ALLOWED(BASIC_TYPES, "a basic type");

  if (pType->tflags & T_UNION)
    CHECK_ALLOWED(UNIONS, "a union");

  if (pType->tflags & T_STRUCT)
    CHECK_ALLOWED(STRUCTS, "a struct");

  if (pType->tflags & T_ENUM)
    CHECK_ALLOWED(ENUMS, "an enum");

  return NULL;
}

/*******************************************************************************
*
*   ROUTINE: check_allowed_types
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2003
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

void check_allowed_types(pTHX_ const MemberInfo *pMI, const char *method, U32 allowed_types)
{
  const char *failed_type = check_allowed_types_string(pMI, allowed_types);

  if (failed_type)
    Perl_croak(aTHX_ "Cannot use %s on %s", method, failed_type);
}

