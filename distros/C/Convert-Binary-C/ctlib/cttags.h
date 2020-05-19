/*******************************************************************************
*
* HEADER: cttags.h
*
********************************************************************************
*
* DESCRIPTION: Tag properties to C types
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CTLIB_CTTAGS_H
#define _CTLIB_CTTAGS_H

/*===== GLOBAL INCLUDES ======================================================*/

/*===== LOCAL INCLUDES =======================================================*/

#include "arch.h"


/*===== DEFINES ==============================================================*/


/*===== TYPEDEFS =============================================================*/

typedef u_16 CtTagType;
typedef u_16 CtTagFlags;

typedef struct CtTag_ CtTag, *CtTagList;

typedef struct CtTagVtable_ {
  void (*init )(CtTag *);
  void (*clone)(CtTag *, const CtTag *);
  void (*free )(CtTag *);
} CtTagVtable;

struct CtTag_ {
  CtTag             *next;
  const CtTagVtable *vtable;
  CtTagType          type;
  CtTagFlags         flags;
  void              *any;
};

/*===== FUNCTION PROTOTYPES ==================================================*/

#define tag_new CTlib_tag_new
CtTag *tag_new(CtTagType type, const CtTagVtable *vtable);

#define tag_clone CTlib_tag_clone
CtTag *tag_clone(const CtTag *stag);

#define tag_delete CTlib_tag_delete
void tag_delete(CtTag *tag);


#define find_tag CTlib_find_tag
CtTag *find_tag(CtTagList list, CtTagType type);

#define insert_tag CTlib_insert_tag
void insert_tag(CtTagList *list, CtTag *tag);

#define remove_tag CTlib_remove_tag
CtTag *remove_tag(CtTagList *list, CtTagType type);

#define delete_taglist CTlib_delete_taglist
void delete_taglist(CtTagList *list);

#define clone_taglist CTlib_clone_taglist
CtTagList clone_taglist(CtTagList tag);

#endif
