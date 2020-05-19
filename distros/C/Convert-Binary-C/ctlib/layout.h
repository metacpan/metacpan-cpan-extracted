/*******************************************************************************
*
* HEADER: layout.h
*
********************************************************************************
*
* DESCRIPTION: Type layouting routines
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CTLIB_LAYOUT_H
#define _CTLIB_LAYOUT_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/arch.h"
#include "ctlib/cttype.h"
#include "ctlib/bitfields.h"
#include "ctlib/byteorder.h"


/*===== DEFINES ==============================================================*/

#if ARCH_HAVE_LONG_LONG
#define CTLIB_long_long_SIZE sizeof(long long)
#else
#define CTLIB_long_long_SIZE 8
#endif

#if ARCH_HAVE_LONG_DOUBLE
#define CTLIB_long_double_SIZE sizeof(long double)
#else
#define CTLIB_long_double_SIZE 12
#endif

#define CTLIB_double_SIZE  sizeof(double)
#define CTLIB_float_SIZE   sizeof(float)
#define CTLIB_char_SIZE    sizeof(char)
#define CTLIB_short_SIZE   sizeof(short)
#define CTLIB_long_SIZE    sizeof(long)
#define CTLIB_int_SIZE     sizeof(int)

#define CTLIB_POINTER_SIZE sizeof(void *)

#define CTLIB_ALIGNMENT    (native_alignment ? native_alignment                \
                                           : get_native_alignment())

#define CTLIB_COMPOUND_ALIGNMENT    (native_compound_alignment                 \
                                     ? native_compound_alignment               \
                                     : get_native_compound_alignment())


/*===== TYPEDEFS =============================================================*/

typedef enum {
  GTI_NO_ERROR = 0,
  GTI_NO_STRUCT_DECL
} ErrorGTI;

typedef struct {
  unsigned         alignment;
  unsigned         compound_alignment;
  unsigned         char_size;
  unsigned         int_size;
  unsigned         short_size;
  unsigned         long_size;
  unsigned         long_long_size;
  int              enum_size;
  unsigned         ptr_size;
  unsigned         float_size;
  unsigned         double_size;
  unsigned         long_double_size;
  CByteOrder       byte_order;
  BitfieldLayouter bflayouter;
} LayoutParam;


/*===== EXTERNAL VARIABLES ===================================================*/

#define native_alignment CTlib_native_alignment
extern unsigned native_alignment;

#define native_compound_alignment CTlib_native_compound_alignment
extern unsigned native_compound_alignment;


/*===== FUNCTION PROTOTYPES ==================================================*/

#define get_type_info_generic CTlib_get_type_info_generic
ErrorGTI get_type_info_generic(const LayoutParam *pLP, const TypeSpec *pTS,
                               const Declarator *pDecl, const char *format, ...);

#define layout_compound_generic CTlib_layout_compound_generic
void layout_compound_generic(const LayoutParam *pLP, Struct *pStruct);

#define get_native_alignment CTlib_get_native_alignment
unsigned get_native_alignment(void);

#define get_native_compound_alignment CTlib_get_native_compound_alignment
unsigned get_native_compound_alignment(void);

#define get_native_enum_size CTlib_get_native_enum_size
int get_native_enum_size(void);

#define get_native_unsigned_chars CTlib_get_native_unsigned_chars
int get_native_unsigned_chars(void);

#define get_native_unsigned_bitfields CTlib_get_native_unsigned_bitfields
int get_native_unsigned_bitfields(void);

#endif
