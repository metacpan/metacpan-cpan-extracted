/*******************************************************************************
*
* HEADER: bitfields.h
*
********************************************************************************
*
* DESCRIPTION: Bitfield layouting routines
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CTLIB_BITFIELDS_H
#define _CTLIB_BITFIELDS_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/arch.h"
#include "ctlib/cttype.h"

#include "token/t_blproperty.h"

/*===== DEFINES ==============================================================*/

#define BL_CLASS_FIXED               \
          const struct BLVtable *m;  \
          const struct BLClass *blc

/*===== TYPEDEFS =============================================================*/

struct BLClass;

enum BLError {
  BLE_NO_ERROR,
  BLE_INVALID_PROPERTY,
  BLE_BITFIELD_TOO_WIDE
};

typedef signed long BLPropValInt;

typedef struct _BLPropValue {
  enum BLPVType {
    BLPVT_INT,
    BLPVT_STR
  } type;
  union {
    BLPropValInt v_int;
    BLPropValStr v_str;
  } v;
} BLPropValue;

typedef struct _BLOption {
  BLProperty    prop;
  enum BLPVType type;
  int           nval;  /* number of allowed values (0: all values allowed) */
  const void   *pval;  /* pointer to list of allowed values */
} BLOption;

typedef struct _BLPushParam {
  Struct      *pStruct;
  Declarator  *pDecl;
  unsigned     type_size;
  unsigned     type_align;
} BLPushParam;

typedef struct _BitfieldLayouter *BitfieldLayouter;

struct BLVtable {
  BitfieldLayouter (*clone)      (BitfieldLayouter);
  void             (*init)       (BitfieldLayouter);
  void             (*reset)      (BitfieldLayouter);
  void             (*destroy)    (BitfieldLayouter);
  enum BLError     (*push)       (BitfieldLayouter, const BLPushParam *);
  enum BLError     (*finalize)   (BitfieldLayouter);
  enum BLError     (*get)        (BitfieldLayouter, BLProperty, BLPropValue *);
  enum BLError     (*set)        (BitfieldLayouter, BLProperty, const BLPropValue *);
  const BLOption * (*options)    (BitfieldLayouter, int *count);
  const char *     (*class_name) (BitfieldLayouter);
};

struct _BitfieldLayouter {
  BL_CLASS_FIXED;
};


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== FUNCTION PROTOTYPES ==================================================*/

#define bl_create CTlib_bl_create
BitfieldLayouter bl_create(const char *class_name);

#define bl_property CTlib_bl_property
BLProperty bl_property(const char *property);

#define bl_property_string CTlib_bl_property_string
const char *bl_property_string(BLProperty property);

#define bl_propval CTlib_bl_propval
BLPropValStr bl_propval(const char *propval);

#define bl_propval_string CTlib_bl_propval_string
const char *bl_propval_string(BLPropValStr propval);

#endif
