/*******************************************************************************
*
* MODULE: tag.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C tags
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

#include "cbc/hook.h"
#include "cbc/dimension.h"
#include "cbc/tag.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

#define NUM_TAGIDS  (sizeof(gs_TagTbl) / sizeof(gs_TagTbl[0]) - 1)

#define TAG_INIT(name)   void name ## _Init(CtTag *tag)
#define TAG_CLONE(name)  void name ## _Clone(CtTag *dst, const CtTag *src)
#define TAG_FREE(name)   void name ## _Free(CtTag *tag)
#define TAG_SET(name)    TagSetRV name ## _Set(pTHX_ const TagTypeInfo *ptti PERL_UNUSED_DECL, \
                                                     CtTag *tag, SV *val)
#define TAG_GET(name)    SV *     name ## _Get(pTHX_ const TagTypeInfo *ptti PERL_UNUSED_DECL, \
                                                     const CtTag *tag)
#define TAG_VERIFY(name) void     name ## _Verify(pTHX_ const TagTypeInfo *ptti PERL_UNUSED_DECL, \
                                                        const CtTag *tag PERL_UNUSED_DECL, \
                                                        SV *val PERL_UNUSED_DECL)


/*===== TYPEDEFS =============================================================*/

typedef enum {
  TSRV_UPDATE,
  TSRV_DELETE
} TagSetRV;

typedef TagSetRV (* TagSetMethod)(pTHX_ const TagTypeInfo *ptti, CtTag *tag, SV *val);
typedef SV *     (* TagGetMethod)(pTHX_ const TagTypeInfo *ptti, const CtTag *tag);
typedef void     (* TagVerifyMethod)(pTHX_ const TagTypeInfo *ptti, const CtTag *tag, SV *val);


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

#include "token/t_tag.c"


/*===== STATIC FUNCTIONS =====================================================*/

/*
 *                 So, how and when are tag methods called?
 *
 * Upon tag creation, TAG_INIT() is called to initialize the newly allocated
 * tag object. This can be used to allocate extra memory to store more tag
 * information or simply to initialize the flags and any members.
 *
 * TAG_CLONE() is obviously called when a tag object is cloned.
 *
 * TAG_FREE() is called when when a tag is removed from a taglist and the
 * tag object is about to be destroyed.
 *
 * TAG_SET() is called when the tag is assigned a (new) value. This method
 * can itself decide whether a SET is an UPDATE or a DELETE. In the latter
 * case, TAG_FREE() will be called after TAG_SET() returns.
 *
 * TAG_GET() is called to get information about the tag object.
 *
 * TAG_VERIFY() is optionally called before TAG_SET() / TAG_GET(), but you
 * usually don't need to implement it if you implement the latter methods.
 */

/*******************************************************************************
*
*   ROUTINE: croak_on_bitfield
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2006
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

static void croak_on_bitfield(pTHX_ const TagTypeInfo *ptti, const char *tagname)
{
  Declarator *pDecl = ptti->mi.pDecl;

  if (pDecl && pDecl->bitfield_flag)
    Perl_croak(aTHX_ "Cannot use '%s' tag on bitfields", tagname);
}

/*******************************************************************************
*
*   ROUTINE: Format_Verify
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2006
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

static TAG_VERIFY(Format)
{
  croak_on_bitfield(aTHX_ ptti, "Format");
}

/*******************************************************************************
*
*   ROUTINE: ByteOrder_Verify
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2006
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

static TAG_VERIFY(ByteOrder)
{
  croak_on_bitfield(aTHX_ ptti, "ByteOrder");
}

/*******************************************************************************
*
*   ROUTINE: Hooks_*
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

static TAG_INIT(Hooks)
{
  tag->any = hook_new(NULL);
}

static TAG_CLONE(Hooks)
{
  dst->any = hook_new(src->any);
}

static TAG_FREE(Hooks)
{
  hook_delete(tag->any);
}

static TAG_SET(Hooks)
{
  if (SvOK(val))
  {
    HV *hooks;
    TypeHooks newhooks, *p_oldhooks = tag->any;

    if (!(SvROK(val) && SvTYPE(hooks=(HV *)SvRV(val)) == SVt_PVHV))
      Perl_croak(aTHX_ "Need a hash reference to define hooks for '%s'", ptti->type);

    newhooks = *p_oldhooks;

    if (find_hooks(aTHX_ ptti->type, hooks, &newhooks) > 0)
    {
      hook_update(p_oldhooks, &newhooks);
      return TSRV_UPDATE;
    }
  }

  return TSRV_DELETE;
}

static TAG_GET(Hooks)
{
  return newRV_noinc((SV *) get_hooks(aTHX_ tag->any));
}

/*******************************************************************************
*
*   ROUTINE: Dimension_*
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

static TAG_INIT(Dimension)
{
  tag->any = dimtag_new(NULL);
}

static TAG_CLONE(Dimension)
{
  dst->any = dimtag_new(src->any);
}

static TAG_FREE(Dimension)
{
  dimtag_delete(tag->any);
}

static TAG_SET(Dimension)
{
  if (SvOK(val))
  {
    DimensionTag newdim;

    if (dimtag_parse(aTHX_ &ptti->mi, ptti->type, val, &newdim) > 0)
    {
      dimtag_update(tag->any, &newdim);

      return TSRV_UPDATE;
    }
  }

  return TSRV_DELETE;
}

static TAG_GET(Dimension)
{
  return dimtag_get(aTHX_ tag->any);
}

static TAG_VERIFY(Dimension)
{
  dimtag_verify(aTHX_ &ptti->mi, ptti->type);
}

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: get_tags
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

SV *get_tags(pTHX_ const TagTypeInfo *ptti, CtTagList taglist)
{
  HV *hv = newHV();
  CtTag *tag;

  for (tag = taglist; tag; tag = tag->next)
  {
    if (tag->type < NUM_TAGIDS)
    {
      SV *sv = gs_TagTbl[tag->type].get(aTHX_ ptti, tag);
      const char *id = gs_TagIdStr[tag->type];
      if (hv_store(hv, id, strlen(id), sv, 0) == NULL)
        fatal("hv_store() failed in get_tags()");
    }
    else
      fatal("Unknown tag type (%d) in get_tags()", (int) tag->type);
  }

  return sv_2mortal(newRV_noinc((SV *) hv));
}

/*******************************************************************************
*
*   ROUTINE: handle_tag
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

void handle_tag(pTHX_ const TagTypeInfo *ptti, CtTagList *ptl, SV *name, SV *val, SV **rv)
{
  const struct tag_tbl_ent *etbl;
  const char *tagstr;
  CtTagType tagid;
  CtTag *tag;

  assert(ptl);
  assert(name);

  if (SvROK(name))
    Perl_croak(aTHX_ "Tag name must be a string, not a reference");

  tagstr = SvPV_nolen(name);
  tagid  = get_tag_id(tagstr);

  if (tagid == CBC_INVALID_TAG)
    Perl_croak(aTHX_ "Invalid tag name '%s'", tagstr);

  if (tagid > NUM_TAGIDS)
    fatal("Unknown tag type (%d) in handle_tag()", (int) tagid);

  etbl = &gs_TagTbl[tagid];

  tag = find_tag(*ptl, tagid);

  if (etbl->verify)
    etbl->verify(aTHX_ ptti, tag, val);

  if (val)
  {
    TagSetRV rv;

    if (tag == NULL)
    {
      dTHR;
      dXCPT;

      tag = tag_new(tagid, etbl->vtbl);

      XCPT_TRY_START {
        rv = etbl->set(aTHX_ ptti, tag, val);
      } XCPT_TRY_END

      XCPT_CATCH
      {
        tag_delete(tag);
        XCPT_RETHROW;
      }

      insert_tag(ptl, tag);
    }
    else
      rv = etbl->set(aTHX_ ptti, tag, val);

    switch (rv)
    {
      case TSRV_UPDATE:
        break;

      case TSRV_DELETE:
        tag_delete(remove_tag(ptl, tagid));
        tag = NULL;
        break;

      default:
        fatal("Invalid return value for tag set method (%d)", rv);
    }
  }

  if (rv)
    *rv = tag ? etbl->get(aTHX_ ptti, tag) : &PL_sv_undef;
}

/*******************************************************************************
*
*   ROUTINE: find_taglist_ptr
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2005
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

CtTagList *find_taglist_ptr(const void *pType)
{
  if (pType)
    switch (GET_CTYPE(pType))
    {
      case TYP_STRUCT:  return &((Struct *) pType)->tags;
      case TYP_ENUM:    return &((EnumSpecifier *) pType)->tags;
      case TYP_TYPEDEF: return &((Typedef *) pType)->pDecl->tags;

      default:
        fatal("Invalid type (%d) in find_taglist_ptr()", GET_CTYPE(pType));
    }

  return NULL;
}

/*******************************************************************************
*
*   ROUTINE: delete_all_tags
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

void delete_all_tags(CtTagList *ptl)
{
  delete_taglist(ptl);
}

