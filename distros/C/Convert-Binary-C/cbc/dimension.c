/*******************************************************************************
*
* MODULE: dimension.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C dimension tag
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

#define NO_XSLOCKS
#include <XSUB.h>

#include "ppport.h"


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/cbc.h"
#include "cbc/hook.h"
#include "cbc/util.h"
#include "cbc/dimension.h"
#include "cbc/type.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void dimtag_init(pTHX_ DimensionTag *dim);
static void dimtag_fini(pTHX_ DimensionTag *dim);
static void validate_member_expression(pTHX_ const MemberInfo *pmi,
                                             const char *member, const char *type);
static long sv_to_dimension(pTHX_ SV *sv, const char *member);
static long dimension_from_member(pTHX_ const char *member, HV *parent);
static long dimension_from_hook(pTHX_ SingleHook *hook, SV *self, HV *parent);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: dimtag_init
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

static void dimtag_init(pTHX_ DimensionTag *dim)
{
  assert(dim != NULL);

  switch (dim->type)
  {
    case DTT_MEMBER:
      {
        STRLEN len;
        const char *src = dim->u.member;

        assert(src != NULL);

        len = strlen(src);
        New(0, dim->u.member, len+1, char);
        strcpy(dim->u.member, src);
      }
      break;

    case DTT_HOOK:
      assert(dim->u.hook != NULL);
      dim->u.hook = single_hook_new(dim->u.hook);
      break;

    default:
      /* nothing to do */
      break;
  }
}

/*******************************************************************************
*
*   ROUTINE: dimtag_fini
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

static void dimtag_fini(pTHX_ DimensionTag *dim)
{
  assert(dim != NULL);

  switch (dim->type)
  {
    case DTT_MEMBER:
      assert(dim->u.member != NULL);
      Safefree(dim->u.member);
      break;

    case DTT_HOOK:
      assert(dim->u.hook != NULL);
      single_hook_delete(dim->u.hook);
      break;

    default:
      break;
  }
}

/*******************************************************************************
*
*   ROUTINE: validate_member_expression
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

static void validate_member_expression(pTHX_ const MemberInfo *pmi,
                                             const char *member, const char *type)
{
  MemberInfo mi, mi2;
  const char *failed_type;

  assert(pmi != NULL);
  assert(member != NULL);

  if (pmi->parent == NULL)
  {
    Perl_croak(aTHX_ "Cannot use member expression '%s' as Dimension tag"
                     " for '%s' when not within a compound type", member, type);
  }

  mi.type.ptr = pmi->parent;
  mi.type.tflags = ((Struct *) pmi->parent)->tflags;
  mi.pDecl = NULL;
  mi.level = 0;

  (void) get_member(aTHX_ &mi, member, &mi2, CBC_GM_ACCEPT_DOTLESS_MEMBER |
                                             CBC_GM_REJECT_OUT_OF_BOUNDS_INDEX |
                                             CBC_GM_REJECT_OFFSET);

  failed_type = check_allowed_types_string(&mi2, ALLOW_BASIC_TYPES);

  if (failed_type)
  {
    Perl_croak(aTHX_ "Cannot use %s in member '%s' to determine a dimension for '%s'",
                     failed_type, member, type);
  }

  if (mi2.offset + (int)mi2.size > pmi->offset)
  {
    const char *where;

    if (mi2.offset == pmi->offset)
      where = "located at same offset as"; 
    else if (mi2.offset < pmi->offset)
      where = "overlapping with";
    else
      where = "located behind";

    Perl_croak(aTHX_ "Cannot use member '%s' %s '%s' in layout"
                     " to determine a dimension", member, where, type);
  }
}

/*******************************************************************************
*
*   ROUTINE: sv_to_dimension
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

static long sv_to_dimension(pTHX_ SV *sv, const char *member)
{
  SV *warning;
  const char *value = NULL;

  assert(sv != NULL);

  SvGETMAGIC(sv);

  if (SvOK(sv) && !SvROK(sv))
  {
    if (looks_like_number(sv))
    {
      return SvIV(sv);
    }

    value = SvPV_nolen(sv);
  }

  warning = newSVpvn("", 0);
  if (value)  sv_catpvf(warning, " ('%s')", value);
  if (member) sv_catpvf(warning, " in '%s'", member);

  WARN((aTHX_ "Cannot use %s%s as dimension", identify_sv(sv), SvPV_nolen(warning)));

  SvREFCNT_dec(warning);

  return 0;
}

/*******************************************************************************
*
*   ROUTINE: dimension_from_member
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

static long dimension_from_member(pTHX_ const char *member, HV *parent)
{
  MemberExprWalker walker;
  int success = 1;
  SV *sv = NULL;
  dTHR;
  dXCPT;

  assert(member != NULL);

  if (parent == NULL)
  {
    WARN((aTHX_ "Missing parent to look up '%s'", member));
    return 0;
  }

  CT_DEBUG(MAIN, ("trying to get dimension from member, walking \"%s\"", member));

  walker = member_expr_walker_new(aTHX_ member, 0);

  XCPT_TRY_START
  {
    for (;;)
    {
      struct me_walk_info mei;

      member_expr_walker_walk(aTHX_ walker, &mei);

      if (mei.retval == MERV_END)
      {
        break;

lookup_failed:
        success = 0;
        break;
      }

      switch (mei.retval)
      {
        case MERV_COMPOUND_MEMBER:
          {
            const char *name = mei.u.compound_member.name;
            HV *hv = parent;
            SV **psv;

            CT_DEBUG(MAIN, ("found compound member \"%s\"", name));

            if (sv)
            {
              SV *hash;

              if (SvROK(sv) && SvTYPE(hash = SvRV(sv)) == SVt_PVHV)
              {
                hv = (HV *) hash;
              }
              else
              {
                WARN((aTHX_ "Expected a hash reference to look up member '%s'"
                            " in '%s', not %s", name, member, identify_sv(sv)));
                goto lookup_failed;
              }
            }

            psv = hv_fetch(hv, name, mei.u.compound_member.name_length, 0);

            if (psv)
            {
              SvGETMAGIC(*psv);
              sv = *psv;
            }
            else
            {
              WARN((aTHX_ "Cannot find member '%s' in hash (in '%s')", name, member));
              goto lookup_failed;
            }
          }
          break;

        case MERV_ARRAY_INDEX:
          {
            long last, index = mei.u.array_index;
            AV *av;
            SV *array;
            SV **psv;

            assert(sv != NULL);

            CT_DEBUG(MAIN, ("found array index \"%ld\"", index));

            if (SvROK(sv) && SvTYPE(array = SvRV(sv)) == SVt_PVAV)
            {
              av = (AV *) array;
            }
            else
            {
              WARN((aTHX_ "Expected an array reference to look up index '%ld'"
                          " in '%s', not %s", index, member, identify_sv(sv)));
              goto lookup_failed;
            }

            last = (long) av_len(av);

            if (index > last)
            {
              WARN((aTHX_ "Cannot lookup index '%ld' in array of size"
                          " '%ld' (in '%s')", index, last + 1, member));
              goto lookup_failed;
            }

            psv = av_fetch(av, index, 0);

            if (psv == NULL)
            {
              fatal("cannot find index '%ld' in array of size '%ld' (in '%s')",
                    index, last + 1, member);
            }

            SvGETMAGIC(*psv);
            sv = *psv;
          }
          break;

        default:
          fatal("unexpected return value (%d) in dimension_from_member('%s')",
                (int) mei.retval, member);
          break;
      }
    }
  }
  XCPT_TRY_END

  member_expr_walker_delete(aTHX_ walker);

  XCPT_CATCH
  {
    XCPT_RETHROW;
  }

  if (success)
  {
    assert(sv != NULL);

    return sv_to_dimension(aTHX_ sv, member);
  }

  return 0;
}

/*******************************************************************************
*
*   ROUTINE: dimension_from_hook
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

static long dimension_from_hook(pTHX_ SingleHook *hook, SV *self, HV *parent)
{
  dTHR;
  dXCPT;
  SV *sv, *in;
  long rv;

  assert(hook != NULL);
  assert(self != NULL);

  in = parent ? newRV_inc((SV *) parent) : NULL;
  sv = NULL;

  XCPT_TRY_START
  {
    sv = single_hook_call(aTHX_ self, "dimension", NULL, NULL, hook, in, 0);
  }
  XCPT_TRY_END

  XCPT_CATCH
  {
    if (parent)
    {
      CT_DEBUG(MAIN, ("freeing sv @ %p in dimension_from_hook:%d", in, __LINE__));
      SvREFCNT_dec(in);
    }

    XCPT_RETHROW;
  }

  assert(sv != NULL);

  rv = sv_to_dimension(aTHX_ sv, NULL);

  SvREFCNT_dec(sv);

  return rv;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: dimtag_verify
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

void dimtag_verify(pTHX_ const MemberInfo *pmi, const char *type)
{
  const char *failed_type;

  assert(pmi != NULL);
  assert(type != NULL);
  assert(pmi->level == 0);

  failed_type = check_allowed_types_string(pmi, ALLOW_ARRAYS);

  if (failed_type)
  {
    Perl_croak(aTHX_ "Cannot use Dimension tag on %s '%s'", failed_type, type);
  }
}

/*******************************************************************************
*
*   ROUTINE: dimtag_new
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

DimensionTag *dimtag_new(const DimensionTag *src)
{
  dTHX;
  DimensionTag *dst;

  New(0, dst, 1, DimensionTag);

  if (src)
  {
    *dst = *src;
    dimtag_init(aTHX_ dst);
  }
  else
  {
    dst->type = DTT_NONE;
  }

  return dst;
}

/*******************************************************************************
*
*   ROUTINE: dimtag_delete
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

void dimtag_delete(DimensionTag *dim)
{
  dTHX;

  assert(dim != NULL);

  dimtag_fini(aTHX_ dim);

  Safefree(dim);
}

/*******************************************************************************
*
*   ROUTINE: dimtag_parse
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

int dimtag_parse(pTHX_ const MemberInfo *pmi, const char *type, SV *tag, DimensionTag *dim)
{
  enum dimension_tag_type tag_type = DTT_NONE;

  assert(type != NULL);
  assert(tag != NULL);
  assert(dim != NULL);

  assert(SvOK(tag));

  if (SvROK(tag))
  {
    SV *sv = SvRV(tag);

    switch (SvTYPE(sv))
    {
      case SVt_PVCV:
      case SVt_PVAV:
        tag_type = DTT_HOOK;
        break;

      default:
        break;
    }
  }
  else
  {
    if (SvPOK(tag))
    {
      STRLEN len;
      const char *str = SvPV(tag, len);

      if (len > 0)
      {
        if (strEQ(str, "*"))
        {
          tag_type = DTT_FLEXIBLE;
        }
        else if (looks_like_number(tag))
        {
          tag_type = DTT_FIXED;
        }
        else
        {
          tag_type = DTT_MEMBER;
        }
      }
    }
    else if (SvIOK(tag))
    {
      tag_type = DTT_FIXED;
    }
  }

  switch (tag_type)
  {
    case DTT_NONE:
      Perl_croak(aTHX_ "Invalid Dimension tag for '%s'", type);
      break;

    case DTT_FLEXIBLE:
      break;

    case DTT_FIXED:
      {
        IV value = SvIV(tag);

        if (value < 0)
          Perl_croak(aTHX_ "Cannot use negative value %" IVdf " in Dimension"
                           " tag for '%s'", value, type);

        dim->u.fixed = value;
      }
      break;

    case DTT_MEMBER:
      {
        STRLEN len;
        const char *src = SvPV(tag, len);

        validate_member_expression(aTHX_ pmi, src, type);

        New(0, dim->u.member, len+1, char);
        Copy(src, dim->u.member, len, char);
        dim->u.member[len] = '\0';
      }
      break;

    case DTT_HOOK:
      {
        SingleHook newhook;
        U32 allowed = SHF_ALLOW_ARG_SELF
                    | SHF_ALLOW_ARG_HOOK;

        if (pmi->parent)
          allowed |= SHF_ALLOW_ARG_DATA;

        single_hook_fill(aTHX_ "Dimension", type, &newhook, tag, allowed);
        
        dim->u.hook = single_hook_new(&newhook);
      }
      break;
  }

  dim->type = tag_type;

  return 1;
}

/*******************************************************************************
*
*   ROUTINE: dimtag_update
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

void dimtag_update(DimensionTag *dst, const DimensionTag *src)
{
  dTHX;

  assert(dst != NULL);
  assert(src != NULL);

  dimtag_fini(aTHX_ dst);
  *dst = *src;
}

/*******************************************************************************
*
*   ROUTINE: dimtag_get
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

SV *dimtag_get(pTHX_ const DimensionTag *dim)
{
  SV *sv;

  assert(dim != NULL);

  switch (dim->type)
  {
    case DTT_FLEXIBLE:
      sv = newSVpvn("*", 1);
      break;

    case DTT_FIXED:
      sv = newSViv(dim->u.fixed);
      break;

    case DTT_MEMBER:
      sv = newSVpv(dim->u.member, 0);
      break;

    case DTT_HOOK:
      sv = get_single_hook(aTHX_ dim->u.hook);
      break;

    case DTT_NONE:
      fatal("Invalid dimension tag type in dimtag_get()");
      break;

    default:
      fatal("Unknown dimension tag type (%d) in dimtag_get()", (int) dim->type);
      break;
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: dimtag_is_flexible
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

int dimtag_is_flexible(pTHX_ const DimensionTag *dim)
{
  assert(dim != NULL);
  return dim->type == DTT_FLEXIBLE;
}
 
/*******************************************************************************
*
*   ROUTINE: dimtag_eval
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

long dimtag_eval(pTHX_ const DimensionTag *dim, long avail, SV *self, HV *parent)
{
  assert(dim != NULL);
  assert(self != NULL);

  CT_DEBUG(MAIN, ("dimtag_eval(%p(%d), %ld, %p, %p)", dim, (int)dim->type, avail, self, parent));

  switch (dim->type)
  {
    case DTT_FLEXIBLE:
      return avail;

    case DTT_FIXED:
      return (long) dim->u.fixed;

    case DTT_MEMBER:
      return dimension_from_member(aTHX_ dim->u.member, parent);

    case DTT_HOOK:
      return dimension_from_hook(aTHX_ dim->u.hook, self, parent);

    case DTT_NONE:
      fatal("Invalid dimension tag type in dimtag_get()");
      break;

    default:
      fatal("Unknown dimension tag type (%d) in dimtag_get()", (int) dim->type);
      break;
  }

  assert(0);

  return 0;
}
