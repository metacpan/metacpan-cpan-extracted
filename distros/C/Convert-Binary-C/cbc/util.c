/*******************************************************************************
*
* MODULE: util.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C utilities
*
********************************************************************************
*
* Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
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

#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static int load_indexed_hash_module_ex(pTHX_ CBC *THIS, const char **modlist, int num);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

#define NUM_IX_HASH_MODS (sizeof(gs_IxHashMods)/sizeof(gs_IxHashMods[0]))
static const char *gs_IxHashMods[] = {
  NULL, /* custom preferred module */
  "Tie::Hash::Indexed",
  "Hash::Ordered",
  "Tie::IxHash"
};


/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: load_indexed_hash_module_ex
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2003
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

static int load_indexed_hash_module_ex(pTHX_ CBC *THIS, const char **modlist, int num)
{
  const char *p = NULL;
  int i;

  if (THIS->ixhash != NULL)
  {
    /* a module has already been loaded */
    return 1;
  }

  for (i = 0; i < num; i++)
  {
    if (modlist[i])
    {
      SV *sv = newSVpvn("require ", 8);
      sv_catpv(sv, CONST_CHAR(modlist[i]));
      CT_DEBUG(MAIN, ("trying to require \"%s\"", modlist[i]));
      (void) eval_sv(sv, G_DISCARD);
      SvREFCNT_dec(sv);
      if ((sv = get_sv("@", 0)) != NULL && strEQ(SvPV_nolen(sv), ""))
      {
        p = modlist[i];
        break;
      }
      if (i == 0)
      {
        Perl_warn(aTHX_ "Couldn't load %s for member ordering, "
                        "trying default modules", modlist[i]);
      }
      CT_DEBUG(MAIN, ("failed: \"%s\"", sv ? SvPV_nolen(sv) : "[NULL]"));
    }
  }

  if (p == NULL)
  {
    SV *sv = newSVpvn("", 0);

    for (i = 1; i < num; i++)
    {
      if (i > 1)
      {
        if (i == num-1)
          sv_catpvn(sv, " or ", 4);
        else
          sv_catpvn(sv, ", ", 2);
      }
      sv_catpv(sv, CONST_CHAR(modlist[i]));
    }

    Perl_warn(aTHX_ "Couldn't load a module for member ordering "
                    "(consider installing %s)", SvPV_nolen(sv));
    return 0;
  }

  CT_DEBUG(MAIN, ("using \"%s\" for member ordering", p));

  THIS->ixhash = p;

  return 1;
}


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: fatal
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Write fatal error to standard error and abort().
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

void fatal(const char *f, ...)
{
  dTHX;
  va_list l;
  SV *sv = newSVpvn("", 0);

  va_start(l, f);

  sv_catpv(sv,
  "============================================\n"
  "     FATAL ERROR in " XSCLASS "!\n"
  "--------------------------------------------\n"
  );

  sv_vcatpvf(sv, f, &l);

  sv_catpv(sv,
  "\n"
  "--------------------------------------------\n"
  "  please report this error to mhx@cpan.org\n"
  "============================================\n"
  );

  va_end(l);

  fprintf(stderr, "%s", SvPVX(sv));

  SvREFCNT_dec(sv);

  abort();
}

/*******************************************************************************
*
*   ROUTINE: newHV_indexed
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2003
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

HV *newHV_indexed(pTHX_ const CBC *THIS)
{
  dSP;
  HV *hv, *stash;
  GV *gv;
  SV *sv;
  int count;

  hv = newHV();

  sv = newSVpv(CONST_CHAR(THIS->ixhash), 0);
  stash = gv_stashpv(CONST_CHAR(THIS->ixhash), 0);
  gv = gv_fetchmethod(stash, "TIEHASH");
 
  ENTER;
  SAVETMPS;
 
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(sv));
  PUTBACK;
 
  count = call_sv((SV*)GvCV(gv), G_SCALAR);

  SPAGAIN;

  if (count != 1)
    fatal("%s::TIEHASH returned %d elements instead of 1",
          THIS->ixhash, count);
 
  sv = POPs;
 
  PUTBACK;

  hv_magic(hv, (GV *)sv, PERL_MAGIC_tied);
 
  FREETMPS;
  LEAVE;

  return hv;
}

/*******************************************************************************
*
*   ROUTINE: croak_gti
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
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

void croak_gti(pTHX_ ErrorGTI error, const char *name, int warnOnly)
{
  char *errstr = NULL;

  switch (error)
  {
    case GTI_NO_ERROR:
      return;

    case GTI_NO_STRUCT_DECL:
      errstr = "Got no struct declarations";
      break;

    default:
      if( name )
        fatal("Unknown error %d in resolution of '%s'", error, name);
      else
        fatal("Unknown error %d in resolution of typedef", error);
      break;
  }

  if (warnOnly)
  {
    if (name)
      WARN((aTHX_ "%s in resolution of '%s'", errstr, name));
    else
      WARN((aTHX_ "%s in resolution of typedef", errstr));
  }
  else
  {
    if (name)
      Perl_croak(aTHX_ "%s in resolution of '%s'", errstr, name);
    else
      Perl_croak(aTHX_ "%s in resolution of typedef", errstr);
  }
}

/*******************************************************************************
*
*   ROUTINE: get_basic_type_spec_string
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Sep 2002
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

void get_basic_type_spec_string(pTHX_ SV **sv, u_32 flags)
{
  struct { u_32 flag; const char *str; } *pSpec, spec[] = {
    {T_SIGNED,   "signed"  },
    {T_UNSIGNED, "unsigned"},
    {T_SHORT,    "short"   },
    {T_LONGLONG, "long"    },
    {T_LONG,     "long"    },
    {T_VOID,     "void"    },
    {T_CHAR,     "char"    },
    {T_INT ,     "int"     },
    {T_FLOAT ,   "float"   },
    {T_DOUBLE ,  "double"  },
    {0,          NULL      }
  };
  int first = 1;

  CT_DEBUG(MAIN, (XSCLASS "::get_basic_type_spec_string( sv=%p, flags=0x%08lX )",
                  sv, (unsigned long) flags));

  for (pSpec = spec; pSpec->flag; ++pSpec)
  {
    if (pSpec->flag & flags)
    {
      if (*sv)
        sv_catpvf(*sv, first ? "%s" : " %s", pSpec->str);
      else
        *sv = newSVpv(CONST_CHAR(pSpec->str), 0);

      first = 0;
    }
  }
}

/*******************************************************************************
*
*   ROUTINE: add_indent
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

void add_indent(pTHX_ SV *s, int level)
{
#define MAXINDENT 16
  static const char tab[MAXINDENT] = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";

#ifndef CBC_DONT_CLAMP_TO_MAXINDENT
  if (level > MAXINDENT)
    level = MAXINDENT;
#else
  while (level > MAXINDENT)
  {
    sv_catpvn( s, tab, MAXINDENT );
    level -= MAXINDENT;
  }
#endif

  sv_catpvn(s, CONST_CHAR(tab), level);
#undef MAXINDENT
}

/*******************************************************************************
*
*   ROUTINE: load_indexed_hash_module
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2003
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

int load_indexed_hash_module(pTHX_ CBC *THIS)
{
  return load_indexed_hash_module_ex(aTHX_ THIS, gs_IxHashMods, NUM_IX_HASH_MODS);
}

/*******************************************************************************
*
*   ROUTINE: set_preferred_indexed_hash_module
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

void set_preferred_indexed_hash_module(const char *module)
{
  gs_IxHashMods[0] = module;
}

/*******************************************************************************
*
*   ROUTINE: string_new
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

char *string_new(const char *str)
{
  char *cpy = NULL;

  if (str != NULL)
  {
    size_t len = strlen(str) + 1;
    New(0, cpy, len, char);
    Copy(str, cpy, len, char);
  }

  return cpy;
}

/*******************************************************************************
*
*   ROUTINE: string_new_fromSV
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2002
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

char *string_new_fromSV(pTHX_ SV *sv)
{
  char *cpy = NULL;

  if (sv != NULL)
  {
    char  *str;
    STRLEN len;

    str = SvPV(sv, len);
    len++;

    New(0, cpy, len, char);
    Copy(str, cpy, len, char);
  }

  return cpy;
}

/*******************************************************************************
*
*   ROUTINE: string_delete
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: May 2002
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

void string_delete(char *str)
{
  Safefree(str);
}

/*******************************************************************************
*
*   ROUTINE: clone_string_list
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

LinkedList clone_string_list(LinkedList list)
{
  ListIterator li;
  const char *str;
  LinkedList clone;

  clone = LL_new();

  LL_foreach(str, li, list)
    LL_push(clone, string_new(str));

  return clone;
}

/*******************************************************************************
*
*   ROUTINE: dump_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Dumps an SV similar to (but a lot simpler than) Devel::Peek's
*              Dump function, but instead of writing to the debug output, it
*              returns a Perl string that can be used for further processing.
*              Currently, the only useful information is the reference count.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

#define DUMP_INDENT                       \
        STMT_START {                      \
          if (level > 0)                  \
            add_indent(aTHX_ buf, level); \
        } STMT_END

void dump_sv(pTHX_ SV *buf, int level, SV *sv)
{
  char *str;
  svtype type = SvTYPE(sv);

  if (SvROK(sv))
  {
    str = "RV";
  }
  else
  {
    switch (type)
    {
      case SVt_NULL: str = "NULL"; break;
      case SVt_IV:   str = "IV";   break;
      case SVt_NV:   str = "NV";   break;
      case SVt_PV:   str = "PV";   break;
      case SVt_PVIV: str = "PVIV"; break;
      case SVt_PVNV: str = "PVNV"; break;
      case SVt_PVMG: str = "PVMG"; break;
      case SVt_PVLV: str = "PVLV"; break;
      case SVt_PVAV: str = "PVAV"; break;
      case SVt_PVHV: str = "PVHV"; break;
      case SVt_PVCV: str = "PVCV"; break;
      case SVt_PVGV: str = "PVGV"; break;
      case SVt_PVFM: str = "PVFM"; break;
      case SVt_PVIO: str = "PVIO"; break;
      default      : str = "UNKNOWN";
    }
  }

  CT_DEBUG(MAIN, (XSCLASS "::dump_sv( level=%d, sv=\"%s\" )", level, str));

#ifndef CBC_USE_LESS_MEMORY
  /*
   *  This speeds up dump at the cost of memory,
   *  as it prevents a lot of realloc()s.
   *  Actually, it was only inserted to make valgrind
   *  run at acceptable speed... ;-)
   */
  {
    STRLEN cur, len;
    cur = SvCUR(buf) + 64;      /* estimated new string length  */
    if (cur > 1024)             /* do nothing for small strings */
    {
      len = SvLEN(buf);         /* buffer size                  */
      if (cur > len)
      {
        len = (len/1024)*2048;  /* double buffer size           */
        (void) sv_grow(buf, len);
      }
    }
  }
#endif

  DUMP_INDENT; level++;
  sv_catpvf(buf, "SV = %s @ %p (REFCNT = %lu)\n",
                 str, sv, (unsigned long) SvREFCNT(sv));

  if (SvROK(sv))
  {
    dump_sv(aTHX_ buf, level, SvRV(sv));
    return;
  }

  switch (type)
  {
    case SVt_PVAV:
      {
        AV *av = (AV *) sv;
        I32 c, n;
        for (c = 0, n = av_len(av); c <= n; ++c)
        {
          SV **p = av_fetch(av, c, 0);
          if (p)
          {
            DUMP_INDENT;
            sv_catpvf(buf, "index = %ld\n", (long) c);
            dump_sv(aTHX_ buf, level, *p);
          }
        }
      }
      break;

    case SVt_PVHV:
      {
        HV *hv = (HV *) sv;
        SV *v; I32 len;
        hv_iterinit(hv);
        while ((v = hv_iternextsv(hv, &str, &len)) != 0)
        {
          DUMP_INDENT;
          sv_catpv(buf, "key = \"");
          sv_catpvn(buf, str, len);
          sv_catpv(buf, "\"\n");
          dump_sv(aTHX_ buf, level, v);
        }
      }
      break;

    default:
      /* nothing */
      break;
  }
}

/*******************************************************************************
*
*   ROUTINE: identify_sv
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2006
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Identify an SV and return a string describing its type.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

const char *identify_sv(SV *sv)
{
  if (sv == NULL || !SvOK(sv)) return "an undefined value";

  if (SvROK(sv))
  {
    switch (SvTYPE(SvRV(sv)))
    {
      case SVt_PVAV: return "an array reference";
      case SVt_PVHV: return "a hash reference";
      case SVt_PVCV: return "a code reference";
      default:       return "a reference";
    }
  }

  if (SvIOK(sv)) return "an integer value";
  if (SvNOK(sv)) return "a numeric value";
  if (SvPOK(sv)) return "a string value";

  return "an unknown value";
}

