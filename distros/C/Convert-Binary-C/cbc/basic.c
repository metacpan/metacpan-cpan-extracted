/*******************************************************************************
*
* MODULE: basic.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C basic types
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

#include "cbc/basic.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

typedef struct basic_type_info {
  Declarator *pDecl;
} BTInfo;

enum BTName {
  BT_CHAR,
  BT_SIGNED_CHAR,
  BT_UNSIGNED_CHAR,
  BT_SHORT,
  BT_SIGNED_SHORT,
  BT_UNSIGNED_SHORT,
  BT_INT,
  BT_SIGNED_INT,
  BT_UNSIGNED_INT,
  BT_LONG,
  BT_SIGNED_LONG,
  BT_UNSIGNED_LONG,
  BT_LONG_LONG,
  BT_SIGNED_LONG_LONG,
  BT_UNSIGNED_LONG_LONG,
  BT_FLOAT,
  BT_DOUBLE,
  BT_LONG_DOUBLE,
  NUM_BT_NAMES
};

struct _basic_types
{
  BTInfo ti[NUM_BT_NAMES];
};


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: basic_types_new
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

BasicTypes basic_types_new(void)
{
  BasicTypes bt;
  int i;

  New(0, bt, 1, struct _basic_types);

  for (i = 0; i < NUM_BT_NAMES; i++)
    bt->ti[i].pDecl = decl_new("", 0);

  return bt;
}

/*******************************************************************************
*
*   ROUTINE: basic_types_delete
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

void basic_types_delete(BasicTypes bt)
{
  if (bt)
  {
    int i;

    for (i = 0; i < NUM_BT_NAMES; i++)
      decl_delete(bt->ti[i].pDecl);

    Safefree(bt);
  }
}

/*******************************************************************************
*
*   ROUTINE: basic_types_clone
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

BasicTypes basic_types_clone(const BasicTypes src)
{
  BasicTypes bt;
  int i;

  New(0, bt, 1, struct _basic_types);

  for (i = 0; i < NUM_BT_NAMES; i++)
    bt->ti[i].pDecl = decl_clone(src->ti[i].pDecl);

  return bt;
}

/*******************************************************************************
*
*   ROUTINE: basic_types_reset
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2005
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

void basic_types_reset(BasicTypes bt)
{
  int i;

  for (i = 0; i < NUM_BT_NAMES; i++)
  {
    Declarator *pDecl = bt->ti[i].pDecl;
    pDecl->size      = -1;
    pDecl->item_size = -1;
  }
}

/*******************************************************************************
*
*   ROUTINE: basic_types_get_declarator
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

Declarator *basic_types_get_declarator(BasicTypes bt, unsigned tflags)
{
  BTInfo *bti = &bt->ti[0];

  switch (tflags)
  {
    case T_CHAR:                                   return bti[BT_CHAR].pDecl;
    case T_CHAR | T_SIGNED:                        return bti[BT_SIGNED_CHAR].pDecl;
    case T_CHAR | T_UNSIGNED:                      return bti[BT_UNSIGNED_CHAR].pDecl;

    case T_SHORT | T_INT:
    case T_SHORT:                                  return bti[BT_SHORT].pDecl;
    case T_SHORT | T_SIGNED | T_INT:
    case T_SHORT | T_SIGNED:                       return bti[BT_SIGNED_SHORT].pDecl;
    case T_SHORT | T_UNSIGNED | T_INT:
    case T_SHORT | T_UNSIGNED:                     return bti[BT_UNSIGNED_SHORT].pDecl;

    case T_INT:                                    return bti[BT_INT].pDecl;
    case T_SIGNED:
    case T_INT | T_SIGNED:                         return bti[BT_SIGNED_INT].pDecl;
    case T_UNSIGNED:
    case T_INT | T_UNSIGNED:                       return bti[BT_UNSIGNED_INT].pDecl;

    case T_LONG | T_INT:
    case T_LONG:                                   return bti[BT_LONG].pDecl;
    case T_LONG | T_SIGNED | T_INT:
    case T_LONG | T_SIGNED:                        return bti[BT_SIGNED_LONG].pDecl;
    case T_LONG | T_UNSIGNED | T_INT:
    case T_LONG | T_UNSIGNED:                      return bti[BT_UNSIGNED_LONG].pDecl;

    case T_LONG | T_LONGLONG | T_INT:
    case T_LONG | T_LONGLONG:                      return bti[BT_LONG_LONG].pDecl;
    case T_LONG | T_LONGLONG | T_SIGNED | T_INT:
    case T_LONG | T_LONGLONG | T_SIGNED:           return bti[BT_SIGNED_LONG_LONG].pDecl;
    case T_LONG | T_LONGLONG | T_UNSIGNED | T_INT:
    case T_LONG | T_LONGLONG | T_UNSIGNED:         return bti[BT_UNSIGNED_LONG_LONG].pDecl;

    case T_FLOAT:                                  return bti[BT_FLOAT].pDecl;

    case T_DOUBLE:                                 return bti[BT_DOUBLE].pDecl;

    case T_LONG | T_DOUBLE:                        return bti[BT_LONG_DOUBLE].pDecl;

    default:                                       return NULL;
  }
}

/*******************************************************************************
*
*   ROUTINE: get_basic_type_spec
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2002
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

int get_basic_type_spec(const char *name, TypeSpec *pTS)
{
  const char *c;
  u_32 tflags = 0;

  for (;;)
  {
    success:
    /* skip whitespace */
    while (isSPACE(*name))
      name++;

    if (*name == '\0')
      break;

    if (!isALPHA(*name))
      return 0;

    c = name++;

    while (isALPHA(*name))
      name++;

    if (*name != '\0' && !isSPACE(*name))
      return 0;

#include "token/t_basic.c"

    unknown:
      return 0;
  }

  if (tflags == 0)
    return 0;

  if (pTS)
  {
    pTS->ptr    = NULL;
    pTS->tflags = tflags;
  }

  return 1;
}

