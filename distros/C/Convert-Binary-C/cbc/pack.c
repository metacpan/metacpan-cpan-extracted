/*******************************************************************************
*
* MODULE: pack.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C pack/unpack routines
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

#define NO_XSLOCKS
#include <XSUB.h>

#include "ppport.h"


/*===== LOCAL INCLUDES =======================================================*/

#include "cbc/dimension.h"
#include "cbc/hook.h"
#include "cbc/idl.h"
#include "cbc/pack.h"
#include "cbc/tag.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*----------------------*/
/* access configuration */
/*----------------------*/

#define PCONFIG  (&PACK->THIS->cfg)

/*-----------------------------------*/
/* arguments to store_/fetch_integer */
/*-----------------------------------*/

#define SF_INT_ARGS(pBI)                                                       \
          (pBI) ? (pBI)->bits : 0,                                             \
          (pBI) ? (pBI)->pos : 0,                                              \
          (pBI) ? PCONFIG->layout.byte_order : PACK->order,                    \
          pPACKBUF

/*--------------------------------*/
/* macros for buffer manipulation */
/*--------------------------------*/

#define PACKPOS    PACK->buf.pos
#define PACKLEN    PACK->buf.length
#define pPACKBUF  (PACK->buf.buffer + PACKPOS)

#define CHECK_BUFFER(size)                                                     \
          STMT_START {                                                         \
            if (PACKPOS + (size) > PACKLEN)                                    \
            {                                                                  \
              PACKPOS = PACKLEN;                                               \
              return newSV(0);                                                 \
            }                                                                  \
          } STMT_END

#define GROW_BUFFER(size, reason)                                              \
          STMT_START {                                                         \
            unsigned long _required_ = PACKPOS + (size);                       \
            if (_required_ > PACKLEN)                                          \
            {                                                                  \
              CT_DEBUG(MAIN, ("Growing output SV from %ld to %ld bytes due "   \
                              "to %s", PACKLEN, _required_, reason));          \
              PACK->buf.buffer = SvGROW(PACK->bufsv, _required_ + 1);          \
              SvCUR_set(PACK->bufsv, _required_);                              \
              Zero(PACK->buf.buffer + PACKLEN, _required_ + 1 - PACKLEN, char);\
              PACKLEN = _required_;                                            \
            }                                                                  \
          } STMT_END

/*----------------*/
/* ID list macros */
/*----------------*/

#define IDLP_PUSH(what)      IDLIST_PUSH(&(PACK->idl), what)
#define IDLP_POP             IDLIST_POP(&(PACK->idl))
#define IDLP_SET_ID(value)   IDLIST_SET_ID(&(PACK->idl), value)
#define IDLP_SET_IX(value)   IDLIST_SET_IX(&(PACK->idl), value)

/*---------------------------*/
/* handling of ByteOrder tag */
/*---------------------------*/

#define dBYTEORDER           const CByteOrder old_byte_order = PACK->order

#define SET_BYTEORDER(tags)                                                   \
          STMT_START {                                                        \
            const CtTag *BOtag = find_tag(tags, CBC_TAG_BYTE_ORDER);          \
            if (BOtag)                                                        \
              switch (BOtag->flags)                                           \
              {                                                               \
                case CBC_TAG_BYTE_ORDER_BIG_ENDIAN:                           \
                  PACK->order = CBO_BIG_ENDIAN;                               \
                  break;                                                      \
                                                                              \
                case CBC_TAG_BYTE_ORDER_LITTLE_ENDIAN:                        \
                  PACK->order = CBO_LITTLE_ENDIAN;                            \
                  break;                                                      \
                                                                              \
                default:                                                      \
                  fatal("Unknown byte order (%d)", BOtag->flags);             \
                  break;                                                      \
              }                                                               \
          } STMT_END

#define RESTORE_BYTEORDER    PACK->order = old_byte_order

/*------------*/
/* some flags */
/*------------*/

#define PACK_FLEXIBLE   0x00000001


/*===== TYPEDEFS =============================================================*/

struct PackInfo {
  Buffer     buf;
  IDList     idl;
  const CBC *THIS;
  SV        *bufsv;
  SV        *self;
  CByteOrder order;
  HV        *parent;
};

typedef enum {
  FPT_UNKNOWN,
  FPT_FLOAT,
  FPT_DOUBLE,
  FPT_LONG_DOUBLE
} FPType;


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static FPType get_fp_type(u_32 flags);
static void store_float_sv(pPACKARGS, unsigned size, u_32 flags, SV *sv);
static SV *fetch_float_sv(pPACKARGS, unsigned size, u_32 flags);

static void store_int_sv(pPACKARGS, unsigned size, unsigned sign, const BitfieldInfo *pBI, SV *sv);
static SV *fetch_int_sv(pPACKARGS, unsigned size, unsigned sign, const BitfieldInfo *pBI);

static unsigned load_size(const CParseConfig *pCfg, u_32 *pFlags, const BitfieldInfo *pBI);

static void prepare_pack_format(pPACKARGS, const Declarator *pDecl, const CtTag *dimtag,
                                int *pSize, u_32 *pFlags);

static void pack_pointer(pPACKARGS, SV *sv);
static void pack_struct(pPACKARGS, const Struct *pStruct, SV *sv, int inlined);
static void pack_enum(pPACKARGS, const EnumSpecifier *pEnumSpec, const BitfieldInfo *pBI, SV *sv);
static void pack_basic(pPACKARGS, u_32 flags, const BitfieldInfo *pBI, SV *sv);
static void pack_format(pPACKARGS, const CtTag *format, unsigned size, u_32 flags, SV *sv);
static void pack_type(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension,
                                 const BitfieldInfo *pBI, SV *sv);

static SV *unpack_pointer(pPACKARGS);
static SV *unpack_struct(pPACKARGS, const Struct *pStruct, HV *hash);
static SV *unpack_enum(pPACKARGS, const EnumSpecifier *pEnumSpec, const BitfieldInfo *pBI);
static SV *unpack_basic(pPACKARGS, u_32 flags, const BitfieldInfo *pBI);
static SV *unpack_format(pPACKARGS, const CtTag *format, unsigned size, u_32 flags);
static SV *unpack_type(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension,
                                  const BitfieldInfo *pBI);

static SV *hook_call_typespec(pTHX_ SV *self, const TypeSpec *pTS,
                              enum HookId hook_id, SV *in, int mortal);

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: get_fp_type
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

static FPType get_fp_type(u_32 flags)
{
  /* mask out irrelevant flags */
  flags &= T_VOID | T_CHAR | T_SHORT | T_INT
         | T_LONG | T_FLOAT | T_DOUBLE | T_SIGNED
         | T_UNSIGNED | T_LONGLONG;

  /* only a couple of types are supported */
  switch (flags)
  {
    case T_LONG | T_DOUBLE: return FPT_LONG_DOUBLE;
    case T_DOUBLE         : return FPT_DOUBLE;
    case T_FLOAT          : return FPT_FLOAT;
  }

  return FPT_UNKNOWN;
}

/*******************************************************************************
*
*   ROUTINE: store_float_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

#ifdef CBC_HAVE_IEEE_FP

#define STORE_FLOAT(ftype)                                                     \
        STMT_START {                                                           \
          union {                                                              \
            ftype f;                                                           \
            u_8   c[sizeof(ftype)];                                            \
          } _u;                                                                \
          int _i;                                                              \
          u_8 *_p = (u_8 *) pPACKBUF;                                          \
          _u.f = (ftype) SvNV(sv);                                             \
          if (PACK->order == CBC_NATIVE_BYTEORDER)                             \
          {                                                                    \
            for (_i = 0; _i < (int)sizeof(ftype); _i++)                        \
              *_p++ = _u.c[_i];                                                \
          }                                                                    \
          else   /* swap */                                                    \
          {                                                                    \
            for (_i = sizeof(ftype)-1; _i >= 0; _i--)                          \
              *_p++ = _u.c[_i];                                                \
          }                                                                    \
        } STMT_END

#else /* ! CBC_HAVE_IEEE_FP */

#define STORE_FLOAT(ftype)                                                     \
        STMT_START {                                                           \
          if (size == sizeof(ftype))                                           \
          {                                                                    \
            u_8 *_p = (u_8 *) pPACKBUF;                                        \
            ftype _v = (ftype) SvNV(sv);                                       \
            Copy(&_v, _p, 1, ftype);                                           \
          }                                                                    \
          else                                                                 \
            goto non_native;                                                   \
        } STMT_END

#endif /* CBC_HAVE_IEEE_FP */

static void store_float_sv(pPACKARGS, unsigned size, u_32 flags, SV *sv)
{
  FPType type = get_fp_type(flags);

  if (type == FPT_UNKNOWN)
  {
    SV *str = NULL;
    get_basic_type_spec_string(aTHX_ &str, flags);
    WARN((aTHX_ "Unsupported floating point type '%s' in pack", SvPV_nolen(str)));
    SvREFCNT_dec(str);
    goto finish;
  }

#ifdef CBC_HAVE_IEEE_FP

  if (size == sizeof(float))
    STORE_FLOAT(float);
  else if (size == sizeof(double))
    STORE_FLOAT(double);
#if ARCH_HAVE_LONG_DOUBLE
  else if (size == sizeof(long double))
    STORE_FLOAT(long double);
#endif
  else
    WARN((aTHX_ "Cannot pack %d byte floating point values", size));

#else /* ! CBC_HAVE_IEEE_FP */

  if (PACK->order != CBC_NATIVE_BYTEORDER)
    goto non_native;

  switch (type)
  {
    case FPT_FLOAT          : STORE_FLOAT(float);       break;
    case FPT_DOUBLE         : STORE_FLOAT(double);      break;
#if ARCH_HAVE_LONG_DOUBLE
    case FPT_LONG_DOUBLE    : STORE_FLOAT(long double); break;
#endif
    default:
      goto non_native;
  }

  goto finish;

non_native:
  WARN((aTHX_ "Cannot pack non-native floating point values", size));

#endif /* CBC_HAVE_IEEE_FP */

finish:
  return;
}

#undef STORE_FLOAT

/*******************************************************************************
*
*   ROUTINE: fetch_float_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2003
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

#ifdef CBC_HAVE_IEEE_FP

#define FETCH_FLOAT(ftype)                                                     \
        STMT_START {                                                           \
          union {                                                              \
            ftype f;                                                           \
            u_8   c[sizeof(ftype)];                                            \
          } _u;                                                                \
          int _i;                                                              \
          u_8 *_p = (u_8 *) pPACKBUF;                                          \
          if (PACK->order == CBC_NATIVE_BYTEORDER)                             \
          {                                                                    \
            for (_i = 0; _i < (int)sizeof(ftype); _i++)                        \
              _u.c[_i] = *_p++;                                                \
          }                                                                    \
          else   /* swap */                                                    \
          {                                                                    \
            for (_i = sizeof(ftype)-1; _i >= 0; _i--)                          \
              _u.c[_i] = *_p++;                                                \
          }                                                                    \
          value = (NV) _u.f;                                                   \
        } STMT_END

#else /* ! CBC_HAVE_IEEE_FP */

#define FETCH_FLOAT(ftype)                                                     \
        STMT_START {                                                           \
          if (size == sizeof(ftype))                                           \
          {                                                                    \
            u_8 *_p = (u_8 *) pPACKBUF;                                        \
            ftype _v;                                                          \
            Copy(_p, &_v, 1, ftype);                                           \
            value = (NV) _v;                                                   \
          }                                                                    \
          else                                                                 \
            goto non_native;                                                   \
        } STMT_END

#endif /* CBC_HAVE_IEEE_FP */

static SV *fetch_float_sv(pPACKARGS, unsigned size, u_32 flags)
{
  FPType type = get_fp_type(flags);
  NV value = 0.0;

  if (type == FPT_UNKNOWN)
  {
    SV *str = NULL;
    get_basic_type_spec_string(aTHX_ &str, flags);
    WARN((aTHX_ "Unsupported floating point type '%s' in unpack", SvPV_nolen(str)));
    SvREFCNT_dec(str);
    goto finish;
  }

#ifdef CBC_HAVE_IEEE_FP

  if (size == sizeof(float))
    FETCH_FLOAT(float);
  else if (size == sizeof(double))
    FETCH_FLOAT(double);
#if ARCH_HAVE_LONG_DOUBLE
  else if (size == sizeof(long double))
    FETCH_FLOAT(long double);
#endif
  else
    WARN((aTHX_ "Cannot unpack %d byte floating point values", size));

#else /* ! CBC_HAVE_IEEE_FP */

  if (PACK->order != CBC_NATIVE_BYTEORDER)
    goto non_native;

  switch (type)
  {
    case FPT_FLOAT          : FETCH_FLOAT(float);       break;
    case FPT_DOUBLE         : FETCH_FLOAT(double);      break;
#if ARCH_HAVE_LONG_DOUBLE
    case FPT_LONG_DOUBLE    : FETCH_FLOAT(long double); break;
#endif
    default:
      goto non_native;
  }

  goto finish;

non_native:
  WARN((aTHX_ "Cannot unpack non-native floating point values", size));

#endif /* CBC_HAVE_IEEE_FP */

finish:
  return newSVnv(value);
}

#undef FETCH_FLOAT


/*******************************************************************************
*
*   ROUTINE: store_int_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
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

static void store_int_sv(pPACKARGS, unsigned size, unsigned sign, const BitfieldInfo *pBI, SV *sv)
{
  IntValue iv;

  iv.sign = sign;

  if (SvPOK(sv) && string_is_integer(SvPVX(sv)))
    iv.string = SvPVX(sv);
  else {
    iv.string = NULL;

    if (sign)
    {
      IV val = SvIV(sv);
      CT_DEBUG(MAIN, ("SvIV( sv ) = %" IVdf, val));
#if ARCH_NATIVE_64_BIT_INTEGER
      iv.value.s = val;
#else
      iv.value.s.h = val < 0 ? -1 : 0;
      iv.value.s.l = val;
#endif
    }
    else
    {
      UV val = SvUV(sv);
      CT_DEBUG(MAIN, ("SvUV( sv ) = %" UVuf, val));
#if ARCH_NATIVE_64_BIT_INTEGER
      iv.value.u = val;
#else
      iv.value.u.h = 0;
      iv.value.u.l = val;
#endif
    }
  }

  store_integer(size, SF_INT_ARGS(pBI), &iv);
}

/*******************************************************************************
*
*   ROUTINE: fetch_int_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
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

#if ARCH_NATIVE_64_BIT_INTEGER
#define __SIZE_LIMIT sizeof(IV)
#else
#define __SIZE_LIMIT sizeof(iv.value.u.l)
#endif

#if defined(newSVuv) && PERL_BCDVERSION >= 0x5006000
#define HAVE_USABLE_NEWSVUV 1
#else
#define HAVE_USABLE_NEWSVUV 0
#endif

#if HAVE_USABLE_NEWSVUV
#define __TO_UV(x) newSVuv((UV) (x))
#else
#define __TO_UV(x) newSViv((IV) (x))
#endif

static SV *fetch_int_sv(pPACKARGS, unsigned size, unsigned sign, const BitfieldInfo *pBI)
{
  IntValue iv;
  char buffer[32];

  /*
   *  Whew, I guess that could be done better,
   *  but at least it's working...
   */

#if HAVE_USABLE_NEWSVUV

  iv.string = size > __SIZE_LIMIT ? buffer : NULL;

#else  /* older perls don't have newSVuv */

  iv.string = size  > __SIZE_LIMIT ||
              (size == __SIZE_LIMIT && !sign)
              ? buffer : NULL;

#endif

  fetch_integer(size, sign, SF_INT_ARGS(pBI), &iv);

  if (iv.string)
    return newSVpv(iv.string, 0);

#if ARCH_NATIVE_64_BIT_INTEGER
  return sign ? newSViv(iv.value.s         ) : __TO_UV(iv.value.u  );
#else
  return sign ? newSViv((i_32) iv.value.s.l) : __TO_UV(iv.value.u.l);
#endif
}

#undef __SIZE_LIMIT
#undef __TO_UV

/*******************************************************************************
*
*   ROUTINE: load_size
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2004
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

static unsigned load_size(const CParseConfig *pCfg, u_32 *pFlags, const BitfieldInfo *pBI)
{
  unsigned size;

  if (pBI)
  {
    size = pBI->size;

    if (pCfg->unsigned_bitfields && (*pFlags & (T_SIGNED | T_UNSIGNED)) == 0)
      *pFlags |= T_UNSIGNED;
  }
  else
  {
    u_32 flags = *pFlags;

#define LOAD_SIZE(type)                                                        \
        size = pCfg->layout.type ## _size ? pCfg->layout.type ## _size         \
                                          : CTLIB_ ## type ## _SIZE

    if (flags & T_VOID)  /* XXX: do we want void ? */
      size = 1;
    else if (flags & T_CHAR)
    {
      LOAD_SIZE(char);
      if (pCfg->unsigned_chars && (flags & (T_SIGNED | T_UNSIGNED)) == 0)
        flags |= T_UNSIGNED;
    }
    else if ((flags & (T_LONG | T_DOUBLE)) == (T_LONG | T_DOUBLE))
      LOAD_SIZE(long_double);
    else if (flags & T_LONGLONG) LOAD_SIZE(long_long);
    else if (flags & T_FLOAT)    LOAD_SIZE(float);
    else if (flags & T_DOUBLE)   LOAD_SIZE(double);
    else if (flags & T_SHORT)    LOAD_SIZE(short);
    else if (flags & T_LONG)     LOAD_SIZE(long);
    else                         LOAD_SIZE(int);

#undef LOAD_SIZE

    *pFlags = flags;
  }

  return size;
}

/*******************************************************************************
*
*   ROUTINE: prepare_pack_format
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2005
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

static void prepare_pack_format(pPACKARGS, const Declarator *pDecl, const CtTag *dimtag,
                                int *pSize, u_32 *pFlags)
{
  int size, one = 0;

  assert(pDecl != NULL);

  if (dimtag || pDecl->size == 0)
  {
    if (pDecl->size == 0)
    {
      int dim = LL_count(pDecl->ext.array);

      one = pDecl->item_size;

      while (dim-- > 1)
        one *= ((Value *) LL_get(pDecl->ext.array, dim))->iv;
    }
    else
    {
      one = pDecl->size / ((Value *) LL_get(pDecl->ext.array, 0))->iv;
    }
  }

  /* check if it's an incomplete array type */
  if (pDecl->array_flag && (dimtag ? dimtag_is_flexible(aTHX_ dimtag->any) : pDecl->size == 0))
  {
    assert(one > 0);

    size = one;

    *pFlags |= PACK_FLEXIBLE;
  }
  else
  {
    if (dimtag)
    {
      assert(!dimtag_is_flexible(aTHX_ dimtag->any));
      assert(one > 0);

      size = one * dimtag_eval(aTHX_ dimtag->any, 0, PACK->self, PACK->parent);
    }
    else
    {
      size = pDecl->size;
    }
  }

  assert(size > 0);

  *pSize = size;
}

/*******************************************************************************
*
*   ROUTINE: pack_pointer
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

static void pack_pointer(pPACKARGS, SV *sv)
{
  unsigned size = PCONFIG->layout.ptr_size
                  ? PCONFIG->layout.ptr_size : sizeof(void *);

  CT_DEBUG(MAIN, (XSCLASS "::pack_pointer(sv=%p)", sv));

  GROW_BUFFER(size, "insufficient space");

  if (DEFINED(sv) && !SvROK(sv))
    store_int_sv(aPACKARGS, size, 0, NULL, sv);
}

/*******************************************************************************
*
*   ROUTINE: pack_struct
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

static void pack_struct(pPACKARGS, const Struct *pStruct, SV *sv, int inlined)
{
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  long               pos;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::pack_struct(pStruct=%p, sv=%p, inlined=%d)",
           pStruct, sv, inlined));

  if (pStruct->tags && !inlined)
  {
    const CtTag *tag;

    if ((tag = find_tag(pStruct->tags, CBC_TAG_HOOKS)) != NULL)
      sv = hook_call(aTHX_ PACK->self, pStruct->tflags & T_STRUCT ? "struct " : "union ",
                     pStruct->identifier, tag->any, HOOKID_pack, sv, 1);

    if ((tag = find_tag(pStruct->tags, CBC_TAG_FORMAT)) != NULL)
    {
      pack_format(aPACKARGS, tag, pStruct->size, 0, sv);
      return;
    }

    SET_BYTEORDER(pStruct->tags);
  }

  pos = PACKPOS;

  if (DEFINED(sv))
  {
    SV *hash;

    if (SvROK(sv) && SvTYPE(hash = SvRV(sv)) == SVt_PVHV)
    {
      ListIterator sdi;
      HV *h = (HV *) hash;

      IDLP_PUSH(ID);

      LL_foreach(pStructDecl, sdi, pStruct->declarations)
      {
        if (pStructDecl->declarators)
        {
          ListIterator di;

          LL_foreach(pDecl, di, pStructDecl->declarators)
          {
            size_t id_len = CTT_IDLEN(pDecl);

            if (id_len > 0)
            {
              SV **e = hv_fetch(h, pDecl->identifier, id_len, 0);
              BitfieldInfo *pBI;

              CT_DEBUG(MAIN, ("packing member '%s'", pDecl->identifier));

              if (e)
              {
                SvGETMAGIC(*e);

                IDLP_SET_ID(pDecl->identifier);

                assert(pDecl->offset >= 0);
                PACKPOS = pos + pDecl->offset;

                if (pDecl->bitfield_flag)
                {
                  pBI = &pDecl->ext.bitfield;

                  assert(pBI->bits > 0);  /* because id_len is > 0, too */
                  assert(pBI->pos < 64);
                  assert(pBI->size > 0 && pBI->size <= 8);
                }
                else
                  pBI = NULL;

                PACK->parent = h;
                pack_type(aPACKARGS, &pStructDecl->type, pDecl, 0, pBI, e ? *e : NULL);
                PACK->parent = NULL;
              }
            }
          }
        }
        else
        {
          TypeSpec *pTS = &pStructDecl->type;

          FOLLOW_AND_CHECK_TSPTR(pTS);

          IDLP_POP;

          assert(pStructDecl->offset >= 0);
          PACKPOS = pos + pStructDecl->offset;

          pack_struct(aPACKARGS, (Struct *) pTS->ptr, sv, 1);

          IDLP_PUSH(ID);
        }
      }

      IDLP_POP;
    }
    else
      WARN((aTHX_ "'%s' should be a hash reference",
            idl_to_str(aTHX_ &(PACK->idl))));
  }

  RESTORE_BYTEORDER;
}

/*******************************************************************************
*
*   ROUTINE: pack_enum
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

static void pack_enum(pPACKARGS, const EnumSpecifier *pEnumSpec, const BitfieldInfo *pBI, SV *sv)
{
  unsigned size = pBI ? pBI->size : GET_ENUM_SIZE(PCONFIG, pEnumSpec);
  IV value = 0;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::pack_enum(pEnumSpec=%p, pBI=%p sv=%p)", pEnumSpec, pBI, sv));

  if (pEnumSpec->tags)
  {
    const CtTag *tag;

    if ((tag = find_tag(pEnumSpec->tags, CBC_TAG_HOOKS)) != NULL)
      sv = hook_call(aTHX_ PACK->self, "enum ", pEnumSpec->identifier,
                     tag->any, HOOKID_pack, sv, 1);

    if ((tag = find_tag(pEnumSpec->tags, CBC_TAG_FORMAT)) != NULL)
    {
      assert(pBI == NULL);
      pack_format(aPACKARGS, tag, size, 0, sv);
      return;
    }

    SET_BYTEORDER(pEnumSpec->tags);
  }

  /* TODO: add some checks (range, perhaps even value) */

  GROW_BUFFER(size, "insufficient space");

  if (DEFINED(sv) && !SvROK(sv))
  {
    IntValue iv;

    if (SvIOK(sv))
      value = SvIVX(sv);
    else
    {
      Enumerator *pEnum = NULL;

      if (SvPOK(sv))
      {
        STRLEN len;
        char *str = SvPV(sv, len);

        pEnum = HT_get(PACK->THIS->cpi.htEnumerators, str, len, 0);

        if (pEnum)
        {
          if (IS_UNSAFE_VAL(pEnum->value))
            WARN((aTHX_ "Enumerator value '%s' is unsafe", str));
          value = pEnum->value.iv;
        }
      }

      if (pEnum == NULL)
        value = SvIV(sv);
    }

    CT_DEBUG(MAIN, ("value(sv) = %" IVdf, value));

    iv.string = NULL;
    iv.sign   = value < 0;

#if ARCH_NATIVE_64_BIT_INTEGER
    iv.value.s = value;
#else
    iv.value.s.h = value < 0 ? -1 : 0;
    iv.value.s.l = value;
#endif

    store_integer(size, SF_INT_ARGS(pBI), &iv);
  }

  RESTORE_BYTEORDER;
}

/*******************************************************************************
*
*   ROUTINE: pack_basic
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

static void pack_basic(pPACKARGS, u_32 flags, const BitfieldInfo *pBI, SV *sv)
{
  unsigned size;

  CT_DEBUG(MAIN, (XSCLASS "::pack_basic(flags=0x%08lX, pBI=%p sv=%p)",
           (unsigned long) flags, pBI, sv));

  CT_DEBUG(MAIN, ("buffer.pos=%lu, buffer.length=%lu", PACKPOS, PACKLEN));

  size = load_size(PCONFIG, &flags, pBI);

  GROW_BUFFER(size, "insufficient space");

  if (DEFINED(sv) && !SvROK(sv))
  {
    if (flags & (T_DOUBLE | T_FLOAT))
    {
      assert(pBI == NULL);
      store_float_sv(aPACKARGS, size, flags, sv);
    }
    else
      store_int_sv(aPACKARGS, size, (flags & T_UNSIGNED) == 0, pBI, sv);
  }
}

/*******************************************************************************
*
*   ROUTINE: pack_format
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

static void pack_format(pPACKARGS, const CtTag *format, unsigned size, u_32 flags, SV *sv)
{
  CT_DEBUG(MAIN, (XSCLASS "::pack_format(format->flags=0x%lX, size=%u, "
                  "flags=0x%lX, sv=%p)", (unsigned long) format->flags,
                  size, (unsigned long) flags, sv));

  if (flags & PACK_FLEXIBLE)
  {
    if (!DEFINED(sv))
      size = 0;
  }
  else
    GROW_BUFFER(size, "insufficient space");

  if (DEFINED(sv))
  {
    STRLEN len;
    const char *p = SvPV(sv, len);

    if (flags & PACK_FLEXIBLE)
    {
      if (format->flags == CBC_TAG_FORMAT_STRING)
      {
        STRLEN tmp = 0;

        while (p[tmp] && tmp < len)
          tmp++;

        len = tmp + 1;  /* null-termination */
      }

      size = len % size ? (unsigned) (len + size - (len % size))
                        : (unsigned) len;

      GROW_BUFFER(size, "incomplete array type");
    }

    if (len > size)
    {
#define COPY_STRING_LENGTH 16

      unsigned char *src = (unsigned char *)p;
      const char *fmtstr = "Unknown";
      const char *refstr;
      char copy[COPY_STRING_LENGTH];
      unsigned n;

      for (n = 0; n < COPY_STRING_LENGTH - 1 && n < len; n++)
        copy[n] = src[n] < 32 || src[n] > 127 ? '.' : (char) src[n];

      if (len > n)
        for (n -= 3; n < COPY_STRING_LENGTH - 1; n++)
          copy[n] = '.';

      copy[n] = '\0';

      switch (format->flags)
      {
        case CBC_TAG_FORMAT_BINARY: fmtstr = "Binary"; break;
        case CBC_TAG_FORMAT_STRING: fmtstr = "String"; break;
        default: fatal("Unknown format (%d)", format->flags);
      }

      /* hint the user that tries to pack format tagged references */
      refstr = SvROK(sv) ? " (Are you sure you want to pack a reference type?)"
                         : "";

      WARN((aTHX_ "Source string \"%s\" is longer (%u byte%s) than '%s'"
                  " (%u byte%s) while packing '%s' format%s",
            copy, (unsigned) len, len == 1 ? "" : "s", idl_to_str(aTHX_ &(PACK->idl)),
            size, size == 1 ? "" : "s", fmtstr, refstr));

      len = size;
    }

    switch (format->flags)
    {
      case CBC_TAG_FORMAT_BINARY:
        Copy(p, pPACKBUF, len, char);
        break;

      case CBC_TAG_FORMAT_STRING:
        strncpy(pPACKBUF, p, len);
        break;

      default:
        fatal("Unknown format (%d)", format->flags);
    }
  }
}

/*******************************************************************************
*
*   ROUTINE: pack_type
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

static void pack_type(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl,
                                 int dimension, const BitfieldInfo *pBI, SV *sv)
{
  const CtTag *dimtag = NULL;
  int dim;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::pack_type(pTS=%p, pDecl=%p, dimension=%d, "
           "pBI=%p, sv=%p)", pTS, pDecl, dimension, pBI, sv));

  assert(sv != NULL);

  if (pDecl && dimension == 0 && pDecl->tags)
  {
    const CtTag *tag;

    if ((tag = find_tag(pDecl->tags, CBC_TAG_HOOKS)) != NULL)
      sv = hook_call(aTHX_ PACK->self, NULL, pDecl->identifier,
                     tag->any, HOOKID_pack, sv, 1);

    dimtag = find_tag(pDecl->tags, CBC_TAG_DIMENSION);

    if ((tag = find_tag(pDecl->tags, CBC_TAG_FORMAT)) != NULL)
    {
      int size;
      u_32 flags = 0;

      assert(pBI == NULL);

      prepare_pack_format(aPACKARGS, pDecl, dimtag, &size, &flags);

      pack_format(aPACKARGS, tag, size, flags, sv);

      return;
    }

    SET_BYTEORDER(pDecl->tags);
  }

  assert(pDecl == NULL || pDecl->bitfield_flag == 0 || pBI != NULL);

  if (pDecl && pDecl->array_flag && dimension < (dim = LL_count(pDecl->ext.array)))
  {
    SV *ary;
    int size = pDecl->item_size;

    assert(size > 0);
    assert(pBI == NULL);

    if (DEFINED(sv) && SvROK(sv) && SvTYPE(ary = SvRV(sv)) == SVt_PVAV)
    {
      Value *v = (Value *) LL_get(pDecl->ext.array, dimension);
      long i, s, avail;
      unsigned long pos;
      AV *a = (AV *) ary;

      while (dim-- > dimension + 1)
        size *= ((Value *) LL_get(pDecl->ext.array, dim))->iv;

      avail = av_len(a)+1;

      if (dimtag)
      {
        assert(dimension == 0);
        s = dimtag_eval(aTHX_ dimtag->any, avail, PACK->self, PACK->parent);
        GROW_BUFFER(s*size, "dimension tag");
      }
      else if (v->flags & V_IS_UNDEF)
      {
        assert(dimension == 0);
        s = avail;
        GROW_BUFFER(s*size, "incomplete array type");
      }
      else
        s = v->iv;

      IDLP_PUSH(IX);

      pos = PACKPOS;

      for (i = 0; i < s; ++i)
      {
        SV **e = av_fetch(a, i, 0);

        if (e)
        {
          SvGETMAGIC(*e);

          IDLP_SET_IX(i);

          PACKPOS = pos + i * size;

          pack_type(aPACKARGS, pTS, pDecl, dimension+1, NULL, e ? *e : NULL);
        }
      }

      IDLP_POP;
    }
    else
    {
      if (DEFINED(sv))
        WARN((aTHX_ "'%s' should be an array reference",
                    idl_to_str(aTHX_ &(PACK->idl))));

      /* this is safe with flexible array members */
      while (dim-- > dimension)
        size *= ((Value *) LL_get(pDecl->ext.array, dim))->iv;

      GROW_BUFFER(size, "insufficient space");
    }
  }
  else if (pDecl && pDecl->pointer_flag)
  {
    assert(pBI == NULL);

    if (DEFINED(sv) && SvROK(sv))
      WARN((aTHX_ "'%s' should be a scalar value",
                  idl_to_str(aTHX_ &(PACK->idl))));
    sv = hook_call_typespec(aTHX_ PACK->self, pTS, HOOKID_pack_ptr, sv, 1);
    pack_pointer(aPACKARGS, sv);
  }
  else if (pTS->tflags & T_TYPE)
  {
    Typedef *pTD = pTS->ptr;
    pack_type(aPACKARGS, pTD->pType, pTD->pDecl, 0, pBI, sv);
  }
  else if(pTS->tflags & T_COMPOUND)
  {
    Struct *pStruct = (Struct *) pTS->ptr;

    assert(pBI == NULL);

    if (pStruct->declarations == NULL)
      WARN_UNDEF_STRUCT(pStruct);
    else
      pack_struct(aPACKARGS, pStruct, sv, 0);
  }
  else
  {
    if (DEFINED(sv) && SvROK(sv))
      WARN((aTHX_ "'%s' should be a scalar value",
                  idl_to_str(aTHX_ &(PACK->idl))));

    CT_DEBUG(MAIN, ("SET '%s' @ %lu", pDecl ? pDecl->identifier : "", PACKPOS));

    if (pTS->tflags & T_ENUM)
      pack_enum(aPACKARGS, pTS->ptr, pBI, sv);
    else
      pack_basic(aPACKARGS, pTS->tflags, pBI, sv);
  }

  RESTORE_BYTEORDER;
}

/*******************************************************************************
*
*   ROUTINE: unpack_pointer
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

static SV *unpack_pointer(pPACKARGS)
{
  unsigned size = PCONFIG->layout.ptr_size
                  ? PCONFIG->layout.ptr_size : sizeof(void *);

  CT_DEBUG(MAIN, (XSCLASS "::unpack_pointer()"));

  CHECK_BUFFER(size);

  return fetch_int_sv(aPACKARGS, size, 0, NULL);
}

/*******************************************************************************
*
*   ROUTINE: unpack_struct
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

static SV *unpack_struct(pPACKARGS, const Struct *pStruct, HV *hash)
{
  StructDeclaration *pStructDecl;
  Declarator        *pDecl;
  HV                *h = hash;
  long               pos;
  int                ordered;
  SV                *sv;
  const CtTag       *hooks = NULL;
  dTHR;
  dXCPT;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::unpack_struct(pStruct=%p, hash=%p)", pStruct, hash));

  if (pStruct->tags && hash == NULL)
  {
    const CtTag *format;

    hooks = find_tag(pStruct->tags, CBC_TAG_HOOKS);

    if ((format = find_tag(pStruct->tags, CBC_TAG_FORMAT)) != NULL)
    {
      sv = unpack_format(aPACKARGS, format, pStruct->size, 0);
      goto handle_unpack_hook;
    }

    SET_BYTEORDER(pStruct->tags);
  }

  ordered = PACK->THIS->order_members && PACK->THIS->ixhash != NULL;

  if (h == NULL)
    h = ordered ? newHV_indexed(aTHX_ PACK->THIS) :  newHV();

  pos = PACKPOS;

  XCPT_TRY_START
  {
    ListIterator sdi;

    LL_foreach(pStructDecl, sdi, pStruct->declarations)
    {
      if (pStructDecl->declarators)
      {
        ListIterator di;

        LL_foreach(pDecl, di, pStructDecl->declarators)
        {
          U32 klen = CTT_IDLEN(pDecl);

          if (klen > 0)
          {
            CT_DEBUG(MAIN, ("unpacking member '%s'", pDecl->identifier));

            if (hv_exists(h, pDecl->identifier, klen))
            {
              WARN((aTHX_ "Member '%s' used more than once in %s%s%s defined in %s(%ld)",
                    pDecl->identifier,
                    pStruct->tflags & T_UNION ? "union" : "struct",
                    pStruct->identifier[0] != '\0' ? " " : "",
                    pStruct->identifier[0] != '\0' ? pStruct->identifier : "",
                    pStruct->context.pFI->name, pStruct->context.line));
            }
            else
            {
              SV *value, **didstore;
              BitfieldInfo *pBI;

              assert(pDecl->offset >= 0);
              PACKPOS = pos + pDecl->offset;
    
              if (pDecl->bitfield_flag)
              {
                pBI = &pDecl->ext.bitfield;

                assert(pBI->bits > 0);  /* because id_len is > 0, too */
                assert(pBI->pos < 64);
                assert(pBI->size > 0 && pBI->size <= 8);
              }
              else
                pBI = NULL;

              PACK->parent = h;
              value = unpack_type(aPACKARGS, &pStructDecl->type, pDecl, 0, pBI);
              PACK->parent = NULL;

              didstore = hv_store(h, pDecl->identifier, klen, value, 0);

              if (ordered)
                SvSETMAGIC(value);

              if (!didstore)
                SvREFCNT_dec(value);
            }
          }
        }
      }
      else
      {
        TypeSpec *pTS = &pStructDecl->type;

        FOLLOW_AND_CHECK_TSPTR(pTS);

        assert(pStructDecl->offset >= 0);
        PACKPOS = pos + pStructDecl->offset;

        (void) unpack_struct(aPACKARGS, (Struct *) pTS->ptr, h);
      }
    }
  }
  XCPT_TRY_END

  RESTORE_BYTEORDER;

  XCPT_CATCH
  {
    if (hash == NULL)
    {
      CT_DEBUG(MAIN, ("freeing hv @ %p in unpack_struct:%d", h, __LINE__));
      SvREFCNT_dec((SV *) h);
    }

    XCPT_RETHROW;
  }

  if (hash)
    return NULL;

  sv = newRV_noinc((SV *) h);

handle_unpack_hook:

  if (hooks)
  {
    XCPT_TRY_START
    {
      sv = hook_call(aTHX_ PACK->self, pStruct->tflags & T_STRUCT ? "struct " : "union ",
                     pStruct->identifier, hooks->any, HOOKID_unpack, sv, 0);
    }
    XCPT_TRY_END

    XCPT_CATCH
    {
      CT_DEBUG(MAIN, ("freeing sv @ %p in unpack_struct:%d", sv, __LINE__));
      SvREFCNT_dec(sv);
      XCPT_RETHROW;
    }
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: unpack_enum
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

static SV *unpack_enum(pPACKARGS, const EnumSpecifier *pEnumSpec, const BitfieldInfo *pBI)
{
  Enumerator *pEnum;
  unsigned size = pBI ? pBI->size : GET_ENUM_SIZE(PCONFIG, pEnumSpec);
  IV value;
  SV *sv;
  const CtTag *hooks = NULL;
  IntValue iv;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::unpack_enum(pEnumSpec=%p, pBI=%p)", pEnumSpec, pBI));

  if (pEnumSpec->tags)
  {
    const CtTag *format;

    hooks = find_tag(pEnumSpec->tags, CBC_TAG_HOOKS);

    if ((format = find_tag(pEnumSpec->tags, CBC_TAG_FORMAT)) != NULL)
    {
      assert(pBI == NULL);
      sv = unpack_format(aPACKARGS, format, size, 0);
      goto handle_unpack_hook;
    }

    SET_BYTEORDER(pEnumSpec->tags);
  }

  CHECK_BUFFER(size);

  iv.string = NULL;
  fetch_integer(size, pEnumSpec->tflags & T_SIGNED, SF_INT_ARGS(pBI), &iv);

  if (pEnumSpec->tflags & T_SIGNED) /* TODO: handle (un)/signed correctly */
  {
#if ARCH_NATIVE_64_BIT_INTEGER
    value = iv.value.s;
#else
    value = (i_32) iv.value.s.l;
#endif
  }
  else
  {
#if ARCH_NATIVE_64_BIT_INTEGER
    value = iv.value.u;
#else
    value = iv.value.u.l;
#endif
  }

  if (PACK->THIS->enumType == ET_INTEGER)
    sv = newSViv(value);
  else
  {
    ListIterator ei;

    LL_foreach(pEnum, ei, pEnumSpec->enumerators)
      if(pEnum->value.iv == value)
        break;

    if (pEnumSpec->tflags & T_UNSAFE_VAL)
    {
      if (pEnumSpec->identifier[0] != '\0')
        WARN((aTHX_ "Enumeration '%s' contains unsafe values",
                    pEnumSpec->identifier));
      else
        WARN((aTHX_ "Enumeration contains unsafe values"));
    }

    switch (PACK->THIS->enumType)
    {
      case ET_BOTH:
        sv = newSViv(value);
        if (pEnum)
          sv_setpv(sv, pEnum->identifier);
        else
          sv_setpvf(sv, "<ENUM:%" IVdf ">", value);
        SvIOK_on(sv);
        break;

      case ET_STRING:
        if (pEnum)
          sv = newSVpv(pEnum->identifier, 0);
        else
          sv = newSVpvf("<ENUM:%" IVdf ">", value);
        break;

      default:
        fatal("Invalid enum type (%d) in unpack_enum()!", PACK->THIS->enumType);
        break;
    }
  }

  RESTORE_BYTEORDER;

handle_unpack_hook:

  if (hooks)
  {
    dTHR;
    dXCPT;

    XCPT_TRY_START
    {
      sv = hook_call(aTHX_ PACK->self, "enum ", pEnumSpec->identifier,
                     hooks->any, HOOKID_unpack, sv, 0);
    }
    XCPT_TRY_END

    XCPT_CATCH
    {
      CT_DEBUG(MAIN, ("freeing sv @ %p in unpack_enum:%d", sv, __LINE__));
      SvREFCNT_dec(sv);
      XCPT_RETHROW;
    }
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: unpack_basic
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

static SV *unpack_basic(pPACKARGS, u_32 flags, const BitfieldInfo *pBI)
{
  unsigned size;

  CT_DEBUG(MAIN, (XSCLASS "::unpack_basic(flags=0x%08lX, pBI=%p)",
           (unsigned long) flags, pBI));

  CT_DEBUG(MAIN, ("buffer.pos=%lu, buffer.length=%lu", PACKPOS, PACKLEN));

  size = load_size(PCONFIG, &flags, pBI);

  CHECK_BUFFER(size);

  if (flags & (T_FLOAT | T_DOUBLE))
  {
    assert(pBI == NULL);
    return fetch_float_sv(aPACKARGS, size, flags);
  }
  else
    return fetch_int_sv(aPACKARGS, size, (flags & T_UNSIGNED) == 0, pBI);
}

/*******************************************************************************
*
*   ROUTINE: unpack_format
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

static SV *unpack_format(pPACKARGS, const CtTag *format, unsigned size, u_32 flags)
{
  SV *sv;

  CT_DEBUG(MAIN, (XSCLASS "::unpack_format(format->flags=0x%lX, size=%u, flags=0x%lX)",
           (unsigned long) format->flags, size, (unsigned long) flags));

  if (PACKPOS + size > PACKLEN)
    return newSVpvn("", 0);

  if (flags & PACK_FLEXIBLE)
  {
    unsigned remain;

    assert(PACKPOS <= PACKLEN);

    remain = PACKLEN - PACKPOS;

    if (remain % size)
      remain -= remain % size;

    size = remain;
  }

  switch (format->flags)
  {
    case CBC_TAG_FORMAT_BINARY:
      sv = newSVpvn(pPACKBUF, size);
      break; 

    case CBC_TAG_FORMAT_STRING:
      {
        unsigned n;
        const char *buf = pPACKBUF;

        for (n = 0; n < size; n++)
          if (buf[n] == '\0')
            break;

        sv = newSVpvn(pPACKBUF, n);
      }
      break;

    default:
      fatal("Unknown format (%d)", format->flags);
  }

  return sv;
}

/*******************************************************************************
*
*   ROUTINE: unpack_type
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

static SV *unpack_type(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl,
                                  int dimension, const BitfieldInfo *pBI)
{
  SV *rv = NULL;
  const CtTag *hooks = NULL;
  const CtTag *dimtag = NULL;
  int dim;
  dBYTEORDER;

  CT_DEBUG(MAIN, (XSCLASS "::unpack_type(pTS=%p, pDecl=%p, dimension=%d, pBI=%p)",
           pTS, pDecl, dimension, pBI));

  if (pDecl && dimension == 0 && pDecl->tags)
  {
    const CtTag *format;

    hooks = find_tag(pDecl->tags, CBC_TAG_HOOKS);

    dimtag = find_tag(pDecl->tags, CBC_TAG_DIMENSION);

    if ((format = find_tag(pDecl->tags, CBC_TAG_FORMAT)) != NULL)
    {
      int size;
      u_32 flags = 0;

      assert(pBI == NULL);

      prepare_pack_format(aPACKARGS, pDecl, dimtag, &size, &flags);

      rv = unpack_format(aPACKARGS, format, size, flags);

      goto handle_unpack_hook;
    }

    SET_BYTEORDER(pDecl->tags);
  }

  assert(pDecl == NULL || pDecl->bitfield_flag == 0 || pBI != NULL);

  if (pDecl && pDecl->array_flag && dimension < (dim = LL_count(pDecl->ext.array)))
  {
    AV *a = newAV();
    Value *v = (Value *) LL_get(pDecl->ext.array, dimension);
    long i, s, avail;
    unsigned long pos;
    int size = pDecl->item_size;
    dTHR;
    dXCPT;

    assert(size > 0);
    assert(pBI == NULL);

    XCPT_TRY_START
    {
      while (dim-- > dimension + 1)
        size *= ((Value *) LL_get(pDecl->ext.array, dim))->iv;

      avail = ((PACKLEN - PACKPOS) + (size - 1)) / size;

      if (dimtag)
      {
        assert(dimension == 0);
        s = dimtag_eval(aTHX_ dimtag->any, avail, PACK->self, PACK->parent);
      }
      else if (v->flags & V_IS_UNDEF)
      {
        assert(dimension == 0);
        s = avail;
      }
      else
      {
        s = v->iv;
      }

      if (s < 0)
      {
        /* if we're unpacking a larger "thing" and run out of data, avail may become */
        /* negative and we need to protect against creating negatively sized arrays  */
        s = 0;
      }

      av_extend(a, s - 1);

      pos = PACKPOS;

      for (i = 0; i < s; ++i)
      {
        PACKPOS = pos + i * size;
        av_store(a, i, unpack_type(aPACKARGS, pTS, pDecl, dimension + 1, NULL));
      }
    }
    XCPT_TRY_END

    XCPT_CATCH
    {
      CT_DEBUG(MAIN, ("freeing av @ %p in unpack_type:%d", a, __LINE__));
      SvREFCNT_dec((SV *) a);
      XCPT_RETHROW;
    }

    rv = newRV_noinc((SV *) a);
  }
  else if (pDecl && pDecl->pointer_flag)
  {
    dTHR;
    dXCPT;

    assert(pBI == NULL);

    rv = unpack_pointer(aPACKARGS);

    XCPT_TRY_START
    {
      rv = hook_call_typespec(aTHX_ PACK->self, pTS, HOOKID_unpack_ptr, rv, 0);
    }
    XCPT_TRY_END

    XCPT_CATCH
    {
      CT_DEBUG(MAIN, ("freeing rv @ %p in unpack_type:%d", rv, __LINE__));
      SvREFCNT_dec(rv);
      XCPT_RETHROW;
    }
  }
  else if (pTS->tflags & T_TYPE)
  {
    Typedef *pTD = pTS->ptr;
    rv = unpack_type(aPACKARGS, pTD->pType, pTD->pDecl, 0, pBI);
  }
  else if (pTS->tflags & T_COMPOUND)
  {
    Struct *pStruct = pTS->ptr;

    assert(pBI == NULL);

    if (pStruct->declarations == NULL)
    {
      WARN_UNDEF_STRUCT(pStruct);
      rv = newSV(0);
    }
    else
      rv = unpack_struct(aPACKARGS, pTS->ptr, NULL);
  }
  else
  {
    CT_DEBUG(MAIN, ("GET '%s' @ %lu", pDecl ? pDecl->identifier : "", PACKPOS));

    if (pTS->tflags & T_ENUM)
      rv = unpack_enum(aPACKARGS, pTS->ptr, pBI);
    else
      rv = unpack_basic(aPACKARGS, pTS->tflags, pBI);
  }

  assert(rv != NULL);

  RESTORE_BYTEORDER;

handle_unpack_hook:

  if (hooks)
  {
    dTHR;
    dXCPT;

    assert(pDecl != NULL);

    XCPT_TRY_START
    {
      rv = hook_call(aTHX_ PACK->self, NULL, pDecl->identifier,
                     hooks->any, HOOKID_unpack, rv, 0);
    }
    XCPT_TRY_END

    XCPT_CATCH
    {
      CT_DEBUG(MAIN, ("freeing rv @ %p in unpack_type:%d", rv, __LINE__));
      SvREFCNT_dec(rv);
      XCPT_RETHROW;
    }
  }

  return rv;
}

/*******************************************************************************
*
*   ROUTINE: hook_call_typespec
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

static SV *hook_call_typespec(pTHX_ SV *self, const TypeSpec *pTS,
                              enum HookId hook_id, SV *in, int mortal)
{
  const char *id, *pre;
  CtTagList tags = NULL;

  if (pTS->tflags & T_TYPE)
  {
    const Typedef *p = pTS->ptr;

    id   = p->pDecl->identifier;
    tags = p->pDecl->tags;
    pre  = NULL;
  }
  else if (pTS->tflags & T_COMPOUND)
  {
    const Struct *p = pTS->ptr;

    id   = p->identifier;
    tags = p->tags;
    pre  = pTS->tflags & T_STRUCT ? "struct " : "union ";
  }
  else if (pTS->tflags & T_ENUM)
  {
    const EnumSpecifier *p = pTS->ptr;

    id   = p->identifier;
    tags = p->tags;
    pre  = "enum ";
  }

  if (tags)
  {
    const CtTag *hooks = find_tag(tags, CBC_TAG_HOOKS);

    if (hooks)
      return hook_call(aTHX_ self, pre, id, hooks->any, hook_id, in, mortal);
  }

  return in;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: pk_create
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

PackHandle pk_create(const CBC *THIS, SV *self)
{
  PackHandle hdl;
  Newz(0, hdl, 1, struct PackInfo);
  hdl->THIS = THIS;
  hdl->self = self;
  hdl->parent = NULL;
  return hdl;
}

/*******************************************************************************
*
*   ROUTINE: pk_set_type
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

void pk_set_type(PackHandle hdl, const char *type)
{
  IDLIST_INIT(&hdl->idl);
  IDLIST_PUSH(&hdl->idl, ID);
  IDLIST_SET_ID(&hdl->idl, type);
}

/*******************************************************************************
*
*   ROUTINE: pk_set_buffer
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

void pk_set_buffer(PackHandle hdl, SV *bufsv, char *buffer, unsigned long buflen)
{
  hdl->bufsv = bufsv;
  hdl->buf.buffer = buffer;
  hdl->buf.length = buflen;
}

/*******************************************************************************
*
*   ROUTINE: pk_set_buffer_pos
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

void pk_set_buffer_pos(PackHandle hdl, unsigned long pos)
{
  hdl->buf.pos = pos;
}

/*******************************************************************************
*
*   ROUTINE: pk_delete
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

void pk_delete(PackHandle hdl)
{
  IDLIST_FREE(&hdl->idl);
  Safefree(hdl);
}

/*******************************************************************************
*
*   ROUTINE: pk_pack
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

void pk_pack(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension, SV *sv)
{
  PACK->order = PCONFIG->layout.byte_order;
  pack_type(aPACKARGS, pTS, pDecl, dimension, NULL, sv);
}

/*******************************************************************************
*
*   ROUTINE: pk_unpack
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

SV *pk_unpack(pPACKARGS, const TypeSpec *pTS, const Declarator *pDecl, int dimension)
{
  PACK->order = PCONFIG->layout.byte_order;
  return unpack_type(aPACKARGS, pTS, pDecl, dimension, NULL);
}

