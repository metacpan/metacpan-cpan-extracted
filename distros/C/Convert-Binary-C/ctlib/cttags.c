/*******************************************************************************
*
* MODULE: cttags.c
*
********************************************************************************
*
* DESCRIPTION: Tag properties to C types
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stddef.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "cttags.h"
#include "util/memalloc.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: tag_new
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: CtTag object constructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

CtTag *tag_new(CtTagType type, const CtTagVtable *vtable)
{
  CtTag *tag;

  AllocF(CtTag *, tag, sizeof(CtTag));

  tag->next   = NULL;
  tag->vtable = vtable;
  tag->type   = type;
  tag->flags  = 0;
  tag->any    = 0;

  if (tag->vtable && tag->vtable->init)
    tag->vtable->init(tag);

  return tag;
}

/*******************************************************************************
*
*   ROUTINE: tag_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone CtTag object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

CtTag *tag_clone(const CtTag *stag)
{
  CtTag *dtag;

  if (stag == NULL)
    return NULL;

  AllocF(CtTag *, dtag, sizeof(CtTag));
  memcpy(dtag, stag, sizeof(CtTag));

  if (stag->vtable && stag->vtable->clone)
    stag->vtable->clone(dtag, stag);

  return dtag;
}

/*******************************************************************************
*
*   ROUTINE: tag_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: CtTag object destructor.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void tag_delete(CtTag *tag)
{
  if (tag)
  {
    if (tag->vtable && tag->vtable->free)
      tag->vtable->free(tag);

    Free(tag);
  }
}

/*******************************************************************************
*
*   ROUTINE: find_tag
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Find a CtTag object.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

CtTag *find_tag(CtTagList list, CtTagType type)
{
  while (list && list->type != type)
    list = list->next;

  return list;
}

/*******************************************************************************
*
*   ROUTINE: insert_tag
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Insert a CtTag object into a list.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void insert_tag(CtTagList *list, CtTag *tag)
{
  tag->next = *list;
  *list = tag;
}

/*******************************************************************************
*
*   ROUTINE: remove_tag
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Remove a single CtTag object from a list.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

CtTag *remove_tag(CtTagList *list, CtTagType type)
{
  while (*list)
  {
    if ((*list)->type == type)
    {
      CtTag *tag = *list;
      *list = (*list)->next;
      tag->next = NULL;
      return tag;
    }

    list = &(*list)->next;
  }

  return NULL;
}

/*******************************************************************************
*
*   ROUTINE: delete_taglist
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Remove all CtTag objects from a list.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void delete_taglist(CtTagList *list)
{
  CtTag *tag = *list;
  *list = NULL;

  while (tag)
  {
    CtTag *old = tag;
    tag = tag->next;
    tag_delete(old);
  }
}

/*******************************************************************************
*
*   ROUTINE: clone_taglist
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clone a CtTag list.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

CtTagList clone_taglist(CtTagList list)
{
  CtTagList rv = NULL;
  CtTagList *cloned = &rv;

  while (list)
  {
    *cloned = tag_clone(list);
    cloned  = &(*cloned)->next;
    *cloned = NULL;
    list = list->next;
  }

  return rv;
}

