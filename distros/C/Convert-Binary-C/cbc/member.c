/*******************************************************************************
*
* MODULE: member.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C compound member utilities
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

#include "cbc/member.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/* for fast index -> string conversion */
#define MAX_IXSTR 15


/*===== TYPEDEFS =============================================================*/

typedef enum { GMS_NONE, GMS_PAD, GMS_HIT_OFF, GMS_HIT } GMSRV;

typedef union {
  LinkedList list;
  int        count;
} AMSInfo;

struct member_expr {
  enum {
    ST_MEMBER,
    ST_INDEX,
    ST_FINISH_INDEX,
    ST_SEARCH,
    ST_TERM
  } state;
  const char *p;
  unsigned startup : 1;
  unsigned has_dot : 1;
  char buf[1];
};


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void get_ams_struct(pTHX_ Struct *pStruct, SV *name, int level, AMSInfo *info);
static void get_ams_type(pTHX_ TypeSpec *pTS, Declarator *pDecl, int dimension,
                         SV *name, int level, AMSInfo *info);

static GMSRV append_member_string_rec(pTHX_ const TypeSpec *pType, const Declarator *pDecl,
                                      int offset, SV *sv, GMSInfo *pInfo);
static GMSRV get_member_string_rec(pTHX_ const Struct *pStruct, int offset,
                                   int realoffset, SV *sv, GMSInfo *pInfo);

static int search_struct_member(Struct *pStruct, const char *elem,
                                StructDeclaration **ppSD, Declarator **ppD);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_ams_struct
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

static void get_ams_struct(pTHX_ Struct *pStruct, SV *name, int level, AMSInfo *info)
{
  ListIterator       sdi;
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  STRLEN             len;

  CT_DEBUG(MAIN, (XSCLASS "::get_ams_struct( pStruct=%p, name='%s', level=%d, info=%p )",
           pStruct, name ? SvPV_nolen(name) : "", level, info));

  if (name)
  {
    len = SvCUR(name);
    sv_catpvn_nomg(name, ".", 1);
  }

  LL_foreach(pStructDecl, sdi, pStruct->declarations)
  {
    if (pStructDecl->declarators)
    {
      ListIterator di;

      LL_foreach(pDecl, di, pStructDecl->declarators)
      {
        /* skip unnamed bitfield members right here */
        if (pDecl->bitfield_flag && pDecl->identifier[0] == '\0')
          continue;

        if (name)
        {
          SvCUR_set(name, len+1);
          sv_catpvn_nomg(name, pDecl->identifier, CTT_IDLEN(pDecl));
        }

        get_ams_type(aTHX_ &pStructDecl->type, pDecl, 0, name, level+1, info);
      }
    }
    else
    {
      TypeSpec *pTS = &pStructDecl->type;
      FOLLOW_AND_CHECK_TSPTR(pTS);
      if (name)
        SvCUR_set(name, len);
      get_ams_struct(aTHX_ (Struct *) pTS->ptr, name, level+1, info);
    }
  }

  if (name)
    SvCUR_set(name, len);
}

/*******************************************************************************
*
*   ROUTINE: get_ams_type
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

static void get_ams_type(pTHX_ TypeSpec *pTS, Declarator *pDecl, int dimension,
                         SV *name, int level, AMSInfo *info)
{
  CT_DEBUG(MAIN, (XSCLASS "::get_ams_type( pTS=%p, pDecl=%p, dimension=%d, "
           "name='%s', level=%d, info=%p )", pTS, pDecl, dimension,
           name ? SvPV_nolen(name) : "", level, info));

  if (pDecl && pDecl->array_flag && dimension < LL_count(pDecl->ext.array))
  {
    Value *pValue = (Value *) LL_get(pDecl->ext.array, dimension);

    if ((pValue->flags & V_IS_UNDEF) == 0)
    {
      long i, ix, s = pValue->iv;
      STRLEN len;
      char ixstr[MAX_IXSTR+1];
      int  ixlen;

      if (name)
      {
        len = SvCUR(name);
        sv_catpvn_nomg(name, "[", 1);
        ixstr[MAX_IXSTR-1] = ']';
        ixstr[MAX_IXSTR]   = '\0';
      }

      for (i = 0; i < s; i++)
      {
        if (name)
        {
          SvCUR_set(name, len+1);

          for (ix = i, ixlen = 2; ixlen < MAX_IXSTR; ix /= 10, ixlen++)
          {
            ixstr[MAX_IXSTR-ixlen] = (char)('0'+(ix%10));
            if (ix < 10)
              break;
          }

          sv_catpvn_nomg(name, ixstr+MAX_IXSTR-ixlen, ixlen);
        }

        get_ams_type(aTHX_ pTS, pDecl, dimension+1, name, level+1, info);
      }

      if (name)
        SvCUR_set(name, len);
    }
  }
  else
  {
    if (pDecl && pDecl->pointer_flag)
      goto handle_basic;
    else if (pTS->tflags & T_TYPE)
    {
      Typedef *pTD = (Typedef *) pTS->ptr;
      get_ams_type(aTHX_ pTD->pType, pTD->pDecl, 0, name, level, info);
    }
    else if (pTS->tflags & T_COMPOUND)
    {
      Struct *pStruct = pTS->ptr;

      if (pStruct->declarations == NULL)
        WARN_UNDEF_STRUCT(pStruct);

      get_ams_struct(aTHX_ pStruct, name, level, info);
    }
    else
    {
handle_basic:
      if (name)
        LL_push(info->list, newSVsv(name));
      else
        info->count++;
    }
  }
}

/*******************************************************************************
*
*   ROUTINE: append_member_string_rec
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2003
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

static GMSRV append_member_string_rec(pTHX_ const TypeSpec *pType, const Declarator *pDecl,
                                      int offset, SV *sv, GMSInfo *pInfo)
{
  CT_DEBUG(MAIN, ("append_member_string_rec( off=%d, sv='%s' )", offset, SvPV_nolen(sv)));

  if (pDecl && pDecl->identifier[0] != '\0')
  {
    CT_DEBUG(MAIN, ("Appending identifier [%s]", pDecl->identifier));
    sv_catpvf(sv, ".%s", CONST_CHAR(pDecl->identifier));
  }

  if (pDecl == NULL && pType->tflags & T_TYPE)
  {
    Typedef *pTypedef = (Typedef *) pType->ptr;
    pDecl = pTypedef->pDecl;
    pType = pTypedef->pType;
  }

  if (pDecl != NULL)
  {
    if (pDecl->offset > 0)
      offset -= pDecl->offset;

    for(;;)
    {
      int index, size;
      Value *pValue;

      if (pDecl->size < 0)
        fatal("pDecl->size is not initialized in append_member_string_rec()");

      size = pDecl->size;

      if (pDecl->array_flag)
      {
        ListIterator ai;

        LL_foreach(pValue, ai, pDecl->ext.array)
        {
          size /= pValue->iv;
          index = offset/size;
          CT_DEBUG(MAIN, ("Appending array size [%d]", index));
          sv_catpvf(sv, "[%d]", index);
          offset -= index*size;
        }
      }

      if (pDecl->pointer_flag || (pType->tflags & T_TYPE) == 0)
        break;

      do
      {
        Typedef *pTypedef = (Typedef *) pType->ptr;
        pDecl = pTypedef->pDecl;
        pType = pTypedef->pType;
      }
      while (!pDecl->pointer_flag &&
             pType->tflags & T_TYPE &&
             pDecl->array_flag == 0);
    }
  }

  if ((pDecl == NULL || !pDecl->pointer_flag) &&
      pType->tflags & T_COMPOUND)
    return get_member_string_rec(aTHX_ pType->ptr, offset, offset, sv, pInfo);

  if (offset > 0)
  {
    CT_DEBUG(MAIN, ("Appending type offset [+%d]", offset));
    sv_catpvf(sv, "+%d", offset);

    if (pInfo && pInfo->off)
      LL_push(pInfo->off, newSVsv(sv));

    return GMS_HIT_OFF;
  }

  if (pInfo && pInfo->hit)
    LL_push(pInfo->hit, newSVsv(sv));

  return GMS_HIT;
}

/*******************************************************************************
*
*   ROUTINE: get_member_string_rec
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2003
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

#define GMS_HANDLE_PAD_REGION                                                  \
        STMT_START {                                                           \
          CT_DEBUG(MAIN, ("Padding region found, exiting"));                   \
          sv_catpvf(sv, "+%d", realoffset);                                    \
          if (pInfo && pInfo->pad)                                             \
          {                                                                    \
            const char *str;                                                   \
            STRLEN      len;                                                   \
            str = SvPV(sv, len);                                               \
            if (HT_store(pInfo->htpad, str, len, 0, NULL))                     \
              LL_push(pInfo->pad, newSVsv(sv));                                \
          }                                                                    \
          return GMS_PAD;                                                      \
        } STMT_END

#define GMS_HANDLE_BEST_MEMBER                                                 \
        STMT_START {                                                           \
          if (rval > best)                                                     \
          {                                                                    \
            CT_DEBUG(MAIN, ("New member [%s] has better ranking (%d) than "    \
                            "old member [%s] (%d)", SvPV_nolen(tmpSV), rval,   \
                            bestSV ? SvPV_nolen(bestSV) : "", best));          \
                                                                               \
            best = rval;                                                       \
                                                                               \
            if (bestSV)                                                        \
            {                                                                  \
              SV *t;                                                           \
              t      = tmpSV;                                                  \
              tmpSV  = bestSV;                                                 \
              bestSV = t;                                                      \
            }                                                                  \
            else                                                               \
            {                                                                  \
              bestSV = tmpSV;                                                  \
              tmpSV  = NULL;                                                   \
            }                                                                  \
          }                                                                    \
                                                                               \
          if (best == GMS_HIT && pInfo == NULL)                                \
          {                                                                    \
            CT_DEBUG(MAIN, ("Hit compound member without offset"));            \
            goto handle_union_end;                                             \
          }                                                                    \
        } STMT_END

static GMSRV get_member_string_rec(pTHX_ const Struct *pStruct, int offset,
                                   int realoffset, SV *sv, GMSInfo *pInfo)
{
  ListIterator       sdi;
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  SV                *tmpSV, *bestSV;
  GMSRV              best;
  int                isUnion;

  CT_DEBUG(MAIN, ("get_member_string_rec( off=%d, roff=%d, sv='%s' )",
                  offset, realoffset, SvPV_nolen(sv)));

  if (pStruct->declarations == NULL)
  {
    WARN_UNDEF_STRUCT(pStruct);
    return GMS_NONE;
  }

  if ((isUnion = pStruct->tflags & T_UNION) != 0)
  {
    best   = GMS_NONE;
    bestSV = NULL;
    tmpSV  = NULL;
  }

  LL_foreach(pStructDecl, sdi, pStruct->declarations)
  {
    CT_DEBUG(MAIN, ("Current StructDecl: offset=%d size=%d decl=%p",
             pStructDecl->offset, pStructDecl->size, pStructDecl->declarators));

    if (pStructDecl->offset > offset)
      GMS_HANDLE_PAD_REGION;

    if (pStructDecl->offset <= offset &&
        offset < pStructDecl->offset+pStructDecl->size)
    {
      CT_DEBUG(MAIN, ("Member possilbly within current StructDecl (%d <= %d < %d)",
               pStructDecl->offset, offset, pStructDecl->offset+pStructDecl->size));

      if (pStructDecl->declarators == NULL)
      {
        TypeSpec *pTS;

        CT_DEBUG(MAIN, ("Current StructDecl is an unnamed %s",
                 isUnion ? "union" : "struct"));

        pTS = &pStructDecl->type;
        FOLLOW_AND_CHECK_TSPTR(pTS);

        if (isUnion)
        {
          GMSRV rval;

          if (tmpSV == NULL)
            tmpSV = newSVsv(sv);
          else
            sv_setsv(tmpSV, sv);

          rval = get_member_string_rec(aTHX_ (Struct *) pTS->ptr, offset,
                                       realoffset, tmpSV, pInfo);

          GMS_HANDLE_BEST_MEMBER;
        }
        else /* not isUnion */
        {
          return get_member_string_rec(aTHX_ (Struct *) pTS->ptr,
                                       offset - pStructDecl->offset,
                                       realoffset, sv, pInfo);
        }
      }
      else
      {
        ListIterator di;

        LL_foreach(pDecl, di, pStructDecl->declarators)
        {
          CT_DEBUG(MAIN, ("Current Declarator [%s]: offset=%d size=%d",
                          pDecl->identifier, pDecl->offset, pDecl->size));

          if (pDecl->offset > offset)
            GMS_HANDLE_PAD_REGION;

          if (pDecl->offset <= offset && offset < pDecl->offset+pDecl->size)
          {
            CT_DEBUG(MAIN, ("Member possibly within current Declarator [%s] "
                     "( %d <= %d < %d )", pDecl->identifier,
                     pDecl->offset, offset, pDecl->offset+pDecl->size));

            if (isUnion)
            {
              GMSRV rval;

              if (tmpSV == NULL)
                tmpSV = newSVsv(sv);
              else
                sv_setsv(tmpSV, sv);

              rval = append_member_string_rec(aTHX_ &pStructDecl->type, pDecl,
                                              offset, tmpSV, pInfo);

              GMS_HANDLE_BEST_MEMBER;
            }
            else /* not isUnion */
            {
              return append_member_string_rec(aTHX_ &pStructDecl->type, pDecl,
                                              offset, sv, pInfo);
            }
          }
        }
      }
    }
  }

  CT_DEBUG(MAIN, ("End of %s reached", isUnion ? "union" : "struct"));

  if (!isUnion || bestSV == NULL)
    GMS_HANDLE_PAD_REGION;

handle_union_end:

  if (!isUnion)
    fatal("not a union!");

  if (bestSV == NULL)
    fatal("bestSV not set!");

  sv_setsv(sv, bestSV);

  SvREFCNT_dec(bestSV);

  if (tmpSV)
    SvREFCNT_dec(tmpSV);

  return best;
}

/*******************************************************************************
*
*   ROUTINE: search_struct_member
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2003
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

static int search_struct_member(Struct *pStruct, const char *elem,
                                StructDeclaration **ppSD, Declarator **ppD)
{
  ListIterator       sdi;
  StructDeclaration *pStructDecl;
  Declarator        *pDecl = NULL;
  int                offset;

  LL_foreach(pStructDecl, sdi, pStruct->declarations)
  {
    if (pStructDecl->declarators)
    {
      ListIterator di;

      LL_foreach(pDecl, di, pStructDecl->declarators)
      {
        if (strEQ(pDecl->identifier, elem))
          break;
      }

      if (pDecl)
      {
        offset = pDecl->offset;
        break;
      }
    }
    else
    {
      TypeSpec *pTS = &pStructDecl->type;

      FOLLOW_AND_CHECK_TSPTR(pTS);

      offset  = pStructDecl->offset;
      offset += search_struct_member((Struct *) pTS->ptr, elem, &pStructDecl, &pDecl);

      if (pDecl)
        break;
    }
  }

  *ppSD = pStructDecl;
  *ppD  = pDecl;

  if (pDecl)
    return offset < 0 ? 0 : offset;

  return -1;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_all_member_strings
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

int get_all_member_strings(pTHX_ MemberInfo *pMI, LinkedList list)
{
  AMSInfo info;

  if (list)
    info.list = list;
  else
    info.count = 0;

  get_ams_type(aTHX_ &pMI->type, pMI->pDecl, pMI->level,
               list ? sv_2mortal(newSVpvn("", 0)) : NULL, 0, &info);

  return list ? LL_count(list) : info.count;
}

/*******************************************************************************
*
*   ROUTINE: get_member_string
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

SV *get_member_string(pTHX_ const MemberInfo *pMI, int offset, GMSInfo *pInfo)
{
  GMSRV rval;
  SV *sv;
  int dim;

  CT_DEBUG(MAIN, ("get_member_string( off=%d )", offset));

  if (pInfo)
    pInfo->htpad = HT_new(4);

  sv = newSVpvn("", 0);

  /* handle array remainder here */
  if (pMI->pDecl && pMI->pDecl->array_flag &&
      pMI->level < (dim = LL_count(pMI->pDecl->ext.array)))
  {
    int i, index, size = pMI->size;

    for (i = pMI->level; i < dim; i++)
    {
      size /= ((Value *) LL_get(pMI->pDecl->ext.array, i))->iv;
      index = offset / size;
      sv_catpvf(sv, "[%d]", index);
      offset -= index*size;
    }
  }

  rval = append_member_string_rec(aTHX_ &pMI->type, NULL, offset, sv, pInfo);

  if (pInfo)
    HT_destroy(pInfo->htpad, NULL);

  if (rval == GMS_NONE)
  {
    SvREFCNT_dec(sv);
    sv = newSV(0);
  }

  return sv_2mortal(sv);
}

/*******************************************************************************
*
*   ROUTINE: get_member
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

#define TRUNC_NAME                                                             \
        STMT_START {                                                           \
          strncpy(trunc, name, 20);                                            \
          if (strlen(name) > 20)                                               \
          {                                                                    \
            trunc[17] = trunc[18] = trunc[19] = '.';                           \
            trunc[20] = '\0';                                                  \
          }                                                                    \
        } STMT_END

#define PROPAGATE_FLAGS(from)                                                  \
        STMT_START {                                                           \
          if (pMIout)                                                          \
            pMIout->flags |= (from) & (T_HASBITFIELD | T_UNSAFE_VAL);          \
        } STMT_END

#define CANNOT_ACCESS_MEMBER(type)                                             \
        STMT_START {                                                           \
          assert(name != NULL);                                                \
          TRUNC_NAME;                                                          \
          (void) sprintf(err = errbuf,                                         \
                         "Cannot access member '%s' of " type " type", trunc); \
          goto error;                                                          \
        } STMT_END

int get_member(pTHX_ const MemberInfo *pMI, const char *member,
               MemberInfo *pMIout, unsigned gm_flags)
{
  unsigned           accept_dotless_member = gm_flags & CBC_GM_ACCEPT_DOTLESS_MEMBER;
  const unsigned     do_calc = (gm_flags & CBC_GM_NO_OFFSET_SIZE_CALC) == 0;
  const unsigned     reject_oobi = gm_flags & CBC_GM_REJECT_OUT_OF_BOUNDS_INDEX;
  const unsigned     reject_offset = gm_flags & CBC_GM_REJECT_OFFSET;
  const TypeSpec    *pType;
  int                size, level, t_off;
  int                offset;
  Struct            *pStruct;
  StructDeclaration *pSD;
  Declarator        *pDecl;
  char              *err, errbuf[128], trunc[32];
  MemberExprWalker   walker;
  const char        *name;

  CT_DEBUG(MAIN, ("get_member( member=\"%s\", accept_dotless_member=%d, do_calc=%d, reject_oobi=%d )",
                  member, accept_dotless_member, do_calc, reject_oobi));

  walker = member_expr_walker_new(aTHX_ member, 0);

  if (pMIout)
    pMIout->flags = 0;

  pStruct = NULL;
  pType = &pMI->type;
  pDecl = pMI->pDecl;

  if (pDecl == NULL && pType->tflags & T_TYPE)
  {
    Typedef *pTypedef = (Typedef *) pType->ptr;
    pDecl = pTypedef->pDecl;
    pType = pTypedef->pType;
  }

  name   = NULL;
  err    = NULL;
  offset = 0;
  level  = pMI->level;
  size   = do_calc ? -1 : 0;

  if (do_calc && pDecl)
  {
    int i;

    size = pDecl->size;

    if (level > 0)
    {
      assert(pDecl->array_flag);

      if (size < 0)
        fatal("pDecl->size is not initialized in get_member()");

      for (i = 0; i < level; i++)
        size /= ((Value *) LL_get(pDecl->ext.array, i))->iv;
    }
  }

  for (;;)
  {
    struct me_walk_info mei;

    member_expr_walker_walk(aTHX_ walker, &mei);

    CT_DEBUG(MAIN, ("(offset=%d, level=%d, size=%d) %s (%d)", offset, level, size,
                     member_expr_walker_retval_string(mei.retval), (int) mei.retval));

    if (mei.retval == MERV_END)
    {
      break;
    }

    switch (mei.retval)
    {
      case MERV_ERR_INVALID_MEMBER_START:
        err = "Struct members must start with a character or an underscore";
        goto error;

      case MERV_ERR_INVALID_INDEX:
        err = "Array indices must be constant decimal values";
        goto error;

      case MERV_ERR_INVALID_CHAR:
        (void) sprintf(err = errbuf,
                       "Invalid character '%c' (0x%02X) in "
                       "compound member expression",
                       mei.u.invalid_char, (int) mei.u.invalid_char);
        goto error;

      case MERV_ERR_INDEX_NOT_TERMINATED:
        err = "Index operator not terminated correctly";
        goto error;

      case MERV_ERR_INCOMPLETE:
        err = "Incomplete compound member expression";
        goto error;

      case MERV_ERR_TERMINATED:
        fatal("member expression already terminated in get_member()");
        break;

      default:
        /* handled in next switch */
        break;
    }

    PROPAGATE_FLAGS(pType->tflags);

    if (pDecl && !pDecl->pointer_flag && pType->tflags & T_TYPE &&
        level == (pDecl->array_flag ? LL_count(pDecl->ext.array) : 0))
    {
      do
      {
        Typedef *pTypedef = (Typedef *) pType->ptr;
        pDecl = pTypedef->pDecl;
        pType = pTypedef->pType;
      }
      while (!pDecl->pointer_flag &&
             pType->tflags & T_TYPE &&
             pDecl->array_flag == 0);

      if (do_calc)
      {
        size = pDecl->size;
      }

      level = 0;
    }

    switch (mei.retval)
    {
      case MERV_COMPOUND_MEMBER:
        {
          name = mei.u.compound_member.name;

          CT_DEBUG(MAIN, ("MEMBER: \"%s\"%s", name, mei.u.compound_member.has_dot ? " [dot]" : ""));

          if (!accept_dotless_member && !mei.u.compound_member.has_dot)
          {
            (void) sprintf(err = errbuf,
                           "Invalid character '%c' (0x%02X) in "
                           "compound member expression",
                           name[0], (int) name[0]);
            goto error;
          }

          if (pDecl && pDecl->array_flag && level < LL_count(pDecl->ext.array))
            CANNOT_ACCESS_MEMBER("array");
          else if (pDecl && pDecl->pointer_flag)
            CANNOT_ACCESS_MEMBER("pointer");
          else if (pType->tflags & T_COMPOUND)
          {
            pStruct = (Struct *) pType->ptr;
            PROPAGATE_FLAGS(pStruct->tflags);
          }
          else
            CANNOT_ACCESS_MEMBER("non-compound");

          t_off = search_struct_member(pStruct, name, &pSD, &pDecl);
          pType = &pSD->type;

          if (t_off < 0)
          {
            TRUNC_NAME;
            (void) sprintf(err = errbuf, "Cannot find %s member '%s'",
                           pStruct->tflags & T_STRUCT ? "struct" : "union", trunc);
            goto error;
          }

          if (do_calc)
          {
            size    = pDecl->size;
            offset += t_off;
          }

          level = 0;
        }
        break;

      case MERV_ARRAY_INDEX:
        {
          int dim;

          if (pDecl == NULL || (level == 0 && pDecl->array_flag == 0))
          {
            if (name)
            {
              TRUNC_NAME;
              (void) sprintf(err = errbuf,
                             "Cannot use '%s' as an array", trunc);
            }
            else
              err = "Cannot use type as an array";

            goto error;
          }

          assert(pDecl->array_flag);

          dim = LL_count(pDecl->ext.array);

          if (level >= dim)
          {
            if (name)
            {
              TRUNC_NAME;
              (void) sprintf(err = errbuf,
                             "Cannot use '%s' as a %d-dimensional array",
                             trunc, level+1);
            }
            else
            {
              (void) sprintf(err = errbuf,
                             "Cannot use type as a %d-dimensional array",
                             level+1);
            }
            goto error;
          }
          else
          {
            Value *pValue;
            int index;

            pValue = (Value *) LL_get(pDecl->ext.array, level);
            index  = mei.u.array_index;

            CT_DEBUG(MAIN, ("INDEX: %d", index));

            if (pValue->flags & V_IS_UNDEF)
            {
              if (do_calc)
              {
                size = pDecl->item_size;

                if (size <= 0)
                  fatal("pDecl->item_size is not initialized in get_member()");

                while (dim-- > level+1)
                  size *= ((Value *) LL_get(pDecl->ext.array, dim))->iv;
              }
            }
            else
            {
              dim = pValue->iv;

              if (reject_oobi)
              {
                if (index < 0)
                {
                  (void) sprintf(err = errbuf,
                                 "Cannot use negative index %d into array",
                                 index);
                  goto error;
                }
                else if (index >= dim)
                {
                  (void) sprintf(err = errbuf,
                                 "Cannot use index %d into array of size %d",
                                 index, dim);
                  goto error;
                }
              }

              if (do_calc)
              {
                if (size < 0)
                  fatal("size is not initialized in get_member()");

                size /= dim;
              }
            }

            if (do_calc)
            {
              if (size < 0)
                fatal("size is not initialized in get_member()");

              offset += index * size;
            }

            level++;
          }
        }
        break;

      case MERV_OFFSET:
        if (reject_offset)
        {
          err = "Cannot use offset in compound member expression";
          goto error;
        }
        if (do_calc)
        {
          offset += mei.u.offset;
        }
        break;

      default:
        /* all error cases have been handled above */
        fatal("unexpected retval (%d) in get_member()", (int) mei.retval);
        break;
    }

    /* only accept dotless members at the very beginning */
    accept_dotless_member = 0;
  }

  error:
  member_expr_walker_delete(aTHX_ walker);

  if (err != NULL)
  {
    if (gm_flags & CBC_GM_DONT_CROAK)
      return 0;
    Perl_croak(aTHX_ "%s", err);
  }

  CT_DEBUG(MAIN, ("FINISHED: typespec=[ptr=%p, flags=0x%lX], pDecl=%p[dim=%d], level=%d, offset=%d, size=%d, parent=%p",
                  pType->ptr, (unsigned long) pType->tflags, pDecl,
                  pDecl && pDecl->array_flag ? LL_count(pDecl->ext.array) : 0,
                  level, offset, size, pStruct));

  if (pMIout)
  {
    pMIout->type   = *pType;
    pMIout->parent = pStruct;
    pMIout->pDecl  = pDecl;
    pMIout->level  = level;
    pMIout->offset = offset;
    pMIout->size   = (unsigned) size;
  }

  return 1;
}

#undef TRUNC_NAME
#undef PROPAGATE_FLAGS
#undef CANNOT_ACCESS_MEMBER

/*******************************************************************************
*
*   ROUTINE: member_expr_walker_new
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

MemberExprWalker member_expr_walker_new(pTHX_ const char *expr, size_t len)
{
  MemberExprWalker me;

  assert(expr != NULL);

  if (len == 0)
    len = strlen(expr);

  Newc(0, me, offsetof(struct member_expr, buf) + len + 1, char, struct member_expr);

  me->state = ST_SEARCH;
  me->p = expr;
  me->startup = 1;
  me->has_dot = 0;

  CT_DEBUG(MAIN, ("(walk) created new walker @ %p", me));

  return me;
}

/*******************************************************************************
*
*   ROUTINE: member_expr_walker_retval_string
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

const char *member_expr_walker_retval_string(enum me_walk_rv retval)
{
  static const char *Sretval[] = {
    "MERV_COMPOUND_MEMBER",
    "MERV_ARRAY_INDEX",
    "MERV_OFFSET",
    "MERV_ERR_INVALID_MEMBER_START",
    "MERV_ERR_INVALID_INDEX",
    "MERV_ERR_INVALID_CHAR",
    "MERV_ERR_INDEX_NOT_TERMINATED",
    "MERV_ERR_INCOMPLETE",
    "MERV_ERR_TERMINATED",
    "MERV_END"
  };

  return Sretval[retval];
}

/*******************************************************************************
*
*   ROUTINE: member_expr_walker_walk
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

void member_expr_walker_walk(pTHX_ MemberExprWalker me, struct me_walk_info *info)
{
#ifdef CBC_DEBUGGING
  static const char *Sstate[] = {
    "ST_MEMBER",
    "ST_INDEX",
    "ST_FINISH_INDEX",
    "ST_SEARCH",
    "ST_TERM"
  };
#endif
  const char *c, *ixstr;

  assert(me != NULL);

  if (me->state == ST_TERM)
  {
    info->retval = MERV_ERR_TERMINATED;
    return;
  }

  c = me->p;

  for (;;)
  {
    CT_DEBUG(MAIN, ("(walk) state = %s (%d) \"%s\"%s%s", Sstate[me->state], me->state, c,
                    me->startup ? " [startup]" : "", me->has_dot ? " [dot]" : ""));

    while (isSPACE(*c))
      c++;

    if (*c == '\0')
    {
      if (me->state != ST_SEARCH)
      {
        info->retval = MERV_ERR_INCOMPLETE;
        goto error;
      }

      info->retval = MERV_END;
      me->state = ST_TERM;

      return;
    }

    switch (me->state)
    {
      case ST_MEMBER:
        if(!(isALPHA(*c) || *c == '_'))
        {
          info->retval = MERV_ERR_INVALID_MEMBER_START;
          goto error;
        }
        else
        {
          char *e = &me->buf[0];
          do *e++ = *c++; while (isALNUM(*c) || *c == '_');
          *e = '\0';

          info->retval = MERV_COMPOUND_MEMBER;
          info->u.compound_member.name = &me->buf[0];
          info->u.compound_member.name_length = e - &me->buf[0];
          info->u.compound_member.has_dot = me->has_dot;

          goto found;
        }

      case ST_INDEX:
        ixstr = c;

        if (*c == '-' || *c == '+')
        {
          c++;
        }

        if (!isDIGIT(*c))
        {
          info->retval = MERV_ERR_INVALID_INDEX;
          goto error;
        }

        do c++; while (isDIGIT(*c));

        me->state = ST_FINISH_INDEX;
        break;

      case ST_FINISH_INDEX:
        if (*c++ != ']')
        {
          info->retval = MERV_ERR_INDEX_NOT_TERMINATED;
          goto error;
        }

        info->retval = MERV_ARRAY_INDEX;
        info->u.array_index = atoi(ixstr);

        goto found;

      case ST_SEARCH:
        {
          int inc_c = 1;

          switch (*c)
          {
            case '+':
              if (*(c+1) != '\0')
              {
                const char *p = c+1;

                while (isDIGIT(*p)) p++;
                while (isSPACE(*p)) p++;

                /* only allowed at end of string */
                if (*p == '\0')
                {
                  info->retval = MERV_OFFSET;
                  info->u.offset = atoi(c+1);

                  c = p;

                  goto found;
                }
              }

              /* fall through */

            default:
              if (!me->startup || !(isALPHA(*c) || *c == '_'))
              {
                info->retval = MERV_ERR_INVALID_CHAR;
                info->u.invalid_char = *c;
                goto error;
              }

              inc_c = 0;

              /* fall through */

            case '.':
              me->has_dot = *c == '.';
              me->state = ST_MEMBER;
              break;

            case '[':
              me->state = ST_INDEX;
              break;
          }

          if (inc_c)
            c++;
        }
        break;

      default:
        fatal("invalid state (%d) in member_expr_walker_walk()", (int) me->state);
        break;
    }

    /* only accept dotless members at the very beginning */
    me->startup = 0;
  }

  error:

  /* no need to update me->p here */
  me->state = ST_TERM;

  return;

  found:

  me->p = c;
  me->state = ST_SEARCH;
}

/*******************************************************************************
*
*   ROUTINE: member_expr_walker_delete
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

void member_expr_walker_delete(pTHX_ MemberExprWalker me)
{
  assert(me != NULL);

  CT_DEBUG(MAIN, ("(walk) delete walker @ %p", me));

  Safefree(me);
}

