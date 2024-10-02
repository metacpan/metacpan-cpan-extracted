/*******************************************************************************
*
* MODULE: hook.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C hooks
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

#include "cbc/cbc.h"
#include "cbc/hook.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void single_hook_deref(pTHX_ const SingleHook *hook);
static void single_hook_ref(pTHX_ const SingleHook *hook);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

#include "token/t_hookid.c"

/*******************************************************************************
*
*   ROUTINE: single_hook_deref
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

static void single_hook_deref(pTHX_ const SingleHook *hook)
{
  assert(hook != NULL);

  if (hook->sub)
    SvREFCNT_dec(hook->sub);

  if (hook->arg)
    SvREFCNT_dec(hook->arg);
}

/*******************************************************************************
*
*   ROUTINE: single_hook_ref
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

static void single_hook_ref(pTHX_ const SingleHook *hook)
{
  assert(hook != NULL);

  if (hook->sub)
    SvREFCNT_inc(hook->sub);

  if (hook->arg)
    SvREFCNT_inc(hook->arg);
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: single_hook_fill
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2004
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

void single_hook_fill(pTHX_ const char *hook, const char *type, SingleHook *sth,
                            SV *sub, U32 allowed_args)
{
  if (!DEFINED(sub))
  {
    sth->sub = NULL;
    sth->arg = NULL;
  }
  else if (SvROK(sub))
  {
    SV *sv = SvRV(sub);

    switch (SvTYPE(sv))
    {
      case SVt_PVCV:
        sth->sub = sv;
        sth->arg = NULL;
        break;

      case SVt_PVAV:
        {
          AV *in = (AV *) sv;
          I32 len = av_len(in);

          if (len < 0)
            Perl_croak(aTHX_ "Need at least a code reference in %s hook for "
                             "type '%s'", hook, type);
          else
          {
            SV **pSV = av_fetch(in, 0, 0);

            if (pSV == NULL || !SvROK(*pSV) ||
                SvTYPE(sv = SvRV(*pSV)) != SVt_PVCV)
              Perl_croak(aTHX_ "%s hook defined for '%s' is not "
                               "a code reference", hook, type);
            else
            {
              I32 ix;
              AV *out;

              for (ix = 0; ix < len; ++ix)
              {
                pSV = av_fetch(in, ix+1, 0);
                
                if (pSV == NULL)
                  fatal("NULL returned by av_fetch() in single_hook_fill()");

                if (SvROK(*pSV) && sv_isa(*pSV, ARGTYPE_PACKAGE))
                {
                  HookArgType argtype = (HookArgType) SvIV(SvRV(*pSV));

#define CHECK_ARG_TYPE(type)                                   \
          case HOOK_ARG_ ## type:                              \
            if ((allowed_args & SHF_ALLOW_ARG_ ## type) == 0)  \
              Perl_croak(aTHX_ #type " argument not allowed"); \
            break

                  switch (argtype)
                  {
                    CHECK_ARG_TYPE(SELF);
                    CHECK_ARG_TYPE(TYPE);
                    CHECK_ARG_TYPE(DATA);
                    CHECK_ARG_TYPE(HOOK);
                  }

#undef CHECK_ARG_TYPE
                }
              }

              sth->sub = sv;

              out = newAV();
              av_extend(out, len-1);

              for (ix = 0; ix < len; ++ix)
              {
                pSV = av_fetch(in, ix+1, 0);

                if (pSV == NULL)
                  fatal("NULL returned by av_fetch() in single_hook_fill()");

                SvREFCNT_inc(*pSV);

                if (av_store(out, ix, *pSV) == NULL)
                  SvREFCNT_dec(*pSV);
              }

              sth->arg = (AV *) sv_2mortal((SV *) out);
            }
          }
        }
        break;

      default:
        goto not_code_or_array_ref;
    }
  }
  else
  {
not_code_or_array_ref:
    Perl_croak(aTHX_ "%s hook defined for '%s' is not "
                     "a code or array reference", hook, type);
  }
}

/*******************************************************************************
*
*   ROUTINE: single_hook_new
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

SingleHook *single_hook_new(const SingleHook *src)
{
  dTHX;
  SingleHook *dst;

  assert(src != NULL);

  New(0, dst, 1, SingleHook);

  *dst = *src;

  single_hook_ref(aTHX_ src);

  return dst;
}

/*******************************************************************************
*
*   ROUTINE: hook_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
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

TypeHooks *hook_new(const TypeHooks *h)
{
  dTHX;
  TypeHooks *r;
  SingleHook *dst;
  int i;

  New(0, r, 1, TypeHooks);

  dst = &r->hooks[0];

  if (h)
  {
    const SingleHook *src = &h->hooks[0];

    for (i = 0; i < HOOKID_COUNT; i++, src++, dst++)
    {
      *dst = *src;

      single_hook_ref(aTHX_ src);
    }
  }
  else
  {
    for (i = 0; i < HOOKID_COUNT; i++, dst++)
    {
      dst->sub = NULL;
      dst->arg = NULL;
    }
  }

  return r;
}

/*******************************************************************************
*
*   ROUTINE: single_hook_update
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

void single_hook_update(SingleHook *dst, const SingleHook *src)
{
  dTHX;

  assert(src != NULL);
  assert(dst != NULL);

  if (dst->sub != src->sub)
  {
    if (src->sub)
      SvREFCNT_inc(src->sub);
    if (dst->sub)
      SvREFCNT_dec(dst->sub);
  }

  if (dst->arg != src->arg)
  {
    if (src->arg)
      SvREFCNT_inc(src->arg);
    if (dst->arg)
      SvREFCNT_dec(dst->arg);
  }

  *dst = *src;
}

/*******************************************************************************
*
*   ROUTINE: hook_update
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
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

void hook_update(TypeHooks *dst, const TypeHooks *src)
{
  dTHX;
  const SingleHook *hook_src = &src->hooks[0];
  SingleHook *hook_dst = &dst->hooks[0];
  int i;

  assert(src != NULL);
  assert(dst != NULL);

  for (i = 0; i < HOOKID_COUNT; i++, hook_dst++, hook_src++)
    single_hook_update(hook_dst, hook_src);
}

/*******************************************************************************
*
*   ROUTINE: single_hook_delete
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

void single_hook_delete(SingleHook *hook)
{
  dTHX;

  assert(hook != NULL);

  single_hook_deref(aTHX_ hook);

  Safefree(hook);
}

/*******************************************************************************
*
*   ROUTINE: hook_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
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

void hook_delete(TypeHooks *h)
{
  if (h)
  {
    dTHX;
    SingleHook *hook = &h->hooks[0];
    int i;

    for (i = 0; i < HOOKID_COUNT; i++, hook++)
      single_hook_deref(aTHX_ hook);

    Safefree(h);
  }
}

/*******************************************************************************
*
*   ROUTINE: single_hook_call
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

/* TODO: The hook_call interface is a little ugly, mainly because we cannot
 *       directly influence the arguments. This should probably be refactored.
 */

SV *single_hook_call(pTHX_ SV *self, const char *hook_id_str, const char *id_pre,
                     const char *id, const SingleHook *hook, SV *in, int mortal)
{
  dSP;
  int count;
  SV *out;

  CT_DEBUG(MAIN, ("single_hook_call(hid='%s', id='%s%s', hook=%p, in=%p(%d), mortal=%d)",
                  hook_id_str, id_pre, id, hook, in, in ? (int) SvREFCNT(in) : 0, mortal));

  assert(self != NULL);
  assert(hook != NULL);

  if (hook->sub == NULL)
    return in;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  if (hook->arg)
  {
    I32 ix, len;
    len = av_len(hook->arg);

    for (ix = 0; ix <= len; ++ix)
    {
      SV **pSV = av_fetch(hook->arg, ix, 0);
      SV *sv;

      if (pSV == NULL)
        fatal("NULL returned by av_fetch() in single_hook_call()");

      if (SvROK(*pSV) && sv_isa(*pSV, ARGTYPE_PACKAGE))
      {
        HookArgType type = (HookArgType) SvIV(SvRV(*pSV));

        switch (type)
        {
          case HOOK_ARG_SELF:
            sv = sv_mortalcopy(self);
            break;

          case HOOK_ARG_DATA:
            assert(in != NULL);
            sv = sv_mortalcopy(in);
            break;

          case HOOK_ARG_TYPE:
            assert(id != NULL);
            sv = sv_newmortal();
            if (id_pre)
            {
              sv_setpv(sv, id_pre);
              sv_catpv(sv, CONST_CHAR(id));
            }
            else
              sv_setpv(sv, id);
            break;

          case HOOK_ARG_HOOK:
            if (hook_id_str)
            {
              sv = sv_newmortal();
              sv_setpv(sv, hook_id_str);
            }
            else
            {
              sv = &PL_sv_undef;
            }
            break;

          default:
            fatal("Invalid hook argument type (%d) in single_hook_call()", type);
            break;
        }
      }
      else
        sv = sv_mortalcopy(*pSV);

      XPUSHs(sv);
    }
  }
  else
  {
    if (in)
    {
      /* only push the data argument */
      XPUSHs(in);
    }
  }

  PUTBACK;

  count = call_sv(hook->sub, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    fatal("Hook returned %d elements instead of 1", count);

  out = POPs;

  CT_DEBUG(MAIN, ("single_hook_call: in=%p(%d), out=%p(%d)",
                  in, in ? (int) SvREFCNT(in) : 0, out, (int) SvREFCNT(out)));

  if (!mortal && in != NULL)
    SvREFCNT_dec(in);
  SvREFCNT_inc(out);

  PUTBACK;
  FREETMPS;
  LEAVE;

  if (mortal)
    sv_2mortal(out);

  CT_DEBUG(MAIN, ("single_hook_call: out=%p(%d)", out, (int) SvREFCNT(out)));

  return out;
}

/*******************************************************************************
*
*   ROUTINE: hook_call
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
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

SV *hook_call(pTHX_ SV *self, const char *id_pre, const char *id,
              const TypeHooks *pTH, enum HookId hook_id, SV *in, int mortal)
{
  CT_DEBUG(MAIN, ("hook_call(id='%s%s', pTH=%p, in=%p(%d), mortal=%d)",
                  id_pre, id, pTH, in, (int) SvREFCNT(in), mortal));

  assert(self != NULL);
  assert(pTH  != NULL);
  assert(id   != NULL);
  assert(in   != NULL);

  return single_hook_call(aTHX_ self, gs_HookIdStr[hook_id], id_pre, id,
                          &pTH->hooks[hook_id], in, mortal);
}

/*******************************************************************************
*
*   ROUTINE: find_hooks
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

int find_hooks(pTHX_ const char *type, HV *hooks, TypeHooks *pTH)
{
  HE *h;
  int i, num;

  assert(type != NULL);
  assert(hooks != NULL);
  assert(pTH != NULL);

  (void) hv_iterinit(hooks);

  while ((h = hv_iternext(hooks)) != NULL)
  {
    const char *key;
    I32 keylen;
    SV *sub;
    enum HookId id;

    key = hv_iterkey(h, &keylen);
    sub = hv_iterval(hooks, h);

    id = get_hook_id(key);

    if (id >= HOOKID_COUNT)
    {
      if (id == HOOKID_INVALID)
        Perl_croak(aTHX_ "Invalid hook type '%s'", key);
      else
        fatal("Invalid hook id %d for hook '%s'", id, key);
    }

    single_hook_fill(aTHX_ key, type, &pTH->hooks[id], sub, SHF_ALLOW_ARG_SELF |
                                                            SHF_ALLOW_ARG_TYPE |
                                                            SHF_ALLOW_ARG_DATA |
                                                            SHF_ALLOW_ARG_HOOK);
  }

  for (i = num = 0; i < HOOKID_COUNT; i++)
    if (pTH->hooks[i].sub)
      num++;

  return num;
}

/*******************************************************************************
*
*   ROUTINE: get_single_hook
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

SV *get_single_hook(pTHX_ const SingleHook *hook)
{
  SV *sv;

  assert(hook != NULL);

  sv = hook->sub;

  if (sv == NULL)
    return NULL;

  sv = newRV_inc(sv);

  if (hook->arg)
  {
    AV *av = newAV();
    int j, len = 1 + av_len(hook->arg);

    av_extend(av, len);
    if (av_store(av, 0, sv) == NULL)
      fatal("av_store() failed in get_hooks()");

    for (j = 0; j < len; j++)
    {
      SV **pSV = av_fetch(hook->arg, j, 0);

      if (pSV == NULL)
        fatal("NULL returned by av_fetch() in get_hooks()");

      SvREFCNT_inc(*pSV);

      if (av_store(av, j+1, *pSV) == NULL)
        fatal("av_store() failed in get_hooks()");
    }

    sv = newRV_noinc((SV *) av);
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: get_hooks
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

HV *get_hooks(pTHX_ const TypeHooks *pTH)
{
  int i;
  HV *hv = newHV();

  assert(pTH != NULL);

  for (i = 0; i < HOOKID_COUNT; i++)
  {
    SV *sv = get_single_hook(aTHX_ &pTH->hooks[i]);
    const char *id;

    if (sv == NULL)
      continue;

    id = gs_HookIdStr[i];

    if (hv_store(hv, id, strlen(id), sv, 0) == 0)
      fatal("hv_store() failed in get_hooks()");
  }

  return hv;
}

