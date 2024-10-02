/*******************************************************************************
*
* HEADER: tag.h
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

#ifndef _CBC_TAG_H
#define _CBC_TAG_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/arch.h"
#include "ctlib/cttags.h"
#include "cbc/member.h"

#include "token/t_tag.h"

/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

typedef struct {
  const char *type;
  MemberInfo  mi;
} TagTypeInfo;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_tags CBC_get_tags
SV *get_tags(pTHX_ const TagTypeInfo *ptti, CtTagList taglist);

#define handle_tag CBC_handle_tag
void handle_tag(pTHX_ const TagTypeInfo *ptti, CtTagList *ptl, SV *name, SV *val, SV **rv);

#define find_taglist_ptr CBC_find_taglist_ptr
CtTagList *find_taglist_ptr(const void *pType);

#define delete_all_tags CBC_delete_all_tags
void delete_all_tags(CtTagList *ptl);

#endif
