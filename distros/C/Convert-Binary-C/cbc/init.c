/*******************************************************************************
*
* MODULE: init.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C initializer
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
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

#include "util/list.h"

#include "cbc/idl.h"
#include "cbc/init.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

#define INDENT                                \
        STMT_START {                          \
          if (level > 0)                      \
            add_indent(aTHX_ string, level);  \
        } STMT_END

#define APPEND_COMMA                          \
        STMT_START {                          \
          if (first)                          \
            first = 0;                        \
          else                                \
            sv_catpv(string, ",\n");          \
        } STMT_END

#define ENTER_LEVEL                           \
        STMT_START {                          \
          INDENT;                             \
          sv_catpv(string, "{\n");            \
        } STMT_END

#define LEAVE_LEVEL                           \
        STMT_START {                          \
          sv_catpv(string, "\n");             \
          INDENT;                             \
          sv_catpv(string, "}");              \
        } STMT_END


/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void get_init_str_struct(pTHX_ CBC *THIS, Struct *pStruct, SV *init,
                                IDList *idl, int level, SV *string);
static void get_init_str_type(pTHX_ CBC *THIS, TypeSpec *pTS, Declarator *pDecl,
                              int dimension, SV *init, IDList *idl, int level, SV *string);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_init_str_struct
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

static void get_init_str_struct(pTHX_ CBC *THIS, Struct *pStruct, SV *init,
                                IDList *idl, int level, SV *string)
{
  ListIterator       sdi;
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  HV                *hash = NULL;
  int                first = 1;

  CT_DEBUG(MAIN, (XSCLASS "::get_init_str_struct( THIS=%p, pStruct=%p, "
           "init=%p, idl=%p, level=%d, string=%p )",
           THIS, pStruct, init, idl, level, string));

  if (DEFINED(init))
  {
    SV *h;
    if (SvROK(init) && SvTYPE(h = SvRV(init)) == SVt_PVHV)
      hash = (HV *) h;
    else
      WARN((aTHX_ "'%s' should be a hash reference", idl_to_str(aTHX_ idl)));
  }

  ENTER_LEVEL;
  IDLIST_PUSH(idl, ID);

  LL_foreach(pStructDecl, sdi, pStruct->declarations)
  {
    if (pStructDecl->declarators)
    {
      ListIterator di;

      LL_foreach(pDecl, di, pStructDecl->declarators)
      {
        SV **e;

        /* skip unnamed bitfield members right here */
        if (pDecl->bitfield_flag && pDecl->identifier[0] == '\0')
          continue;

        /* skip flexible array members */
        if (pDecl->array_flag && pDecl->size == 0)
          continue;

        e = hash ? hv_fetch(hash, pDecl->identifier, CTT_IDLEN(pDecl), 0) : NULL;
        if(e)
          SvGETMAGIC(*e);

        IDLIST_SET_ID(idl, pDecl->identifier);
        APPEND_COMMA;

        get_init_str_type(aTHX_ THIS, &pStructDecl->type, pDecl, 0,
                          e ? *e : NULL, idl, level+1, string);

        /* only initialize first union member */
        if (pStruct->tflags & T_UNION)
          goto handle_end;
      }
    }
    else
    {
      TypeSpec *pTS = &pStructDecl->type;
      FOLLOW_AND_CHECK_TSPTR(pTS);
      APPEND_COMMA;
      IDLIST_POP(idl);
      get_init_str_struct(aTHX_ THIS, (Struct *) pTS->ptr,
                          init, idl, level+1, string);
      IDLIST_PUSH(idl, ID);

      /* only initialize first union member */
      if (pStruct->tflags & T_UNION)
        goto handle_end;
    }
  }

handle_end:
  IDLIST_POP(idl);
  LEAVE_LEVEL;
}

/*******************************************************************************
*
*   ROUTINE: get_init_str_type
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

static void get_init_str_type(pTHX_ CBC *THIS, TypeSpec *pTS, Declarator *pDecl,
                              int dimension, SV *init, IDList *idl, int level, SV *string)
{
  CT_DEBUG(MAIN, (XSCLASS "::get_init_str_type( THIS=%p, pTS=%p, pDecl=%p, "
           "dimension=%d, init=%p, idl=%p, level=%d, string=%p )",
           THIS, pTS, pDecl, dimension, init, idl, level, string));

  if (pDecl && pDecl->array_flag && dimension < LL_count(pDecl->ext.array))
  {
    AV *ary = NULL;
    long i, s = ((Value *) LL_get(pDecl->ext.array, dimension))->iv;
    int first = 1;

    if (DEFINED(init))
    {
      SV *sv;
      if (SvROK(init) && SvTYPE(sv = SvRV(init)) == SVt_PVAV)
        ary = (AV *) sv;
      else
        WARN((aTHX_ "'%s' should be an array reference",
                    idl_to_str(aTHX_ idl)));
    }

    ENTER_LEVEL;
    IDLIST_PUSH(idl, IX);

    for (i = 0; i < s; ++i)
    {
      SV **e = ary ? av_fetch(ary, i, 0) : NULL;

      if (e)
        SvGETMAGIC(*e);

      IDLIST_SET_IX(idl, i);
      APPEND_COMMA;

      get_init_str_type(aTHX_ THIS, pTS, pDecl, dimension+1,
                        e ? *e : NULL, idl, level+1, string);
    }

    IDLIST_POP(idl);
    LEAVE_LEVEL;
  }
  else
  {
    if (pDecl && pDecl->pointer_flag)
      goto handle_basic;
    else if(pTS->tflags & T_TYPE)
    {
      Typedef *pTD = (Typedef *) pTS->ptr;
      get_init_str_type(aTHX_ THIS, pTD->pType, pTD->pDecl, 0, init, idl, level, string);
    }
    else if(pTS->tflags & T_COMPOUND)
    {
      Struct *pStruct = pTS->ptr;
      if (pStruct->declarations == NULL)
        WARN_UNDEF_STRUCT(pStruct);
      get_init_str_struct(aTHX_ THIS, pStruct, init, idl, level, string);
    }
    else
    {
handle_basic:
      INDENT;
      if (DEFINED(init))
      {
        if (SvROK(init))
          WARN((aTHX_ "'%s' should be a scalar value", idl_to_str(aTHX_ idl)));
        sv_catsv(string, init);
      }
      else
        sv_catpvn(string, "0", 1);
    }
  }
}

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_initializer_string
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

SV *get_initializer_string(pTHX_ CBC *THIS, MemberInfo *pMI, SV *init, const char *name)
{
  SV *string = newSVpvn("", 0);
  IDList idl;

  IDLIST_INIT(&idl);
  IDLIST_PUSH(&idl, ID);
  IDLIST_SET_ID(&idl, name);

  get_init_str_type(aTHX_ THIS, &pMI->type, pMI->pDecl, pMI->level, init, &idl, 0, string);

  IDLIST_FREE(&idl);

  return string;
}

