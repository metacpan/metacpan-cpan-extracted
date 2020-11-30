/*******************************************************************************
*
* MODULE: C.xs
*
********************************************************************************
*
* DESCRIPTION: XS Interface for Convert::Binary::C Perl extension module
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
********************************************************************************
*
*         "All you have to do is to decide what you are going to do
*          with the time that is given to you."     -- Gandalf
*
*******************************************************************************/


/*===== GLOBAL INCLUDES ======================================================*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

#define NO_XSLOCKS
#include <XSUB.h>

#define NEED_newRV_noinc_GLOBAL
#define NEED_sv_2pv_nolen_GLOBAL
#include "ppport.h"


/*===== LOCAL INCLUDES =======================================================*/

#include "util/ccattr.h"
#include "util/list.h"
#include "util/hash.h"
#include "ctlib/cterror.h"
#include "ctlib/fileinfo.h"
#include "ctlib/parser.h"

#include "cbc/cbc.h"
#include "cbc/debug.h"
#include "cbc/hook.h"
#include "cbc/init.h"
#include "cbc/macros.h"
#include "cbc/member.h"
#include "cbc/object.h"
#include "cbc/option.h"
#include "cbc/pack.h"
#include "cbc/sourcify.h"
#include "cbc/tag.h"
#include "cbc/type.h"
#include "cbc/typeinfo.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

#ifndef PerlEnv_getenv
#  define PerlEnv_getenv getenv
#endif

#ifdef CBC_DEBUGGING

#define DBG_CTXT_FMT "%s"

#define DBG_CTXT_ARG (GIMME_V == G_VOID   ? "0=" : \
                     (GIMME_V == G_SCALAR ? "$=" : \
                     (GIMME_V == G_ARRAY  ? "@=" : \
                                            "?="   \
                     )))

#endif

#define CBC_METHOD(name)         const char * const method PERL_UNUSED_DECL = #name
#define CBC_METHOD_VAR           const char * method PERL_UNUSED_DECL = ""
#define CBC_METHOD_SET(string)   method = string

#define CT_DEBUG_METHOD                                                        \
          CT_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s", DBG_CTXT_ARG, method))

#define CT_DEBUG_METHOD1(fmt, arg1)                                            \
          CT_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s( " fmt " )",              \
                          DBG_CTXT_ARG, method, arg1))

#define CT_DEBUG_METHOD2(fmt, arg1, arg2)                                      \
          CT_DEBUG(MAIN, (DBG_CTXT_FMT XSCLASS "::%s( " fmt " )",              \
                          DBG_CTXT_ARG, method, arg1, arg2) )

#define CHECK_PARSE_DATA                                                       \
          STMT_START {                                                         \
            if (!THIS->cpi.available)                                          \
              Perl_croak(aTHX_ "Call to %s without parse data", method);       \
          } STMT_END

#define NEED_PARSE_DATA                                                        \
          STMT_START {                                                         \
            if (THIS->cpi.available)                                           \
            {                                                                  \
              if (!THIS->cpi.ready)                                            \
                update_parse_info(&THIS->cpi, &THIS->cfg);                     \
              assert(THIS->cpi.ready);                                         \
            }                                                                  \
          } STMT_END

#define WARN_VOID_CONTEXT                                                      \
            WARN((aTHX_ "Useless use of %s in void context", method))

#define CHECK_VOID_CONTEXT                                                     \
          STMT_START {                                                         \
            if (GIMME_V == G_VOID)                                             \
            {                                                                  \
              WARN_VOID_CONTEXT;                                               \
              XSRETURN_EMPTY;                                                  \
            }                                                                  \
          } STMT_END


/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static void *ct_newstr(void);
static void ct_scatf(void *p, const char *f, ...);
static void ct_vscatf(void *p, const char *f, va_list *l);
static const char *ct_cstring(void *p, size_t *len);
static void ct_fatal(void *p) __attribute__((__noreturn__));

static void handle_parse_errors(pTHX_ LinkedList stack);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

static int gs_DisableParser;
static int gs_OrderMembers;


/*===== GLOBAL FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: CBC_malloc, CBC_calloc, CBC_realloc, CBC_free
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Memory allocation routines for ucpp and util libs.
*
*******************************************************************************/

void *CBC_malloc(size_t size)
{
  void *p;
  New(0, p, size, char);
  return p;
}

void *CBC_calloc(size_t count, size_t size)
{
  void *p;
  Newz(0, p, count*size, char);
  return p;
}

void *CBC_realloc(void *p, size_t size)
{
  Renew(p, size, char);
  return p;
}

void CBC_free(void *p)
{
  Safefree(p);
}


/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: ct_*
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: These functions are used to build arbitrary strings within the
*              ctlib routines and to provide an interface to perl's warn().
*
*******************************************************************************/

static void *ct_newstr(void)
{
  dTHX;
  return (void *) newSVpvn("", 0);
}

static void ct_destroy(void *p)
{
  dTHX;
  SvREFCNT_dec((SV*)p);
}

static void ct_scatf(void *p, const char *f, ...)
{
  dTHX;
  va_list l;
  va_start(l, f);
  sv_vcatpvf((SV*)p, f, &l);
  va_end(l);
}

static void ct_vscatf(void *p, const char *f, va_list *l)
{
  dTHX;
  sv_vcatpvf((SV*)p, f, l);
}

static const char *ct_cstring(void *p, size_t *len)
{
  dTHX;
  STRLEN l;
  const char *s = SvPV((SV*)p, l);
  if (len)
    *len = (size_t) l;
  return s;
}

static void ct_fatal(void *p)
{
  dTHX;
  sv_2mortal((SV*)p);
  fatal("%s", SvPV_nolen((SV*)p));
}

/*******************************************************************************
*
*   ROUTINE: handle_parse_errors
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2003
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

static void handle_parse_errors(pTHX_ LinkedList stack)
{
  ListIterator ei;
  CTLibError *perr;

  LL_foreach(perr, ei, stack)
  {
    switch (perr->severity)
    {
      case CTES_ERROR:
        Perl_croak(aTHX_ "%s", perr->string);
        break;

      case CTES_WARNING:
        if( PERL_WARNINGS_ON )
          Perl_warn(aTHX_ "%s", perr->string);
        break;

      default:
        Perl_croak(aTHX_ "unknown severity [%d] for error: %s",
                         perr->severity, perr->string);
    }
  }
}


/*===== XS FUNCTIONS =========================================================*/

MODULE = Convert::Binary::C    PACKAGE = Convert::Binary::C

PROTOTYPES: ENABLE

INCLUDE: xsubs/cbc.xs

INCLUDE: xsubs/clone.xs

INCLUDE: xsubs/clean.xs

INCLUDE: xsubs/configure.xs

INCLUDE: xsubs/include.xs

INCLUDE: xsubs/parse.xs

INCLUDE: xsubs/def.xs

INCLUDE: xsubs/pack.xs

INCLUDE: xsubs/sizeof.xs

INCLUDE: xsubs/typeof.xs

INCLUDE: xsubs/offsetof.xs

INCLUDE: xsubs/member.xs

INCLUDE: xsubs/tag.xs

INCLUDE: xsubs/enum.xs

INCLUDE: xsubs/compound.xs

INCLUDE: xsubs/typedef.xs

INCLUDE: xsubs/sourcify.xs

INCLUDE: xsubs/initializer.xs

INCLUDE: xsubs/dependencies.xs

INCLUDE: xsubs/defined.xs

INCLUDE: xsubs/macro.xs

INCLUDE: xsubs/arg.xs

INCLUDE: xsubs/feature.xs

INCLUDE: xsubs/native.xs


################################################################################
#
#   FUNCTION: import
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################
#
# DESCRIPTION: Handle global features, currently only debugging support.
#
#   ARGUMENTS:
#
#     RETURNS:
#
################################################################################

#define WARN_NO_DEBUGGING  0x00000001

void
import(...)
  PREINIT:
    int i;
    U32 wflags;

  CODE:
    wflags = 0;

    if (items % 2 == 0)
      Perl_croak(aTHX_ "You must pass an even number of module arguments");
    else
    {
      for (i = 1; i < items; i += 2)
      {
        const char *opt = SvPV_nolen(ST(i));
#ifdef CBC_DEBUGGING
        const char *arg = SvPV_nolen(ST(i+1));
#endif
        if (strEQ(opt, "debug"))
        {
#ifdef CBC_DEBUGGING
          set_debug_options(aTHX_ arg);
#else
          wflags |= WARN_NO_DEBUGGING;
#endif
        }
        else if (strEQ(opt, "debugfile"))
        {
#ifdef CBC_DEBUGGING
          set_debug_file(aTHX_ arg);
#else
          wflags |= WARN_NO_DEBUGGING;
#endif
        }
        else
          Perl_croak(aTHX_ "Invalid module option '%s'", opt);
      }

      if (wflags & WARN_NO_DEBUGGING)
        Perl_warn(aTHX_ XSCLASS " not compiled with debugging support");
    }

#undef WARN_NO_DEBUGGING


################################################################################
#
#   FUNCTION: __DUMP__
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################
#
# DESCRIPTION: Internal function used for reference count checks.
#
#   ARGUMENTS:
#
#     RETURNS:
#
################################################################################

SV *
__DUMP__(val)
  SV *val

  CODE:
    RETVAL = newSVpvn("", 0);
#ifdef CBC_DEBUGGING
    dump_sv(aTHX_ RETVAL, 0, val);
#else
    (void) val;
    Perl_croak(aTHX_ "__DUMP__ not enabled in non-debug version");
#endif

  OUTPUT:
    RETVAL


################################################################################
#
#   BOOTCODE
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################

BOOT:
  {
    const char *str;
    PrintFunctions f;
    f.newstr   = ct_newstr;
    f.destroy  = ct_destroy;
    f.scatf    = ct_scatf;
    f.vscatf   = ct_vscatf;
    f.cstring  = ct_cstring;
    f.fatalerr = ct_fatal;
    set_print_functions(&f);
#ifdef CBC_DEBUGGING
    init_debugging(aTHX);
    if ((str = PerlEnv_getenv("CBC_DEBUG_OPT")) != NULL)
      set_debug_options(aTHX_ str);
    if ((str = PerlEnv_getenv("CBC_DEBUG_FILE")) != NULL)
      set_debug_file(aTHX_ str);
#endif
    gs_DisableParser = 0;
    if ((str = PerlEnv_getenv("CBC_DISABLE_PARSER")) != NULL)
      gs_DisableParser = atoi(str);
    gs_OrderMembers = 0;
    if ((str = PerlEnv_getenv("CBC_ORDER_MEMBERS")) != NULL)
    {
      if (isDIGIT(str[0]))
        gs_OrderMembers = atoi(str);
      else if (isALPHA(str[0]))
      {
        gs_OrderMembers = 1;
        set_preferred_indexed_hash_module(strdup(str));
      }
    }
  }
