/*******************************************************************************
*
* MODULE: layout.c
*
********************************************************************************
*
* DESCRIPTION: Type layouting routines
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <assert.h>
#include <stddef.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/ctdebug.h"
#include "ctlib/cterror.h"
#include "ctlib/layout.h"


/*===== DEFINES ==============================================================*/

#define LAYOUT_ALIGNMENT(pLP)  ((pLP)->alignment ? (pLP)->alignment            \
                                                 : CTLIB_ALIGNMENT)

#define LAYOUT_COMPOUND_ALIGNMENT(pLP)  ((pLP)->compound_alignment             \
                                         ? (pLP)->compound_alignment           \
                                         : CTLIB_COMPOUND_ALIGNMENT)


/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

unsigned native_alignment          = 0;
unsigned native_compound_alignment = 0;


/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_type_info_generic
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
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

ErrorGTI get_type_info_generic(const LayoutParam *pLP, const TypeSpec *pTS,
                               const Declarator *pDecl, const char *format, ...)
{
  u_32 flags = pTS->tflags;
  void *tptr = pTS->ptr;
  unsigned *pSize = NULL, *pItemSize = NULL, *pAlign = NULL;
  u_32 *pFlags = NULL;
  ErrorGTI err = GTI_NO_ERROR;
  unsigned size;
  va_list ap;

  CT_DEBUG(CTLIB, ("get_type_info_generic( pLP=%p, pTS=%p "
                   "[flags=0x%08lX, ptr=%p], pDecl=%p, format=\"%s\" )",
                   pLP, pTS, (unsigned long) flags, tptr, pDecl, format));

  va_start(ap, format);

  for (; *format; format++)
  {
    switch (*format)
    {
      case 'a': pAlign    = va_arg(ap, unsigned *); break;
      case 'f': pFlags    = va_arg(ap, u_32 *);     break;
      case 'i': pItemSize = va_arg(ap, unsigned *); break;
      case 's': pSize     = va_arg(ap, unsigned *); break;

      default:
        fatal_error("invalid format character (%c) in get_type_info_generic()", *format);
        break;
    }
  }

  va_end(ap);

  if (pFlags)
    *pFlags = 0;

  if (pDecl && pDecl->pointer_flag)
  {
    CT_DEBUG(CTLIB, ("pointer flag set"));

    size = pLP->ptr_size ? pLP->ptr_size : CTLIB_POINTER_SIZE;

    if (pAlign)
      *pAlign = size;
  }
  else if (flags & T_TYPE)
  {
    Typedef *pTypedef = (Typedef *) tptr;

    CT_DEBUG(CTLIB, ("T_TYPE flag set"));

    assert(pTypedef != NULL);

    if (pFlags)
    {
      u_32 flags;

      err = get_type_info_generic(pLP, pTypedef->pType, pTypedef->pDecl,
                                  "saf", &size, pAlign, &flags);

      *pFlags |= flags;
    }
    else
      err = get_type_info_generic(pLP, pTypedef->pType, pTypedef->pDecl,
                                  "sa", &size, pAlign);
  }
  else if (flags & T_ENUM)
  {
    CT_DEBUG(CTLIB, ("T_ENUM flag set"));

    assert(pLP->enum_size > 0 || tptr != NULL);

    size = pLP->enum_size > 0
           ? (unsigned) pLP->enum_size
           : ((EnumSpecifier *) tptr)->sizes[-pLP->enum_size];

    if (pAlign)
      *pAlign = size;
  }
  else if (flags & T_COMPOUND)
  {
    Struct *pStruct = (Struct *) tptr;

    CT_DEBUG(CTLIB, ("T_STRUCT or T_UNION flag set"));

    assert(pStruct != NULL);

    if (pStruct->declarations == NULL)
    {
      CT_DEBUG(CTLIB, ("no struct declarations in get_type_info_generic"));

      size = pLP->int_size ? pLP->int_size : sizeof(int);

      if( pAlign )
        *pAlign = size;

      err = GTI_NO_STRUCT_DECL;
    }
    else
    {
      if (pStruct->align == 0)
        layout_compound_generic(pLP, pStruct);

      size = pStruct->size;

      if (pAlign)
        *pAlign = pStruct->align;
    }

    if (pFlags)
      *pFlags |= pStruct->tflags & (T_HASBITFIELD | T_UNSAFE_VAL);
  }
  else
  {
    CT_DEBUG( CTLIB, ("only basic type flags set") );

#define LOAD_SIZE( type ) \
        size = pLP->type ## _size ? pLP->type ## _size : CTLIB_ ## type ## _SIZE

    if (flags & T_VOID)  /* XXX: do we want void ? */
      size = 1;
    else if ((flags & (T_LONG|T_DOUBLE)) == (T_LONG|T_DOUBLE))
      LOAD_SIZE(long_double);
    else if(flags & T_LONGLONG) LOAD_SIZE(long_long);
    else if(flags & T_FLOAT)    LOAD_SIZE(float);
    else if(flags & T_DOUBLE)   LOAD_SIZE(double);
    else if(flags & T_CHAR)     LOAD_SIZE(char);
    else if(flags & T_SHORT)    LOAD_SIZE(short);
    else if(flags & T_LONG)     LOAD_SIZE(long);
    else                        LOAD_SIZE(int);

#undef LOAD_SIZE

    if (pAlign)
      *pAlign = size;
  }

  if (pItemSize)
    *pItemSize = size;

  if (pSize)
  {
    if (pDecl && pDecl->array_flag)
    {
      if (pDecl->array_flag)
      {
        ListIterator ai;
        Value *pValue;

        CT_DEBUG(CTLIB, ("processing array [%p]", pDecl->ext.array));

        LL_foreach(pValue, ai, pDecl->ext.array)
        {
          CT_DEBUG(CTLIB, ("[%ld]", pValue->iv));

          size *= pValue->iv;

          if (pFlags && IS_UNSAFE_VAL(*pValue))
            *pFlags |= T_UNSAFE_VAL;
        }
      }
      else if (pDecl->bitfield_flag)
      {
        size = 0;
      }
    }

    *pSize = size;
  }

  CT_DEBUG(CTLIB, ("get_type_info_generic( size(%p)=%d, align(%p)=%d, "
                   "item(%p)=%d, flags(%p)=0x%08lX ) finished",
                   pSize, pSize ? *pSize : 0, pAlign, pAlign ? *pAlign : 0,
                   pItemSize, pItemSize ? *pItemSize : 0,
                   pFlags, (unsigned long) (pFlags ? *pFlags : 0)));

  return err;
}

/*******************************************************************************
*
*   ROUTINE: layout_compound_generic
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
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

#define BL_SET_BYTE_ORDER(byte_order)                                          \
        do {                                                                   \
          BLPropValue pv;                                                      \
          enum BLError error;                                                  \
          switch (byte_order)                                                  \
          {                                                                    \
            case CBO_BIG_ENDIAN:    pv.v.v_str = BLPV_BIG_ENDIAN;    break;    \
            case CBO_LITTLE_ENDIAN: pv.v.v_str = BLPV_LITTLE_ENDIAN; break;    \
            default:                                                           \
              fatal_error("invalid byte-order in BL_SET_BYTEORDER()");         \
              break;                                                           \
          }                                                                    \
          pv.type = BLPVT_STR;                                                 \
          error = bl->m->set(bl, BLP_BYTE_ORDER, &pv);                         \
          if (error != BLE_NO_ERROR)                                           \
            fatal_error(blproperror, 's', BLP_BYTE_ORDER, error);              \
        } while (0)

#define BL_SET(prop, val)                                                      \
        do {                                                                   \
          BLPropValue pv;                                                      \
          enum BLError error;                                                  \
          pv.type = BLPVT_INT;                                                 \
          pv.v.v_int = val;                                                    \
          error = bl->m->set(bl, BLP_ ## prop, &pv);                           \
          if (error != BLE_NO_ERROR)                                           \
            fatal_error(blproperror, 's', BLP_ ## prop, error);                \
        } while (0)

#define BL_GET(prop, val)                                                      \
        do {                                                                   \
          BLPropValue pv;                                                      \
          enum BLError error;                                                  \
          error = bl->m->get(bl, BLP_ ## prop, &pv);                           \
          if (error != BLE_NO_ERROR)                                           \
            fatal_error(blproperror, 'g', BLP_ ## prop, error);                \
          assert(pv.type == BLPVT_INT);                                        \
          val = pv.v.v_int;                                                    \
        } while (0)

#define FINISH_BITFIELD                                                        \
        do {                                                                   \
          bl->m->finalize(bl);                                                 \
          BL_GET(OFFSET, pStruct->size );                                      \
          BL_GET(ALIGN,  pStruct->align);                                      \
        } while (0)

void layout_compound_generic(const LayoutParam *pLP, Struct *pStruct)
{
  ListIterator       sdi;
  static const char *blproperror = "couldn't %cet bitfield layouter property (%d) => error %d";
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  unsigned           size, item_size, align, alignment;
  u_32               flags;
  int                in_bitfield = 0;
  BitfieldLayouter   bl = pLP->bflayouter;

  CT_DEBUG(CTLIB, ("layout_compound_generic( %s ), got %d struct declaration(s)",
           pStruct->identifier[0] ? pStruct->identifier : "<no-identifier>",
           LL_count(pStruct->declarations)));

  if (pStruct->declarations == NULL)
  {
    CT_DEBUG(CTLIB, ("no struct declarations in layout_compound_generic"));
    return;
  }

  alignment = pStruct->pack ? pStruct->pack : LAYOUT_ALIGNMENT(pLP);

  pStruct->align = alignment < LAYOUT_COMPOUND_ALIGNMENT(pLP)
                 ? alignment : LAYOUT_COMPOUND_ALIGNMENT(pLP);

  BL_SET(MAX_ALIGN, alignment);
  BL_SET_BYTE_ORDER(pLP->byte_order);

  LL_foreach(pStructDecl, sdi, pStruct->declarations)
  {
    CT_DEBUG(CTLIB, ("%d declarators in struct declaration, tflags=0x%08lX ptr=%p",
             LL_count(pStructDecl->declarators),
             (unsigned long) pStructDecl->type.tflags, pStructDecl->type.ptr));

    pStructDecl->offset = pStruct->tflags & T_STRUCT ? -1 : 0;
    pStructDecl->size   = 0;

    if (pStructDecl->declarators)
    {
      ListIterator di;

      LL_foreach(pDecl, di, pStructDecl->declarators)
      {
        CT_DEBUG(CTLIB, ("current declarator [%s]",
                 pDecl->identifier[0] ? pDecl->identifier : "<no-identifier>"));

        get_type_info_generic(pLP, &pStructDecl->type, pDecl,
                              "saif", &size, &align, &item_size, &flags);

        CT_DEBUG(CTLIB, ("declarator size=%u, item=%u, align=%u, flags=0x%08lX",
                         size, item_size, align, (unsigned long) flags));

        if ((flags & T_HASBITFIELD) || pDecl->bitfield_flag)
        {
          CT_DEBUG(CTLIB, ("found bitfield '%s' in '%s %s'",
                   pDecl->identifier[0] ? pDecl->identifier : "<no-identifier>",
                   pStruct->tflags & T_STRUCT ? "struct" : "union",
                   pStruct->identifier[0] ? pStruct->identifier : "<no-identifier>"));

          pStruct->tflags |= T_HASBITFIELD;
        }

        if (flags & T_UNSAFE_VAL)
        {
          CT_DEBUG(CTLIB, ("unsafe values in '%s %s'",
                   pStruct->tflags & T_STRUCT ? "struct" : "union",
                   pStruct->identifier[0] ? pStruct->identifier : "<no-identifier>"));

          pStruct->tflags |= T_UNSAFE_VAL;
        }

        if (pDecl->bitfield_flag)
        {
          BLPushParam pp;
          enum BLError error;

          if (!in_bitfield)
          {
            bl->m->reset(bl);

            BL_SET(ALIGN, pStruct->align);

            if (pStruct->tflags & T_STRUCT)
            {
              BL_SET(OFFSET, pStruct->size);
              in_bitfield = 1;
            }
            else /* T_UNION */
            {
              BL_SET(OFFSET, 0);
              /* don't set in_bitfield = 1 */
            }
          }

          pp.pStruct    = pStruct;
          pp.pDecl      = pDecl;
          pp.type_size  = item_size;
          pp.type_align = align;

          error = bl->m->push(bl, &pp);

          if (error != BLE_NO_ERROR)
            fatal_error("couldn't push bitfield => error %d", error);

          if (pStruct->tflags & T_UNION)
            FINISH_BITFIELD;
        }
        else
        {
          if (in_bitfield)
          {
            FINISH_BITFIELD;
            in_bitfield = 0;
          }

          pDecl->size      = size;
          pDecl->item_size = item_size;

          if (align > alignment)
            align = alignment;

          if (align > pStruct->align)
            pStruct->align = align;

          if (pStruct->tflags & T_STRUCT)
          {
            unsigned mod = pStruct->size % align;

            if (mod)
              pStruct->size += align - mod;

            if (pStructDecl->offset < 0)
              pStructDecl->offset = pStruct->size;

            pDecl->offset = pStruct->size;
            pStruct->size += size;
          }
          else /* T_UNION */
          {
            pDecl->offset = 0;

            if (size > pStruct->size)
              pStruct->size = size;
          }
        }
      }
    }
    else /* unnamed struct/union */
    {
      if (in_bitfield)
      {
        FINISH_BITFIELD;
        in_bitfield = 0;
      }

      CT_DEBUG(CTLIB, ("current declaration is an unnamed struct/union"));

      get_type_info_generic(pLP, &pStructDecl->type, NULL,
                            "saf", &size, &align, &flags);
      CT_DEBUG(CTLIB, ("unnamed struct/union: size=%d, align=%d, flags=0x%08lX",
                       size, align, (unsigned long) flags));

      if (flags & T_HASBITFIELD)
      {
        CT_DEBUG(CTLIB, ("found bitfield in unnamed struct/union"));
        pStruct->tflags |= T_HASBITFIELD;
      }

      if (flags & T_UNSAFE_VAL)
      {
        CT_DEBUG(CTLIB, ("unsafe values in unnamed struct/union"));
        pStruct->tflags |= T_UNSAFE_VAL;
      }

      if (align > alignment)
        align = alignment;

      if (align > pStruct->align)
        pStruct->align = align;

      if (pStruct->tflags & T_STRUCT)
      {
        unsigned mod = pStruct->size % align;

        if (mod)
          pStruct->size += align - mod;

        if (pStructDecl->offset < 0)
          pStructDecl->offset = pStruct->size;

        pStruct->size += size;
      }
      else /* T_UNION */
      {
        if (size > pStruct->size)
          pStruct->size = size;
      }
    }

    if (pStructDecl->offset < 0)
      pStructDecl->offset = pStruct->size;

    pStructDecl->size = pStruct->size - pStructDecl->offset;

  }

  if (in_bitfield)
    FINISH_BITFIELD;

  if (pStruct->size % pStruct->align)
    pStruct->size += pStruct->align - pStruct->size % pStruct->align;

  CT_DEBUG(CTLIB, ("layout_compound_generic( %s ): size=%d, align=%d",
           pStruct->identifier[0] ? pStruct->identifier : "<no-identifier>",
           pStruct->size, pStruct->align));
}

/*******************************************************************************
*
*   ROUTINE: get_native_alignment
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Determine the native struct member alignment and store it to
*              the global native_alignment.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

#define CHECK_NATIVE_ALIGNMENT(type)                                           \
        do {                                                                   \
          struct _align { char a; type b; };                                   \
          unsigned off = offsetof(struct _align, b);                           \
          if (off > align)                                                     \
            align = off;                                                       \
        } while (0)

unsigned get_native_alignment(void)
{
  unsigned align = 0;

  CHECK_NATIVE_ALIGNMENT(int);
  CHECK_NATIVE_ALIGNMENT(int *);
  CHECK_NATIVE_ALIGNMENT(long);
  CHECK_NATIVE_ALIGNMENT(float);
  CHECK_NATIVE_ALIGNMENT(double);
#if ARCH_HAVE_LONG_LONG
  CHECK_NATIVE_ALIGNMENT(long long);
#endif
#if ARCH_HAVE_LONG_DOUBLE
  CHECK_NATIVE_ALIGNMENT(long double);
#endif

  native_alignment = align;

  return align;
}

#undef CHECK_NATIVE_ALIGNMENT

/*******************************************************************************
*
*   ROUTINE: get_native_compound_alignment
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Determine the native compound alignment and store it to the
*              global native_compound_alignment.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

unsigned get_native_compound_alignment(void)
{
  struct _align {
    char a;
    struct {
      char x;
    }    b;
  };

  unsigned align = offsetof(struct _align, b);

  native_compound_alignment = align;

  return align;
}

/*******************************************************************************
*
*   ROUTINE: get_native_enum_size
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Determine the native enum size.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int get_native_enum_size(void)
{
  enum pbyte { PB1 =      0, PB2 =   255 };
  enum nbyte { NB1 =   -128, NB2 =   127 };
  enum pword { PW1 =      0, PW2 = 65535 };
  enum nword { NW1 = -32768, NW2 = 32767 };
  enum plong { PL1 =      0, PL2 = 65536 };
  enum nlong { NL1 = -32768, NL2 = 32768 };

  if (sizeof(enum pbyte) == 2 && sizeof(enum nbyte) == 1 &&
      sizeof(enum pword) == 4 && sizeof(enum nword) == 2 &&
      sizeof(enum plong) == 4 && sizeof(enum nlong) == 4)
    return -1;

  if (sizeof(enum pbyte) == 1 && sizeof(enum nbyte) == 1 &&
      sizeof(enum pword) == 2 && sizeof(enum nword) == 2 &&
      sizeof(enum plong) == 4 && sizeof(enum nlong) == 4)
    return 0;

  if (sizeof(enum pbyte) == sizeof(enum nbyte) &&
      sizeof(enum pbyte) == sizeof(enum pword) &&
      sizeof(enum pbyte) == sizeof(enum nword) &&
      sizeof(enum pbyte) == sizeof(enum plong) &&
      sizeof(enum pbyte) == sizeof(enum nlong))
    return sizeof(enum pbyte);

  fatal_error("Unsupported native enum size (%d:%d:%d:%d:%d:%d)",
              sizeof(enum pbyte), sizeof(enum nbyte), sizeof(enum pword),
              sizeof(enum nword), sizeof(enum plong), sizeof(enum nlong));

  return -1000;
}

/*******************************************************************************
*
*   ROUTINE: get_native_unsigned_chars
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2006
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Determine if native chars are unsigned.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int get_native_unsigned_chars(void)
{
  char c = -1;
  int  i = (int) c;

  if (i == -1)
    return 0;

  if (i > 0)
    return 1;

  fatal_error("Strange result of cast from char to int (%d)", i);

  return -1000;
}

/*******************************************************************************
*
*   ROUTINE: get_native_unsigned_bitfields
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2006
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Determine if native bitfields are unsigned.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

int get_native_unsigned_bitfields(void)
{
  struct { int a:3; } x = { -1 };
  int  i = (int) x.a;

  if (i == -1)
    return 0;

  if (i > 0)
    return 1;

  fatal_error("Strange result of cast from bitfield to int (%d)", i);

  return -1000;
}

