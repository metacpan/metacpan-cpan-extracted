/*******************************************************************************
*
* HEADER: dimension.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C dimension tag
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_DIMENSION_H
#define _CBC_DIMENSION_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/member.h"
#include "cbc/hook.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

typedef struct dimension_tag {
  enum dimension_tag_type {
    DTT_NONE,
    DTT_FLEXIBLE,
    DTT_FIXED,
    DTT_MEMBER,
    DTT_HOOK
  } type;
  union {
    IV          fixed;
    char       *member;
    SingleHook *hook;
  } u;
} DimensionTag;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define dimtag_verify CBC_dimtag_verify
void dimtag_verify(pTHX_ const MemberInfo *pmi, const char *type);

#define dimtag_new CBC_dimtag_new
DimensionTag *dimtag_new(const DimensionTag *src);

#define dimtag_delete CBC_dimtag_delete
void dimtag_delete(DimensionTag *dim);

#define dimtag_parse CBC_dimtag_parse
int dimtag_parse(pTHX_ const MemberInfo *pmi, const char *type, SV *tag, DimensionTag *dim);

#define dimtag_update CBC_dimtag_update
void dimtag_update(DimensionTag *dst, const DimensionTag *src);

#define dimtag_get CBC_dimtag_get
SV *dimtag_get(pTHX_ const DimensionTag *dim);

#define dimtag_is_flexible CBC_dimtag_is_flexible
int dimtag_is_flexible(pTHX_ const DimensionTag *dim);

#define dimtag_eval CBC_dimtag_eval
long dimtag_eval(pTHX_ const DimensionTag *dim, long avail, SV *self, HV *parent);

#endif
