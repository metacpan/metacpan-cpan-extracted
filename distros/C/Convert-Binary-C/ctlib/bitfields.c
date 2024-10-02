/*******************************************************************************
*
* MODULE: bitfields.c
*
********************************************************************************
*
* DESCRIPTION: Bitfield layouting routines
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <assert.h>
#include <string.h>
#include <stddef.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/ctdebug.h"
#include "ctlib/cterror.h"
#include "ctlib/bitfields.h"

#include "util/ccattr.h"
#include "util/memalloc.h"


/*===== DEFINES ==============================================================*/

#define REG_BL_CLASS(cls)  { #cls, sizeof(struct _BL_ ## cls), &cls ## _vtable }
#define BL_SELF(cls)       BL_ ## cls self = (BL_ ## cls) _self
#define aSELF              BitfieldLayouter _self __attribute__((unused))

#ifdef BITS
#  undef BITS
#endif
#define BITS(bytes)        (8*(bytes))

#define BYTE_ORDER_STRING  (self->byte_order == BLPV_BIG_ENDIAN ? "BE" : "LE")

/*===== TYPEDEFS =============================================================*/

typedef struct _BL_Generic {
  BL_CLASS_FIXED;
  BLPropValStr byte_order;
  BLPropValInt max_align;
  BLPropValInt align;
  BLPropValInt offset;
  int bit_offset;
  int cur_type_size;
  int cur_type_align;
} *BL_Generic;

typedef struct _BL_Microsoft {
  BL_CLASS_FIXED;
  BLPropValStr byte_order;
  BLPropValInt max_align;
  BLPropValInt align;
  BLPropValInt offset;
  int bit_offset;
  int cur_type_size;
  int cur_type_align;
} *BL_Microsoft;

typedef struct _BL_Simple {
  BL_CLASS_FIXED;
  BLPropValStr byte_order;
  BLPropValInt max_align;
  BLPropValInt align;
  BLPropValInt offset;
  BLPropValInt block_size;
  int pos;
  int bits_left;
} *BL_Simple;


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void             Generic_init(aSELF);
static void             Generic_reset(aSELF);
static enum BLError     Generic_push(aSELF, const BLPushParam *pParam);
static enum BLError     Generic_finalize(aSELF);
static enum BLError     Generic_get(aSELF, BLProperty prop, BLPropValue *value);
static enum BLError     Generic_set(aSELF, BLProperty prop, const BLPropValue *value);
static const BLOption * Generic_options(aSELF, int *count);

static void             Microsoft_init(aSELF);
static void             Microsoft_reset(aSELF);
static enum BLError     Microsoft_push(aSELF, const BLPushParam *pParam);
static enum BLError     Microsoft_finalize(aSELF);
static enum BLError     Microsoft_get(aSELF, BLProperty prop, BLPropValue *value);
static enum BLError     Microsoft_set(aSELF, BLProperty prop, const BLPropValue *value);
static const BLOption * Microsoft_options(aSELF, int *count);

static void             Simple_init(aSELF);
static void             Simple_reset(aSELF);
static enum BLError     Simple_push(aSELF, const BLPushParam *pParam);
static enum BLError     Simple_finalize(aSELF);
static enum BLError     Simple_get(aSELF, BLProperty prop, BLPropValue *value);
static enum BLError     Simple_set(aSELF, BLProperty prop, const BLPropValue *value);
static const BLOption * Simple_options(aSELF, int *count);

static void             bl_destroy(BitfieldLayouter self);
static BitfieldLayouter bl_clone(BitfieldLayouter self);
static const char *     bl_class_name(BitfieldLayouter self);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

static const struct BLVtable Generic_vtable = {
  bl_clone,
  Generic_init,
  Generic_reset,
  bl_destroy,
  Generic_push,
  Generic_finalize,
  Generic_get,
  Generic_set,
  Generic_options,
  bl_class_name,
};

static const struct BLVtable Microsoft_vtable = {
  bl_clone,
  Microsoft_init,
  Microsoft_reset,
  bl_destroy,
  Microsoft_push,
  Microsoft_finalize,
  Microsoft_get,
  Microsoft_set,
  Microsoft_options,
  bl_class_name,
};

static const struct BLVtable Simple_vtable = {
  bl_clone,
  Simple_init,
  Simple_reset,
  bl_destroy,
  Simple_push,
  Simple_finalize,
  Simple_get,
  Simple_set,
  Simple_options,
  bl_class_name,
};

static const struct BLClass {
  const char *name;
  const size_t size;
  const struct BLVtable *vtbl;
} bl_classes[] = {
  REG_BL_CLASS(Generic),
  REG_BL_CLASS(Microsoft),
  REG_BL_CLASS(Simple)
};


/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
********************************************************************************
********************************************************************************
                       ______                     _     
                      / ____/__  ____  ___  _____(_)____
                     / / __/ _ \/ __ \/ _ \/ ___/ / ___/
                    / /_/ /  __/ / / /  __/ /  / / /__  
                    \____/\___/_/ /_/\___/_/  /_/\___/  

********************************************************************************
********************************************************************************
*******************************************************************************/

/*******************************************************************************
*
*   ROUTINE: Generic_init
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Generic_init(aSELF)
{
  BL_SELF(Generic);

  self->byte_order = BLPV_LITTLE_ENDIAN;
}

/*******************************************************************************
*
*   ROUTINE: Generic_reset
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Generic_reset(aSELF)
{
  BL_SELF(Generic);

  self->bit_offset     = 0;
  self->cur_type_size  = 0;
  self->cur_type_align = 0;
}

/*******************************************************************************
*
*   ROUTINE: Generic_push
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Generic_push(aSELF, const BLPushParam *pParam)
{
  BL_SELF(Generic);
  BitfieldInfo *bit;

  assert(pParam->pDecl != NULL);
  assert(pParam->pDecl->bitfield_flag);

  bit = &pParam->pDecl->ext.bitfield;

  CT_DEBUG(CTLIB, ("(Generic) pushing bitfield (%s:%d/s=%d/a=%d), offset=%d.%d, max_align=%d",
                   pParam->pDecl->identifier, bit->bits,
                   pParam->type_size, pParam->type_align,
                   (int) self->offset, self->bit_offset, (int) self->max_align));

  if (self->cur_type_size != (int) pParam->type_size)
  {
    int align = (int) pParam->type_align < self->max_align
              ? (int) pParam->type_align : self->max_align;
    int delta = self->offset % align;

    if (align > self->align)
      self->align = align;

    self->offset     -= delta;
    self->bit_offset += BITS(delta);

    CT_DEBUG(CTLIB, ("(Generic) type size change: size: %d -> %d, align: %d -> %d, offset=%d.%d",
                     self->cur_type_size, pParam->type_size, self->cur_type_align, align,
                     (int) self->offset, self->bit_offset));
  
    self->cur_type_size  = pParam->type_size;
    self->cur_type_align = align;
  }

  while (bit->bits > BITS(self->cur_type_size) - self->bit_offset)
  {
    self->offset += self->cur_type_align;

    if (self->bit_offset > BITS(self->cur_type_align))
      self->bit_offset -= BITS(self->cur_type_align);
    else
      self->bit_offset = 0;

    CT_DEBUG(CTLIB, ("(Generic) move offset -> %d.%d",
                     (int) self->offset, self->bit_offset));
  }

  if (bit->bits == 0)
  {
    if (self->bit_offset > 0)
    {
      self->offset    += self->cur_type_size - (self->offset % self->cur_type_size);
      self->bit_offset = 0;
    }
  }
  else
  {
    int used_bytes, new_bit_offset;

    new_bit_offset = self->bit_offset + bit->bits;

    if (new_bit_offset <= BITS(1))
      used_bytes = 1;
    else if (new_bit_offset <= BITS(2))
      used_bytes = 2;
    else if (new_bit_offset <= BITS(4))
      used_bytes = 4;
    else if (new_bit_offset <= BITS(8))
      used_bytes = 8;

    assert(used_bytes <= self->cur_type_size);

    pParam->pDecl->offset = self->offset;
    pParam->pDecl->size   = used_bytes;

    bit->size             = used_bytes;

    switch (self->byte_order)
    {
      case BLPV_LITTLE_ENDIAN:
        bit->pos = self->bit_offset;
        break;

      case BLPV_BIG_ENDIAN:
        bit->pos = BITS(used_bytes) - self->bit_offset - bit->bits;
        break;

      default:
        fatal_error("(Generic) invalid byte-order (%d)", self->byte_order);
        break;
    }

    assert(bit->pos < 64);

    self->bit_offset = new_bit_offset;
  }

  CT_DEBUG(CTLIB, ("(Generic) new %s bitfield (%s) at (offset=%d, size=%d, pos=%d, bits=%d)",
                   BYTE_ORDER_STRING, pParam->pDecl->identifier,
                   pParam->pDecl->offset, bit->size, bit->pos, bit->bits));

  return BLE_NO_ERROR;
}

/*******************************************************************************
*
*   ROUTINE: Generic_finalize
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Generic_finalize(aSELF)
{
  BL_SELF(Generic);

  CT_DEBUG(CTLIB, ("(Generic) finalizing bitfield (offset=%d.%d)",
                   (int) self->offset, self->bit_offset));

  self->offset += (self->bit_offset + (BITS(1)-1)) / BITS(1);

  CT_DEBUG(CTLIB, ("(Generic) final offset=%d", (int) self->offset));

  return BLE_NO_ERROR;
}

/*******************************************************************************
********************************************************************************
********************************************************************************
                  __  ____                            ______ 
                 /  |/  (_)_____________  _________  / __/ /_
                / /|_/ / / ___/ ___/ __ \/ ___/ __ \/ /_/ __/
               / /  / / / /__/ /  / /_/ (__  ) /_/ / __/ /_  
              /_/  /_/_/\___/_/   \____/____/\____/_/  \__/  
                                              
********************************************************************************
********************************************************************************
*******************************************************************************/

/*******************************************************************************
*
*   ROUTINE: Microsoft_init
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Microsoft_init(aSELF)
{
  BL_SELF(Microsoft);

  self->byte_order = BLPV_LITTLE_ENDIAN;
}

/*******************************************************************************
*
*   ROUTINE: Microsoft_reset
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Microsoft_reset(aSELF)
{
  BL_SELF(Microsoft);

  self->bit_offset     = 0;
  self->cur_type_size  = 0;
  self->cur_type_align = 0;
}

/*******************************************************************************
*
*   ROUTINE: Microsoft_push
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Microsoft_push(aSELF, const BLPushParam *pParam)
{
  BL_SELF(Microsoft);
  BitfieldInfo *bit;

  assert(pParam->pDecl != NULL);
  assert(pParam->pDecl->bitfield_flag);

  bit = &pParam->pDecl->ext.bitfield;

  if (self->cur_type_size != (int) pParam->type_size)
  {
    int delta;
    int align = (int) pParam->type_align < self->max_align
              ? (int) pParam->type_align : self->max_align;

    if (align > self->align)
      self->align = align;

    if (self->bit_offset > 0)
    {
      self->offset    += self->cur_type_size;
      self->bit_offset = 0;
    }

    delta = self->offset % align;

    if (delta)
    {
      self->offset    += align - delta;
      self->bit_offset = 0;
    }

    self->cur_type_size  = pParam->type_size;
    self->cur_type_align = align;
  }

  if (bit->bits == 0)
  {
    if (self->bit_offset > 0)
    {
      self->offset    += self->cur_type_size;
      self->bit_offset = 0;
    }
  }
  else
  {
    if (bit->bits > BITS(self->cur_type_size) - self->bit_offset)
    {
      if (bit->bits > BITS(self->cur_type_size))
        return BLE_BITFIELD_TOO_WIDE;

      self->offset    += self->cur_type_size;
      self->bit_offset = 0;
    }

    switch (self->byte_order)
    {
      case BLPV_LITTLE_ENDIAN:
        bit->pos = self->bit_offset;
        break;

      case BLPV_BIG_ENDIAN:
        bit->pos = BITS(self->cur_type_size) - self->bit_offset - bit->bits;
        break;

      default:
        fatal_error("(Microsoft) invalid byte-order (%d)", self->byte_order);
        break;
    }

    assert(bit->pos < 64);

    self->bit_offset += bit->bits;

    pParam->pDecl->offset = self->offset;
    pParam->pDecl->size   = self->cur_type_size;
    bit->size             = self->cur_type_size;

    CT_DEBUG(CTLIB, ("(Microsoft) new %s bitfield (%s) at (offset=%d, size=%d, pos=%d, bits=%d), bit_offset=%d",
                     BYTE_ORDER_STRING, pParam->pDecl->identifier,
                     pParam->pDecl->offset, bit->size, bit->pos, bit->bits, self->bit_offset));
  }

  return BLE_NO_ERROR;
}

/*******************************************************************************
*
*   ROUTINE: Microsoft_finalize
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Microsoft_finalize(aSELF)
{
  BL_SELF(Microsoft);

  if (self->bit_offset > 0)
    self->offset += self->cur_type_size;

  return BLE_NO_ERROR;
}

/*******************************************************************************
********************************************************************************
********************************************************************************
                        _____ _                 __   
                       / ___/(_)___ ___  ____  / /__ 
                       \__ \/ / __ `__ \/ __ \/ / _ \
                      ___/ / / / / / / / /_/ / /  __/
                     /____/_/_/ /_/ /_/ .___/_/\___/ 
                                     /_/             
********************************************************************************
********************************************************************************
*******************************************************************************/

/*******************************************************************************
*
*   ROUTINE: Simple_init
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Simple_init(aSELF)
{
  BL_SELF(Simple);

  self->byte_order = BLPV_LITTLE_ENDIAN;
  self->block_size = 4;
}

/*******************************************************************************
*
*   ROUTINE: Simple_reset
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static void Simple_reset(aSELF)
{
  BL_SELF(Simple);

  self->offset   += self->block_size - (self->offset % self->block_size);
  self->pos       = 0;
  self->bits_left = BITS(self->block_size);
}

/*******************************************************************************
*
*   ROUTINE: Simple_push
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Simple_push(aSELF, const BLPushParam *pParam)
{
  BL_SELF(Simple);
  BitfieldInfo *bit;

  assert(pParam->pDecl != NULL);
  assert(pParam->pDecl->bitfield_flag);

  bit = &pParam->pDecl->ext.bitfield;

  if (bit->bits == 0)
  {
    self->pos += self->block_size;
    self->bits_left = BITS(self->block_size);
  }
  else
  {
    if (bit->bits > self->bits_left)
    {
      self->pos += self->block_size;
      self->bits_left = BITS(self->block_size);
    }

    pParam->pDecl->offset = self->offset + self->pos;
    pParam->pDecl->size   = self->block_size;

    bit->size = (unsigned char) self->block_size;

    switch (self->byte_order)
    {
      case BLPV_LITTLE_ENDIAN:
        bit->pos = BITS(self->block_size) - self->bits_left;
        break;

      case BLPV_BIG_ENDIAN:
        bit->pos = self->bits_left - bit->bits;
        break;

      default:
        fatal_error("(Simple) invalid byte-order (%d)", self->byte_order);
        break;
    }

    self->bits_left -= bit->bits;

    CT_DEBUG(CTLIB, ("(Simple) new %s bitfield (%s) at (offset=%d, size=%d, pos=%d, bits=%d), bits_left=%d",
                     BYTE_ORDER_STRING, pParam->pDecl->identifier,
                     pParam->pDecl->offset, pParam->pDecl->size, bit->pos, bit->bits, self->bits_left));
  }

  return BLE_NO_ERROR;
}

/*******************************************************************************
*
*   ROUTINE: Simple_finalize
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

static enum BLError Simple_finalize(aSELF)
{
  BL_SELF(Simple);

  if (self->bits_left != BITS(self->block_size))
    self->pos += self->block_size;

  self->offset += self->pos;
  self->align   = self->block_size;

  return BLE_NO_ERROR;
}

/*******************************************************************************
********************************************************************************
********************************************************************************
    __    _ __  _____      __    __     __                        __           
   / /_  (_) /_/ __(_)__  / /___/ /    / /___ ___  ______  __  __/ /____  _____
  / __ \/ / __/ /_/ / _ \/ / __  /    / / __ `/ / / / __ \/ / / / __/ _ \/ ___/
 / /_/ / / /_/ __/ /  __/ / /_/ /    / / /_/ / /_/ / /_/ / /_/ / /_/  __/ /    
/_.___/_/\__/_/ /_/\___/_/\__,_/____/_/\__,_/\__, /\____/\__,_/\__/\___/_/     
                              /_____/       /____/                             
********************************************************************************
********************************************************************************
*******************************************************************************/

/*******************************************************************************
*
*   ROUTINE: bl_destroy
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Destroys a BitfieldLayouter.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static void bl_destroy(BitfieldLayouter self)
{
  if (self)
    Free(self);
}

/*******************************************************************************
*
*   ROUTINE: bl_clone
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Clones a BitfieldLayouter.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static BitfieldLayouter bl_clone(BitfieldLayouter self)
{
  BitfieldLayouter clone;
  const struct BLClass *pc;

  assert(self != NULL);

  pc = self->blc;

  AllocF(BitfieldLayouter, clone, pc->size);
  memcpy(clone, self, pc->size);

  return clone;
}

/*******************************************************************************
*
*   ROUTINE: bl_class_name
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Returns the class name of a BitfieldLayouter.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static const char *bl_class_name(BitfieldLayouter self)
{
  assert(self != NULL);
  return self->blc->name;
}

/*******************************************************************************
*
*   ROUTINE: bl_create
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2005
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

BitfieldLayouter bl_create(const char *class_name)
{
  BitfieldLayouter self;
  unsigned i;
  const struct BLClass *pc = NULL;

  assert(class_name != NULL);

  CT_DEBUG(CTLIB, ("trying to create new [%s] bitfield layouter", class_name));

  for (i = 0; i < sizeof bl_classes / sizeof bl_classes[0]; i++)
    if (strcmp(class_name, bl_classes[i].name) == 0)
    {
      pc = &bl_classes[i];
      break;
    }

  if (pc == NULL)
  {
    CT_DEBUG(CTLIB, ("no such bitfield layouter class [%s]", class_name));
    return NULL;
  }

  AllocF(BitfieldLayouter, self, pc->size);
  memset(self, 0, pc->size);

  self->blc = pc;
  self->m = pc->vtbl;

  if (self->m->init)
    self->m->init(self);

  CT_DEBUG(CTLIB, ("created new [%s] bitfield layouter", class_name));

  return self;
}

#include "token/t_blproperty.c"

