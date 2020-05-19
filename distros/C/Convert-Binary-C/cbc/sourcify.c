/*******************************************************************************
*
* MODULE: sourcify.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C sourcify
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

#include "ctlib/cttype.h"

#include "cbc/cbc.h"
#include "cbc/idl.h"
#include "cbc/sourcify.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

#define T_ALREADY_DUMPED   T_USER_FLAG_1

#define F_NEWLINE          0x00000001
#define F_KEYWORD          0x00000002
#define F_DONT_EXPAND      0x00000004
#define F_PRAGMA_PACK_POP  0x00000008

#define SRC_INDENT                       \
        STMT_START {                     \
          if (level > 0)                 \
            add_indent(aTHX_ s, level);  \
        } STMT_END

#define CHECK_SET_KEYWORD                \
        STMT_START {                     \
          if (pSS->flags & F_KEYWORD)    \
            sv_catpvn(s, " ", 1);        \
          else                           \
            SRC_INDENT;                  \
          pSS->flags &= ~F_NEWLINE;      \
          pSS->flags |= F_KEYWORD;       \
        } STMT_END

#define SvGROW_early(s, granularity)                   \
        STMT_START {                                   \
          if (SvCUR(s) + ((granularity)/2) > SvLEN(s)) \
            SvGROW(s, SvCUR(s) + (granularity));       \
        } STMT_END

#define SVG_STRUCT 512
#define SVG_ENUM   512

/*===== TYPEDEFS =============================================================*/

typedef struct {
  U32      flags;
  unsigned pack;
} SourcifyState;


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void check_define_type(pTHX_ SourcifyConfig *pSC, SV *str, TypeSpec *pTS);

static void add_type_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *str, SV *s,
                                     TypeSpec *pTS, int level, SourcifyState *pSS);
static void add_enum_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *s,
                                     EnumSpecifier *pES, int level, SourcifyState *pSS);
static void add_struct_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *str, SV *s,
                                       Struct *pStruct, int level, SourcifyState *pSS);

static void add_typedef_list_decl_string(pTHX_ SV *str, TypedefList *pTDL);
static void add_typedef_list_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, TypedefList *pTDL);
static void add_enum_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, EnumSpecifier *pES);
static void add_struct_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, Struct *pStruct);

static void pp_macro_callback(const CMacroInfo *pmi);
static void add_preprocessor_definitions(pTHX_ CParseInfo *pCPI, SV *str);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: check_define_type
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

static void check_define_type(pTHX_ SourcifyConfig *pSC, SV *str, TypeSpec *pTS)
{
  u_32 flags = pTS->tflags;

  CT_DEBUG(MAIN, (XSCLASS "::check_define_type( pTS=(tflags=0x%08lX, ptr=%p) )",
                  (unsigned long) pTS->tflags, pTS->ptr));

  if (flags & T_TYPE)
  {
    Typedef *pTypedef= (Typedef *) pTS->ptr;

    while (!pTypedef->pDecl->pointer_flag && pTypedef->pType->tflags & T_TYPE)
      pTypedef = (Typedef *) pTypedef->pType->ptr;

    if (pTypedef->pDecl->pointer_flag)
      return;

    pTS   = pTypedef->pType;
    flags = pTS->tflags;
  }

  if (flags & T_ENUM)
  {
    EnumSpecifier *pES = (EnumSpecifier *) pTS->ptr;

    if (pES && (pES->tflags & T_ALREADY_DUMPED) == 0)
      add_enum_spec_string(aTHX_ pSC, str, pES);
  }
  else if (flags & T_COMPOUND)
  {
    Struct *pStruct = (Struct *) pTS->ptr;

    if (pStruct && (pStruct->tflags & T_ALREADY_DUMPED) == 0)
      add_struct_spec_string(aTHX_ pSC, str, pStruct);
  }
}

/*******************************************************************************
*
*   ROUTINE: add_type_spec_string_rec
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

static void add_type_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *str, SV *s,
                                     TypeSpec *pTS, int level, SourcifyState *pSS)
{
  u_32 flags = pTS->tflags;

  CT_DEBUG(MAIN, (XSCLASS "::add_type_spec_string_rec( pTS=(tflags=0x%08lX, ptr=%p"
                          "), level=%d, pSS->flags=0x%08lX, pSS->pack=%u )",
                          (unsigned long) pTS->tflags, pTS->ptr, level,
                          (unsigned long) pSS->flags, pSS->pack));

  if (flags & T_TYPE)
  {
    Typedef *pTypedef= (Typedef *) pTS->ptr;

    if (pTypedef && pTypedef->pDecl->identifier[0])
    {
      CHECK_SET_KEYWORD;
      sv_catpv(s, pTypedef->pDecl->identifier);
    }
  }
  else if (flags & T_ENUM)
  {
    EnumSpecifier *pES = (EnumSpecifier *) pTS->ptr;

    if (pES)
    {
      if (pES->identifier[0] && ((pES->tflags & T_ALREADY_DUMPED) ||
                                 (pSS->flags & F_DONT_EXPAND)))
      {
        CHECK_SET_KEYWORD;
        sv_catpvf(s, "enum %s", pES->identifier);
      }
      else
        add_enum_spec_string_rec(aTHX_ pSC, s, pES, level, pSS);
    }
  }
  else if (flags & T_COMPOUND)
  {
    Struct *pStruct = (Struct *) pTS->ptr;

    if (pStruct)
    {
      if (pStruct->identifier[0] && ((pStruct->tflags & T_ALREADY_DUMPED) ||
                                     (pSS->flags & F_DONT_EXPAND)))
      {
        CHECK_SET_KEYWORD;
        sv_catpvf(s, "%s %s", flags & T_UNION ? "union" : "struct",
                              pStruct->identifier);
      }
      else
        add_struct_spec_string_rec(aTHX_ pSC, str, s, pStruct, level, pSS);
    }
  }
  else
  {
    CHECK_SET_KEYWORD;
    get_basic_type_spec_string(aTHX_ &s, flags);
  }
}

/*******************************************************************************
*
*   ROUTINE: add_enum_spec_string_rec
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:\
*             \
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static void add_enum_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *s,
                                     EnumSpecifier *pES, int level, SourcifyState *pSS)
{
  CT_DEBUG(MAIN, (XSCLASS "::add_enum_spec_string_rec( pES=(identifier=\"%s\"),"
                          " level=%d, pSS->flags=0x%08lX, pSS->pack=%u )",
                          pES->identifier, level, (unsigned long) pSS->flags, pSS->pack));

  SvGROW_early(s, SVG_ENUM);

  pES->tflags |= T_ALREADY_DUMPED;

  if (pSC->context)
  {
    if ((pSS->flags & F_NEWLINE) == 0)
    {
      sv_catpvn(s, "\n", 1);
      pSS->flags &= ~F_KEYWORD;
      pSS->flags |= F_NEWLINE;
    }
    sv_catpvf(s, "#line %lu \"%s\"\n", pES->context.line,
                                       pES->context.pFI->name);
  }

  if (pSS->flags & F_KEYWORD)
    sv_catpvn(s, " ", 1);
  else
    SRC_INDENT;

  pSS->flags &= ~(F_NEWLINE|F_KEYWORD);

  sv_catpvn(s, "enum", 4);
  if (pES->identifier[0])
    sv_catpvf(s, " %s", pES->identifier);

  if (pES->enumerators)
  {
    ListIterator ei;
    Enumerator *pEnum;
    int         first = 1;
    Value       lastVal;

    sv_catpvn(s, "\n", 1);
    SRC_INDENT;
    sv_catpvn(s, "{", 1);

    LL_foreach(pEnum, ei, pES->enumerators)
    {
      if (!first)
        sv_catpvn(s, ",", 1);

      sv_catpvn(s, "\n", 1);
      SRC_INDENT;

      if (( first && pEnum->value.iv == 0) ||
          (!first && pEnum->value.iv == lastVal.iv + 1))
        sv_catpvf(s, "\t%s", pEnum->identifier);
      else
        sv_catpvf(s, "\t%s = %ld", pEnum->identifier, pEnum->value.iv);

      if (first)
        first = 0;

      lastVal = pEnum->value;
    }

    sv_catpvn(s, "\n", 1);
    SRC_INDENT;
    sv_catpvn(s, "}", 1);
  }
}

/*******************************************************************************
*
*   ROUTINE: add_struct_spec_string_rec
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

static void add_struct_spec_string_rec(pTHX_ SourcifyConfig *pSC, SV *str, SV *s,
                                       Struct *pStruct, int level, SourcifyState *pSS)
{
  int pack_pushed;

  CT_DEBUG(MAIN, (XSCLASS "::add_struct_spec_string_rec( pStruct=(identifier="
                          "\"%s\", pack=%d, tflags=0x%08lX), level=%d"
                          " pSS->flags=0x%08lX, pSS->pack=%u )",
                          pStruct->identifier,
                          pStruct->pack, (unsigned long) pStruct->tflags,
                          level, (unsigned long) pSS->flags, pSS->pack));

  SvGROW_early(s, SVG_STRUCT);

  pStruct->tflags |= T_ALREADY_DUMPED;

  pack_pushed = pStruct->declarations
             && pStruct->pack
             && pStruct->pack != pSS->pack;

  if (pack_pushed)
  {
    if ((pSS->flags & F_NEWLINE) == 0)
    {
      sv_catpvn(s, "\n", 1);
      pSS->flags &= ~F_KEYWORD;
      pSS->flags |= F_NEWLINE;
    }
    sv_catpvf(s, "#pragma pack(push, %u)\n", pStruct->pack);
  }

  if (pSC->context)
  {
    if ((pSS->flags & F_NEWLINE) == 0)
    {
      sv_catpvn(s, "\n", 1);
      pSS->flags &= ~F_KEYWORD;
      pSS->flags |= F_NEWLINE;
    }
    sv_catpvf(s, "#line %lu \"%s\"\n", pStruct->context.line,
                                       pStruct->context.pFI->name);
  }

  if (pSS->flags & F_KEYWORD)
    sv_catpvn(s, " ", 1);
  else
    SRC_INDENT;

  pSS->flags &= ~(F_NEWLINE|F_KEYWORD);

  if(pStruct->tflags & T_STRUCT)
    sv_catpvn(s, "struct", 6);
  else
    sv_catpvn(s, "union", 5);

  if (pStruct->identifier[0])
    sv_catpvf(s, " %s", pStruct->identifier);

  if (pStruct->declarations)
  {
    ListIterator sdi;
    StructDeclaration *pStructDecl;

    sv_catpvn(s, "\n", 1);
    SRC_INDENT;
    sv_catpvn(s, "{\n", 2);

    LL_foreach(pStructDecl, sdi, pStruct->declarations)
    {
      ListIterator di;
      Declarator *pDecl;
      int first = 1, need_def = 0;
      SourcifyState ss;

      ss.flags = F_NEWLINE;
      ss.pack  = pack_pushed ? pStruct->pack : 0;

      LL_foreach(pDecl, di, pStructDecl->declarators)
        if (pDecl->pointer_flag == 0)
        {
          need_def = 1;
          break;
        }

      if (!need_def)
        ss.flags |= F_DONT_EXPAND;

      add_type_spec_string_rec(aTHX_ pSC, str, s, &pStructDecl->type, level+1, &ss);

      ss.flags &= ~F_DONT_EXPAND;

      if (ss.flags & F_NEWLINE)
        add_indent(aTHX_ s, level+1);
      else if (pStructDecl->declarators)
        sv_catpvn(s, " ", 1);

      LL_foreach(pDecl, di, pStructDecl->declarators)
      {
        Value *pValue;

        if (first)
          first = 0;
        else
          sv_catpvn(s, ", ", 2);

        if (pDecl->bitfield_flag)
        {
          sv_catpvf(s, "%s:%d", pDecl->identifier, pDecl->ext.bitfield.bits);
        }
        else {
          sv_catpvf(s, "%s%s", pDecl->pointer_flag ? "*" : "",
                               pDecl->identifier);

          if (pDecl->array_flag)
          {
            ListIterator ai;

            LL_foreach(pValue, ai, pDecl->ext.array)
            {
              if (pValue->flags & V_IS_UNDEF)
                sv_catpvn(s, "[]", 2);
              else
                sv_catpvf(s, "[%ld]", pValue->iv);
            }
          }
        }
      }

      sv_catpvn(s, ";\n", 2);

      if (ss.flags & F_PRAGMA_PACK_POP)
        sv_catpvn(s, "#pragma pack(pop)\n", 18);

      if (need_def)
        check_define_type(aTHX_ pSC, str, &pStructDecl->type);
    }

    SRC_INDENT;
    sv_catpvn(s, "}", 1);
  }

  if (pack_pushed)
    pSS->flags |= F_PRAGMA_PACK_POP;
}

/*******************************************************************************
*
*   ROUTINE: add_typedef_list_decl_string
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

static void add_typedef_list_decl_string(pTHX_ SV *str, TypedefList *pTDL)
{
  ListIterator ti;
  Typedef *pTypedef;
  int first = 1;

  CT_DEBUG(MAIN, (XSCLASS "::add_typedef_list_decl_string( pTDL=%p )", pTDL));

  LL_foreach(pTypedef, ti, pTDL->typedefs)
  {
    Declarator *pDecl = pTypedef->pDecl;
    Value *pValue;

    if (first)
      first = 0;
    else
      sv_catpvn(str, ", ", 2);

    sv_catpvf(str, "%s%s", pDecl->pointer_flag ? "*" : "", pDecl->identifier);

    if (pDecl->array_flag)
    {
      ListIterator ai;

      LL_foreach(pValue, ai, pDecl->ext.array)
      {
        if (pValue->flags & V_IS_UNDEF)
          sv_catpvn(str, "[]", 2);
        else
          sv_catpvf(str, "[%ld]", pValue->iv);
      }
    }
  }
}

/*******************************************************************************
*
*   ROUTINE: add_typedef_list_spec_string
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

static void add_typedef_list_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, TypedefList *pTDL)
{
  SV *s = newSVpv("typedef", 0);
  SourcifyState ss;

  CT_DEBUG(MAIN, (XSCLASS "::add_typedef_list_spec_string( pTDL=%p )", pTDL));

  ss.flags = F_KEYWORD;
  ss.pack  = 0;

  add_type_spec_string_rec(aTHX_ pSC, str, s, &pTDL->type, 0, &ss);

  if ((ss.flags & F_NEWLINE) == 0)
    sv_catpvn(s, " ", 1);

  add_typedef_list_decl_string(aTHX_ s, pTDL);

  sv_catpvn(s, ";\n", 2);

  if (ss.flags & F_PRAGMA_PACK_POP)
    sv_catpvn(s, "#pragma pack(pop)\n", 18);

  sv_catsv(str, s);

  SvREFCNT_dec(s);
}

/*******************************************************************************
*
*   ROUTINE: add_enum_spec_string
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

static void add_enum_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, EnumSpecifier *pES)
{
  SV *s = newSVpvn("", 0);
  SourcifyState ss;

  CT_DEBUG(MAIN, (XSCLASS "::add_enum_spec_string( pES=%p )", pES));

  ss.flags = 0;
  ss.pack  = 0;

  add_enum_spec_string_rec(aTHX_ pSC, s, pES, 0, &ss);
  sv_catpvn(s, ";\n", 2);
  sv_catsv(str, s);

  SvREFCNT_dec(s);
}

/*******************************************************************************
*
*   ROUTINE: add_struct_spec_string
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

static void add_struct_spec_string(pTHX_ SourcifyConfig *pSC, SV *str, Struct *pStruct)
{
  SV *s = newSVpvn("", 0);
  SourcifyState ss;

  CT_DEBUG(MAIN, (XSCLASS "::add_struct_spec_string( pStruct=%p )", pStruct));

  ss.flags = 0;
  ss.pack  = 0;

  add_struct_spec_string_rec(aTHX_ pSC, str, s, pStruct, 0, &ss);
  sv_catpvn(s, ";\n", 2);

  if (ss.flags & F_PRAGMA_PACK_POP)
    sv_catpvn(s, "#pragma pack(pop)\n", 18);

  sv_catsv(str, s);

  SvREFCNT_dec(s);
}

/*******************************************************************************
*
*   ROUTINE: pp_macro_callback
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

#define SvGROWexp(s, amount)                                                   \
        BEGIN_STMT {                                                           \
          if (SvCUR(s) + pmi->definition_len + 10 >= SvLEN(s))                 \
            SvGROW(s, 2*SvLEN(s));                                             \
        } END_STMT

struct macro_cb_arg
{
#ifdef PERL_IMPLICIT_CONTEXT
  void *interp;
#endif
  SV *string;
};

static void pp_macro_callback(const CMacroInfo *pmi)
{
  struct macro_cb_arg *a = pmi->arg;
  SV *s = a->string;
  dTHXa(a->interp);

  if (SvCUR(s) + pmi->definition_len + 10 >= SvLEN(s))
    SvGROW(s, 2*SvLEN(s));

  sv_catpvn(s, "#define ", 8);
  sv_catpvn(s, pmi->definition, pmi->definition_len);
  sv_catpvn(s, "\n", 1);
}

/*******************************************************************************
*
*   ROUTINE: add_preprocessor_definitions
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

static void add_preprocessor_definitions(pTHX_ CParseInfo *pCPI, SV *str)
{
  struct macro_cb_arg a;
  SV *s = newSVpvn("", 0);

#ifdef PERL_IMPLICIT_CONTEXT
  a.interp = aTHX;
#endif
  a.string = s;

  SvGROW(s, 512);

  macro_iterate_defs(pCPI, pp_macro_callback, &a, CMIF_WITH_DEFINITION |
                                                  CMIF_NO_PREDEFINED);

  if (SvCUR(s) > 0)
  {
    sv_catpv(str, "/* preprocessor defines */\n\n");
    sv_catsv(str, s);
    sv_catpvn(str, "\n", 1);
  }

  SvREFCNT_dec(s);
}

/*******************************************************************************
*
*   ROUTINE: get_sourcify_config_option
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2003
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

#include "token/t_sourcify.c"


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_sourcify_config
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2003
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

void get_sourcify_config(pTHX_ HV *cfg, SourcifyConfig *pSC)
{
  HE *opt;

  (void) hv_iterinit(cfg);

  while ((opt = hv_iternext(cfg)) != NULL)
  {
    const char *key;
    I32 keylen;
    SV *value;

    key   = hv_iterkey(opt, &keylen);
    value = hv_iterval(cfg, opt);

    switch (get_sourcify_config_option(key))
    {
      case SOURCIFY_OPTION_Context:
        pSC->context = SvTRUE(value);
        break;

      case SOURCIFY_OPTION_Defines:
        pSC->defines = SvTRUE(value);
        break;

      default:
        Perl_croak(aTHX_ "Invalid option '%s'", key);
    }
  }
}

/*******************************************************************************
*
*   ROUTINE: get_parsed_definitions_string
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

SV *get_parsed_definitions_string(pTHX_ CParseInfo *pCPI, SourcifyConfig *pSC)
{
  ListIterator   li;
  TypedefList   *pTDL;
  EnumSpecifier *pES;
  Struct        *pStruct;
  int            fTypedefPre = 0, fTypedef = 0, fEnum = 0,
                 fStruct = 0, fUndefEnum = 0, fUndefStruct = 0;

  SV *s = newSVpvn("", 0);

  CT_DEBUG(MAIN, (XSCLASS "::get_parsed_definitions_string( pCPI=%p, pSC=%p )", pCPI, pSC));

  /* typedef predeclarations */

  LL_foreach(pTDL, li, pCPI->typedef_lists)
  {
    u_32 tflags = pTDL->type.tflags;

    if ((tflags & (T_ENUM|T_STRUCT|T_UNION|T_TYPE)) == 0)
    {
      if (!fTypedefPre)
      {
        sv_catpv(s, "/* typedef predeclarations */\n\n");
        fTypedefPre = 1;
      }
      add_typedef_list_spec_string(aTHX_ pSC, s, pTDL);
    }
    else
    {
      const char *what = NULL, *ident;

      if (tflags & T_ENUM)
      {
        EnumSpecifier *pES = (EnumSpecifier *) pTDL->type.ptr;
        if (pES && pES->identifier[0] != '\0')
        {
          what  = "enum";
          ident = pES->identifier;
        }
      }
      else if (tflags & T_COMPOUND)
      {
        Struct *pStruct = (Struct *) pTDL->type.ptr;
        if (pStruct && pStruct->identifier[0] != '\0')
        {
          what  = pStruct->tflags & T_STRUCT ? "struct" : "union";
          ident = pStruct->identifier;
        }
      }

      if (what != NULL)
      {
        if (!fTypedefPre)
        {
          sv_catpv(s, "/* typedef predeclarations */\n\n");
          fTypedefPre = 1;
        }
        sv_catpvf(s, "typedef %s %s ", what, ident);
        add_typedef_list_decl_string(aTHX_ s, pTDL);
        sv_catpvn(s, ";\n", 2);
      }
    }
  }

  /* typedefs */

  LL_foreach(pTDL, li, pCPI->typedef_lists)
    if (pTDL->type.ptr != NULL)
      if (((pTDL->type.tflags & T_ENUM) &&
           ((EnumSpecifier *) pTDL->type.ptr)->identifier[0] == '\0') ||
          ((pTDL->type.tflags & T_COMPOUND) &&
           ((Struct *) pTDL->type.ptr)->identifier[0] == '\0') ||
          (pTDL->type.tflags & T_TYPE))
      {
        if (!fTypedef)
        {
          sv_catpv(s, "\n\n/* typedefs */\n\n");
          fTypedef = 1;
        }
        add_typedef_list_spec_string(aTHX_ pSC, s, pTDL);
        sv_catpvn(s, "\n", 1);
      }

  /* defined enums */

  LL_foreach(pES, li, pCPI->enums)
    if (pES->enumerators &&
        pES->identifier[0] != '\0' &&
        (pES->tflags & (T_ALREADY_DUMPED)) == 0)
    {
      if (!fEnum)
      {
        sv_catpv(s, "\n/* defined enums */\n\n");
        fEnum = 1;
      }
      add_enum_spec_string(aTHX_ pSC, s, pES);
      sv_catpvn(s, "\n", 1);
    }

  /* defined structs and unions */

  LL_foreach(pStruct, li, pCPI->structs)
    if(pStruct->declarations &&
       pStruct->identifier[0] != '\0' &&
       (pStruct->tflags & (T_ALREADY_DUMPED)) == 0)
    {
      if (!fStruct)
      {
        sv_catpv(s, "\n/* defined structs and unions */\n\n");
        fStruct = 1;
      }
      add_struct_spec_string(aTHX_ pSC, s, pStruct);
      sv_catpvn(s, "\n", 1);
    }

  /* undefined enums */

  LL_foreach(pES, li, pCPI->enums)
  {
    if ((pES->tflags & T_ALREADY_DUMPED) == 0 && pES->refcount == 0)
    {
      if (pES->enumerators || pES->identifier[0] != '\0')
      {
        if (!fUndefEnum)
        {
          sv_catpv(s, "\n/* undefined enums */\n\n");
          fUndefEnum = 1;
        }
        add_enum_spec_string(aTHX_ pSC, s, pES);
        sv_catpvn(s, "\n", 1);
      }
    }

    pES->tflags &= ~T_ALREADY_DUMPED;
  }

  /* undefined structs and unions */

  LL_foreach(pStruct, li, pCPI->structs)
  {
    if ((pStruct->tflags & T_ALREADY_DUMPED) == 0 && pStruct->refcount == 0)
    {
      if (pStruct->declarations || pStruct->identifier[0] != '\0')
      {
        if (!fUndefStruct)
        {
          sv_catpv(s, "\n/* undefined/unnamed structs and unions */\n\n");
          fUndefStruct = 1;
        }
        add_struct_spec_string(aTHX_ pSC, s, pStruct);
        sv_catpvn(s, "\n", 1);
      }
    }

    pStruct->tflags &= ~T_ALREADY_DUMPED;
  }

  /*
   * preprocessor stuff
   *
   * NOTE: This _must_ be at the end, because, if placed at the top, some
   *       defines may already interfere with the C code.
   */

  if (pSC->defines)
    add_preprocessor_definitions(aTHX_ pCPI, s);

  return s;
}

