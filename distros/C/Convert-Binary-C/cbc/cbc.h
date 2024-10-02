/*******************************************************************************
*
* HEADER: cbc.h
*
********************************************************************************
*
* DESCRIPTION: C::B::C common defines
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _CBC_CBC_H
#define _CBC_CBC_H

/*===== GLOBAL INCLUDES ======================================================*/


/*===== LOCAL INCLUDES =======================================================*/

#include "ctlib/arch.h"
#include "ctlib/ctdebug.h"
#include "ctlib/ctparse.h"
#include "ctlib/cttype.h"

#include "cbc/basic.h"


/*===== DEFINES ==============================================================*/

#define XSCLASS "Convert::Binary::C"

#define ARGTYPE_PACKAGE "Convert::Binary::C::ARGTYPE"

/*-------------------------------------*/
/* some quick paranoid checks first... */
/*-------------------------------------*/

#if (defined I8SIZE && I8SIZE != 1) || \
    (defined U8SIZE && U8SIZE != 1)
#error "Your I8/U8 doesn't seem to have 8 bits..."
#endif

#if (defined I16SIZE && I16SIZE != 2) || \
    (defined U16SIZE && U16SIZE != 2)
#error "Your I16/U16 doesn't seem to have 16 bits..."
#endif

#if (defined I32SIZE && I32SIZE != 4) || \
    (defined U32SIZE && U32SIZE != 4)
#error "Your I32/U32 doesn't seem to have 32 bits..."
#endif

/*---------------*/
/* some defaults */
/*---------------*/

#ifndef CBC_DEFAULT_PTR_SIZE
#define CBC_DEFAULT_PTR_SIZE    CTLIB_POINTER_SIZE
#else
#if     CBC_DEFAULT_PTR_SIZE != 1 && \
        CBC_DEFAULT_PTR_SIZE != 2 && \
        CBC_DEFAULT_PTR_SIZE != 4 && \
        CBC_DEFAULT_PTR_SIZE != 8
#error "CBC_DEFAULT_PTR_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_ENUM_SIZE
#define CBC_DEFAULT_ENUM_SIZE    sizeof( int )
#else
#if     CBC_DEFAULT_ENUM_SIZE != 0 && \
        CBC_DEFAULT_ENUM_SIZE != 1 && \
        CBC_DEFAULT_ENUM_SIZE != 2 && \
        CBC_DEFAULT_ENUM_SIZE != 4 && \
        CBC_DEFAULT_ENUM_SIZE != 8
#error "CBC_DEFAULT_ENUM_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_INT_SIZE
#define CBC_DEFAULT_INT_SIZE    CTLIB_int_SIZE
#else
#if     CBC_DEFAULT_INT_SIZE != 1 && \
        CBC_DEFAULT_INT_SIZE != 2 && \
        CBC_DEFAULT_INT_SIZE != 4 && \
        CBC_DEFAULT_INT_SIZE != 8
#error "CBC_DEFAULT_INT_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_CHAR_SIZE
#define CBC_DEFAULT_CHAR_SIZE    CTLIB_char_SIZE
#else
#if     CBC_DEFAULT_CHAR_SIZE != 1 && \
        CBC_DEFAULT_CHAR_SIZE != 2 && \
        CBC_DEFAULT_CHAR_SIZE != 4 && \
        CBC_DEFAULT_CHAR_SIZE != 8
#error "CBC_DEFAULT_CHAR_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_SHORT_SIZE
#define CBC_DEFAULT_SHORT_SIZE    CTLIB_short_SIZE
#else
#if     CBC_DEFAULT_SHORT_SIZE != 1 && \
        CBC_DEFAULT_SHORT_SIZE != 2 && \
        CBC_DEFAULT_SHORT_SIZE != 4 && \
        CBC_DEFAULT_SHORT_SIZE != 8
#error "CBC_DEFAULT_SHORT_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_LONG_SIZE
#define CBC_DEFAULT_LONG_SIZE    CTLIB_long_SIZE
#else
#if     CBC_DEFAULT_LONG_SIZE != 1 && \
        CBC_DEFAULT_LONG_SIZE != 2 && \
        CBC_DEFAULT_LONG_SIZE != 4 && \
        CBC_DEFAULT_LONG_SIZE != 8
#error "CBC_DEFAULT_LONG_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_LONG_LONG_SIZE
#define CBC_DEFAULT_LONG_LONG_SIZE    CTLIB_long_long_SIZE
#else
#if     CBC_DEFAULT_LONG_LONG_SIZE != 1 && \
        CBC_DEFAULT_LONG_LONG_SIZE != 2 && \
        CBC_DEFAULT_LONG_LONG_SIZE != 4 && \
        CBC_DEFAULT_LONG_LONG_SIZE != 8
#error "CBC_DEFAULT_LONG_LONG_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_FLOAT_SIZE
#define CBC_DEFAULT_FLOAT_SIZE    CTLIB_float_SIZE
#else
#if     CBC_DEFAULT_FLOAT_SIZE != 1  && \
        CBC_DEFAULT_FLOAT_SIZE != 2  && \
        CBC_DEFAULT_FLOAT_SIZE != 4  && \
        CBC_DEFAULT_FLOAT_SIZE != 8  && \
        CBC_DEFAULT_FLOAT_SIZE != 12 && \
        CBC_DEFAULT_FLOAT_SIZE != 16
#error "CBC_DEFAULT_FLOAT_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_DOUBLE_SIZE
#define CBC_DEFAULT_DOUBLE_SIZE    CTLIB_double_SIZE
#else
#if     CBC_DEFAULT_DOUBLE_SIZE != 1  && \
        CBC_DEFAULT_DOUBLE_SIZE != 2  && \
        CBC_DEFAULT_DOUBLE_SIZE != 4  && \
        CBC_DEFAULT_DOUBLE_SIZE != 8  && \
        CBC_DEFAULT_DOUBLE_SIZE != 12 && \
        CBC_DEFAULT_DOUBLE_SIZE != 16
#error "CBC_DEFAULT_DOUBLE_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_LONG_DOUBLE_SIZE
#define CBC_DEFAULT_LONG_DOUBLE_SIZE    CTLIB_long_double_SIZE
#else
#if     CBC_DEFAULT_LONG_DOUBLE_SIZE != 1  && \
        CBC_DEFAULT_LONG_DOUBLE_SIZE != 2  && \
        CBC_DEFAULT_LONG_DOUBLE_SIZE != 4  && \
        CBC_DEFAULT_LONG_DOUBLE_SIZE != 8  && \
        CBC_DEFAULT_LONG_DOUBLE_SIZE != 12 && \
        CBC_DEFAULT_LONG_DOUBLE_SIZE != 16
#error "CBC_DEFAULT_LONG_DOUBLE_SIZE is invalid!"
#endif
#endif

#ifndef CBC_DEFAULT_ALIGNMENT
#define CBC_DEFAULT_ALIGNMENT    1
#elif   CBC_DEFAULT_ALIGNMENT != 1  && \
        CBC_DEFAULT_ALIGNMENT != 2  && \
        CBC_DEFAULT_ALIGNMENT != 4  && \
        CBC_DEFAULT_ALIGNMENT != 8  && \
        CBC_DEFAULT_ALIGNMENT != 16
#error "CBC_DEFAULT_ALIGNMENT is invalid!"
#endif

#ifndef CBC_DEFAULT_COMPOUND_ALIGNMENT
#define CBC_DEFAULT_COMPOUND_ALIGNMENT    1
#elif   CBC_DEFAULT_COMPOUND_ALIGNMENT != 1  && \
        CBC_DEFAULT_COMPOUND_ALIGNMENT != 2  && \
        CBC_DEFAULT_COMPOUND_ALIGNMENT != 4  && \
        CBC_DEFAULT_COMPOUND_ALIGNMENT != 8  && \
        CBC_DEFAULT_COMPOUND_ALIGNMENT != 16
#error "CBC_DEFAULT_COMPOUND_ALIGNMENT is invalid!"
#endif

#ifndef CBC_DEFAULT_ENUMTYPE
#define CBC_DEFAULT_ENUMTYPE   ET_INTEGER
#endif

#if ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_BIG_ENDIAN
#define CBC_NATIVE_BYTEORDER   CBO_BIG_ENDIAN
#elif ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_LITTLE_ENDIAN
#define CBC_NATIVE_BYTEORDER   CBO_LITTLE_ENDIAN
#else
#error "unknown native byte order"
#endif

#ifndef CBC_DEFAULT_BYTEORDER
#define CBC_DEFAULT_BYTEORDER  CBC_NATIVE_BYTEORDER
#endif

/*--------------------------------------*/
/* macros for different checks/warnings */
/*--------------------------------------*/

#if defined G_WARN_ON && defined G_WARN_ALL_ON
#define PERL_WARNINGS_ON (PL_dowarn & (G_WARN_ON | G_WARN_ALL_ON))
#else
#define PERL_WARNINGS_ON  PL_dowarn
#endif

#define WARN(args) STMT_START { if (PERL_WARNINGS_ON) Perl_warn args; } STMT_END

#define WARN2(args) STMT_START { if (PERL_WARNINGS_ON && THIS->cfg.issue_warnings) Perl_warn args; } STMT_END

#define WARN_UNSAFE(type) \
          WARN((aTHX_ "Unsafe values used in %s('%s')", method, type))

#define WARN_FLAGS(type, flags)                                                \
          STMT_START {                                                         \
            if ((flags) & T_UNSAFE_VAL)                                        \
              WARN_UNSAFE(type);                                               \
          } STMT_END

#define CROAK_UNDEF_STRUCT(ptr)                                                \
          Perl_croak(aTHX_ "Got no definition for '%s %s'",                    \
                           (ptr)->tflags & T_UNION ? "union" : "struct",       \
                           (ptr)->identifier)

#define WARN_UNDEF_STRUCT(ptr)                                                 \
          WARN((aTHX_ "Got no definition for '%s %s'",                         \
                      (ptr)->tflags & T_UNION ? "union" : "struct",            \
                      (ptr)->identifier))

/*----------------------------*/
/* checks if an SV is defined */
/*----------------------------*/

#define DEFINED(sv) ((sv) != NULL && SvOK(sv))

/*----------------------------------*/
/* avoid warnings with older perl's */
/*----------------------------------*/

#if PERL_REVISION == 5 && PERL_VERSION < 6
# define CONST_CHAR(x) ((char *)(x))
#else
# define CONST_CHAR(x) (x)
#endif

/*--------------------------------------------------*/
/* macros to create SV's/HV's with constant strings */
/*--------------------------------------------------*/

#define NEW_SV_PV_CONST(str) \
          newSVpvn(str, sizeof(str)/sizeof(char)-1)

#define HV_STORE_CONST(hash, key, value)                                       \
        STMT_START {                                                           \
          SV *_val = value;                                                    \
          if (hv_store(hash, key, sizeof(key)/sizeof(char)-1, _val, 0) == NULL)\
            SvREFCNT_dec(_val);                                                \
        } STMT_END

/*-------------------------*/
/* get the size of an enum */
/*-------------------------*/

#define GET_ENUM_SIZE(pCfg, pES)                                               \
          ((pCfg)->layout.enum_size > 0                                        \
            ? (unsigned) (pCfg)->layout.enum_size                              \
            : (pES)->sizes[-(pCfg)->layout.enum_size]) 

/*------------------------------------------------*/
/* this is needed quite often for unnamed structs */
/*------------------------------------------------*/

#define FOLLOW_AND_CHECK_TSPTR(pTS)                                            \
        STMT_START {                                                           \
          if ((pTS)->tflags & T_TYPE)                                          \
          {                                                                    \
            Typedef *_pT = (Typedef *) (pTS)->ptr;                             \
            for(;;)                                                            \
            {                                                                  \
              if (_pT && _pT->pType->tflags & T_TYPE                           \
                      && _pT->pDecl->pointer_flag == 0                         \
                      && _pT->pDecl->array_flag == 0)                          \
                _pT = (Typedef *) _pT->pType->ptr;                             \
              else                                                             \
                break;                                                         \
            }                                                                  \
            (pTS) = _pT->pType;                                                \
          }                                                                    \
                                                                               \
          if (((pTS)->tflags & T_COMPOUND) == 0)                               \
            fatal("Unnamed member was not struct or union (type=0x%08X) "      \
                  "in %s line %d", (pTS)->tflags, __FILE__, __LINE__);         \
                                                                               \
          if ((pTS)->ptr == NULL)                                              \
            fatal("Type pointer to struct/union was NULL in %s line %d",       \
                  __FILE__, __LINE__);                                         \
        } STMT_END


/*===== TYPEDEFS =============================================================*/

typedef struct {

  CParseConfig  cfg;
  CParseInfo    cpi;

  enum {
    ET_INTEGER, ET_STRING, ET_BOTH
  }             enumType;

  /* boolean options */
  unsigned      order_members      : 1;

  const char   *ixhash;
  HV           *hv;
  BasicTypes    basic;

} CBC;


/*===== FUNCTION PROTOTYPES ==================================================*/

#endif
