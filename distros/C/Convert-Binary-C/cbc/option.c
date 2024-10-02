/*******************************************************************************
*
* MODULE: option.c
*
********************************************************************************
*
* DESCRIPTION: C::B::C options
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
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

#include "ctlib/arch.h"
#include "ctlib/ctparse.h"
#include "ctlib/parser.h"
#include "cbc/option.h"
#include "cbc/util.h"


/*===== DEFINES ==============================================================*/

/*===== TYPEDEFS =============================================================*/

typedef struct {
  const int   value;
  const char *string;
} StringOption;


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

static int check_integer_option(pTHX_ const IV *options, int count, SV *sv,
                                IV *value, const char *name);
static const StringOption *get_string_option(pTHX_ const StringOption *options,
                                             int count, int value, SV *sv,
                                             const char *name);
static void disabled_keywords(pTHX_ LinkedList *current, SV *sv, SV **rval,
                              u_32 *pKeywordMask);
static void keyword_map(pTHX_ HashTable *current, SV *sv, SV **rval);
static void bitfields_option(pTHX_ BitfieldLayouter *layouter, SV *sv_val, SV **rval);


/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

static const StringOption ByteOrderOption[] = {
  { CBO_BIG_ENDIAN,    "BigEndian"    },
  { CBO_LITTLE_ENDIAN, "LittleEndian" }
};

static const StringOption EnumTypeOption[] = {
  { ET_INTEGER, "Integer" },
  { ET_STRING,  "String"  },
  { ET_BOTH,    "Both"    }
};

static const IV PointerSizeOption[]       = {     0, 1, 2, 4, 8         };
static const IV EnumSizeOption[]          = { -1, 0, 1, 2, 4, 8         };
static const IV IntSizeOption[]           = {     0, 1, 2, 4, 8         };
static const IV CharSizeOption[]          = {     0, 1, 2, 4, 8         };
static const IV ShortSizeOption[]         = {     0, 1, 2, 4, 8         };
static const IV LongSizeOption[]          = {     0, 1, 2, 4, 8         };
static const IV LongLongSizeOption[]      = {     0, 1, 2, 4, 8         };
static const IV FloatSizeOption[]         = {     0, 1, 2, 4, 8, 12, 16 };
static const IV DoubleSizeOption[]        = {     0, 1, 2, 4, 8, 12, 16 };
static const IV LongDoubleSizeOption[]    = {     0, 1, 2, 4, 8, 12, 16 };
static const IV AlignmentOption[]         = {     0, 1, 2, 4, 8,     16 };
static const IV CompoundAlignmentOption[] = {     0, 1, 2, 4, 8,     16 };


/*===== STATIC FUNCTIONS =====================================================*/

/*******************************************************************************
*
*   ROUTINE: check_integer_option
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

static int check_integer_option(pTHX_ const IV *options, int count, SV *sv,
                                IV *value, const char *name)
{
  const IV *opt = options;
  int n = count;

  if (SvROK(sv))
  {
    Perl_croak(aTHX_ "%s must be an integer value, not a reference", name);
    return 0;
  }

  *value = SvIV(sv);

  while (n--)
    if (*value == *opt++)
      return 1;

  if (name)
  {
    SV *str = sv_2mortal(newSVpvn("", 0));

    for (n = 0; n < count; n++)
      sv_catpvf(str, "%" IVdf "%s", *options++,
                n < count-2 ? ", " : n == count-2 ? " or " : "");

    Perl_croak(aTHX_ "%s must be %s, not %" IVdf, name, SvPV_nolen(str), *value);
  }

  return 0;
}

/*******************************************************************************
*
*   ROUTINE: get_string_option
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

#define GET_STR_OPTION(name, value, sv)                                        \
          get_string_option(aTHX_ name ## Option, sizeof(name ## Option) /     \
                            sizeof(StringOption), value, sv, #name)

static const StringOption *get_string_option(pTHX_ const StringOption *options,
                                             int count, int value, SV *sv, const char *name)
{
  char *string = NULL;

  if (sv)
  {
    if (SvROK(sv))
      Perl_croak(aTHX_ "%s must be a string value, not a reference", name);
    else
      string = SvPV_nolen(sv);
  }

  if (string)
  {
    const StringOption *opt = options;
    int n = count;

    while (n--)
    {
      if (strEQ(string, opt->string))
        return opt;

      opt++;
    }

    if (name)
    {
      SV *str = sv_2mortal(newSVpvn("", 0));

      for (n = 0; n < count; n++)
      {
        sv_catpv(str, CONST_CHAR((options++)->string));
        if (n < count-2)
          sv_catpv(str, "', '");
        else if (n == count-2)
          sv_catpv(str, "' or '");
      }

      Perl_croak(aTHX_ "%s must be '%s', not '%s'", name, SvPV_nolen(str), string);
    }
  }
  else
  {
    while (count--)
    {
      if (value == options->value)
        return options;

      options++;
    }

    fatal("Inconsistent data detected in get_string_option()!");
  }

  return NULL;
}

/*******************************************************************************
*
*   ROUTINE: disabled_keywords
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
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

static void disabled_keywords(pTHX_ LinkedList *current, SV *sv, SV **rval,
                              u_32 *pKeywordMask)
{
  const char *str;
  LinkedList keyword_list = NULL;

  if (sv)
  {
    if (SvROK(sv))
    {
      sv = SvRV(sv);

      if (SvTYPE(sv) == SVt_PVAV)
      {
        AV *av = (AV *) sv;
        SV **pSV;
        int i, max = av_len(av);
        u_32 keywords = HAS_ALL_KEYWORDS;

        keyword_list = LL_new();

        for (i = 0; i <= max; i++)
        {
          if ((pSV = av_fetch(av, i, 0)) != NULL)
          {
            SvGETMAGIC(*pSV);
            str = SvPV_nolen(*pSV);

#include "token/t_keywords.c"

            success:
            LL_push(keyword_list, string_new(str));
          }
          else
            fatal("NULL returned by av_fetch() in disabled_keywords()");
        }

        if (pKeywordMask != NULL)
          *pKeywordMask = keywords;

        if (current != NULL)
        {
          LL_destroy(*current, (LLDestroyFunc) string_delete); 
          *current = keyword_list;
        }
      }
      else
        Perl_croak(aTHX_ "DisabledKeywords wants an array reference");
    }
    else
      Perl_croak(aTHX_ "DisabledKeywords wants a reference to "
                       "an array of strings");
  }

  if (rval)
  {
    ListIterator li;
    AV *av = newAV();

    LL_foreach (str, li, *current)
      av_push(av, newSVpv(CONST_CHAR(str), 0));

    *rval = newRV_noinc((SV *) av);
  }

  return;

unknown:
  LL_destroy(keyword_list, (LLDestroyFunc) string_delete);
  Perl_croak(aTHX_ "Cannot disable unknown keyword '%s'", str);
}

/*******************************************************************************
*
*   ROUTINE: keyword_map
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
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

#define FAIL_CLEAN(x)                                                          \
        STMT_START {                                                           \
          HT_destroy(keyword_map, NULL);                                       \
          Perl_croak x;                                                        \
        } STMT_END

static void keyword_map(pTHX_ HashTable *current, SV *sv, SV **rval)
{
  HashTable keyword_map = NULL;

  if(sv)
  {
    if (SvROK(sv))
    {
      sv = SvRV(sv);

      if (SvTYPE(sv) == SVt_PVHV)
      {
        HV *hv = (HV *) sv;
        HE *entry;

        keyword_map = HT_new_ex(4, HT_AUTOGROW);

        (void) hv_iterinit(hv);

        while ((entry = hv_iternext(hv)) != NULL)
        {
          SV *value;
          I32 keylen;
          const char *key, *c;
          const CKeywordToken *pTok;

          c = key = hv_iterkey(entry, &keylen);

          if (*c == '\0')
            FAIL_CLEAN((aTHX_ "Cannot use empty string as a keyword"));

          while (*c == '_' || isALPHA(*c))
            c++;

          if (*c != '\0')
            FAIL_CLEAN((aTHX_ "Cannot use '%s' as a keyword", key));

          value = hv_iterval(hv, entry);

          if (!SvOK(value))
            pTok = get_skip_token();
          else
          {
            const char *map;

            if (SvROK(value))
              FAIL_CLEAN((aTHX_ "Cannot use a reference as a keyword"));

            map = SvPV_nolen(value);

            if ((pTok = get_c_keyword_token(map)) == NULL)
              FAIL_CLEAN((aTHX_ "Cannot use '%s' as a keyword", map));
          }

          (void) HT_store(keyword_map, key, (int) keylen, 0,
                          (CKeywordToken *) pTok);
        }

        if (current != NULL)
        {
          HT_destroy(*current, NULL);
          *current = keyword_map;
        }
      }
      else
        Perl_croak(aTHX_ "KeywordMap wants a hash reference");
    }
    else
      Perl_croak(aTHX_ "KeywordMap wants a hash reference");
  }

  if (rval)
  {
    HashIterator hi;
    HV *hv = newHV();
    CKeywordToken *tok;
    const char *key;
    int keylen;

    HI_init(&hi, *current);

    while (HI_next(&hi, &key, &keylen, (void **) &tok))
    {
      SV *val;
      val = tok->name == NULL ? newSV(0) : newSVpv(CONST_CHAR(tok->name), 0);
      if (hv_store(hv, key, keylen, val, 0) == NULL)
        SvREFCNT_dec(val);
    }

    *rval = newRV_noinc((SV *) hv);
  }
}

#undef FAIL_CLEAN

/*******************************************************************************
*
*   ROUTINE: bitfields_option
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

#define FAIL_CLEAN(x)                                                          \
        STMT_START {                                                           \
          if (bl_new)                                                          \
            bl_new->m->destroy(bl_new);                                        \
          Perl_croak x;                                                        \
        } STMT_END

static void bitfields_option(pTHX_ BitfieldLayouter *layouter, SV *sv_val, SV **rval)
{
  BitfieldLayouter bl_new = NULL;
  BitfieldLayouter bl = *layouter;

  if(sv_val)
  {
    if (SvROK(sv_val))
    {
      sv_val = SvRV(sv_val);

      if (SvTYPE(sv_val) == SVt_PVHV)
      {
        HV *hv = (HV *) sv_val;
        HE *entry;
        SV **engine = hv_fetch(hv, "Engine", 6, 0);
        int noptions;
        const BLOption *options;

        if (engine && *engine)
        {
          const char *name = SvPV_nolen(*engine);
          bl = bl_new = bl_create(name);
          if (bl_new == NULL)
            Perl_croak(aTHX_ "Unknown bitfield layout engine '%s'", name);
        }

        (void) hv_iterinit(hv);

        options = bl->m->options(bl, &noptions);

        while ((entry = hv_iternext(hv)) != NULL)
        {
          SV *value;
          I32 keylen;
          int i;
          const char *prop_string = hv_iterkey(entry, &keylen);
          BLProperty prop;
          BLPropValue prop_value;
          const BLOption *opt = NULL;
          enum BLError error;

          if (strEQ(prop_string, "Engine"))
            continue;

          prop = bl_property(prop_string);

          for (i = 0; i < noptions; i++)
            if (options[i].prop == prop)
            {
              opt = &options[i];
              break;
            }

          if (opt == NULL)
            FAIL_CLEAN((aTHX_ "Invalid option '%s' for bitfield layout engine '%s'",
                              prop_string, bl->m->class_name(bl)));

          value = hv_iterval(hv, entry);
          prop_value.type = opt->type;

          switch (opt->type)
          {
            case BLPVT_INT:
              prop_value.v.v_int = SvIV(value);

              if (opt->nval)
              {
                const BLPropValInt *pval = opt->pval;

                for (i = 0; i < opt->nval; i++)
                  if (pval[i] == prop_value.v.v_int)
                    break;
              }
              break;

            case BLPVT_STR:
              prop_value.v.v_str = bl_propval(SvPV_nolen(value));

              if (opt->nval)
              {
                const BLPropValStr *pval = opt->pval;

                for (i = 0; i < opt->nval; i++)
                  if (pval[i] == prop_value.v.v_str)
                    break;
              }
              break;

            default:
              fatal("unknown opt->type (%d) in bitfields_option()", opt->type);
              break;
          }

          if (opt->nval && i == opt->nval)
            FAIL_CLEAN((aTHX_ "Invalid value '%s' for option '%s'",
                              SvPV_nolen(value), prop_string));

          error = bl->m->set(bl, prop, &prop_value);

          switch (error)
          {
            case BLE_NO_ERROR:
              break;

            case BLE_INVALID_PROPERTY:
              FAIL_CLEAN((aTHX_ "Invalid value '%s' for option '%s'",
                                SvPV_nolen(value), prop_string));
              break;

            default:
              fatal("unknown error code (%d) returned by set method", error);
              break;
          }
        }

        if (bl_new)
        {
          (*layouter)->m->destroy(*layouter);
          *layouter = bl_new;
        }
      }
      else
        Perl_croak(aTHX_ "Bitfields wants a hash reference");
    }
    else
      Perl_croak(aTHX_ "Bitfields wants a hash reference");
  }

  if (rval)
  {
    int noptions;
    const BLOption *opt;
    int i;
    HV *hv = newHV();
    SV *sv = newSVpv(bl->m->class_name(bl), 0);

    if (hv_store(hv, "Engine", 6, sv, 0) == NULL)
      SvREFCNT_dec(sv);

    opt = bl->m->options(bl, &noptions);

    for (i = 0; i < noptions; i++, opt++)
    {
      BLPropValue value;
      enum BLError error;
      const char *prop_string;

      error = bl->m->get(bl, opt->prop, &value);

      if (error != BLE_NO_ERROR)
        fatal("unexpected error (%d) returned by get method", error);

      assert(value.type == opt->type);

      switch (opt->type)
      {
        case BLPVT_INT:
          sv = newSViv(value.v.v_int);
          break;

        case BLPVT_STR:
          {
            const char *valstr = bl_propval_string(value.v.v_str);
            assert(valstr != NULL);
            sv = newSVpv(valstr, 0);
          }
          break;

        default:
          fatal("unknown opt->type (%d) in bitfields_option()", opt->type);
          break;
      }

      prop_string = bl_property_string(opt->prop);
      assert(prop_string != NULL);

      if (hv_store(hv, prop_string, strlen(prop_string), sv, 0) == NULL)
        SvREFCNT_dec(sv);
    }

    *rval = newRV_noinc((SV *) hv);
  }
}

#undef FAIL_CLEAN

/*******************************************************************************
*
*   ROUTINE: get_config_option
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2002
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

#include "token/t_config.c"


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: handle_string_list
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

void handle_string_list(pTHX_ const char *option, LinkedList list, SV *sv, SV **rval)
{
  const char *str;

  if (sv)
  {
    LL_flush(list, (LLDestroyFunc) string_delete); 

    if (SvROK(sv))
    {
      sv = SvRV(sv);

      if (SvTYPE(sv) == SVt_PVAV)
      {
        AV *av = (AV *) sv;
        SV **pSV;
        int i, max = av_len(av);

        for (i = 0; i <= max; i++)
        {
          if ((pSV = av_fetch(av, i, 0)) != NULL)
          {
            SvGETMAGIC(*pSV);
            LL_push(list, string_new_fromSV(aTHX_ *pSV));
          }
          else
            fatal("NULL returned by av_fetch() in handle_string_list()");
        }
      }
      else
        Perl_croak(aTHX_ "%s wants an array reference", option);
    }
    else
      Perl_croak(aTHX_ "%s wants a reference to an array of strings", option);
  }

  if (rval)
  {
    ListIterator li;
    AV *av = newAV();

    LL_foreach(str, li, list)
      av_push(av, newSVpv(CONST_CHAR(str), 0));

    *rval = newRV_noinc((SV *) av);
  }
}

/*******************************************************************************
*
*   ROUTINE: handle_option
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

#define START_OPTIONS                                                          \
          const char *option;                                                  \
          ConfigOption cfgopt;                                                 \
          if (p_res)                                                           \
          {                                                                    \
            p_res->option_modified = 0;                                        \
            p_res->impacts_layout = 0;                                         \
            p_res->impacts_preproc = 0;                                        \
          }                                                                    \
          if (SvROK(opt))                                                      \
            Perl_croak(aTHX_ "Option name must be a string, "                  \
                             "not a reference");                               \
          switch (cfgopt = get_config_option(option = SvPV_nolen(opt))) {

#define DID_CHANGE(change)                                                     \
        STMT_START {                                                           \
          if (p_res)                                                           \
            p_res->option_modified = change;                                   \
        } STMT_END

#define IMPACTS_LAYOUT(layout)                                                 \
        STMT_START {                                                           \
          if (p_res)                                                           \
            p_res->impacts_layout = layout;                                    \
        } STMT_END

#define IMPACTS_PREPROC(pp)                                                    \
        STMT_START {                                                           \
          if (p_res)                                                           \
            p_res->impacts_preproc = pp;                                       \
        } STMT_END

#define POST_PROCESS      } switch (cfgopt) {

#define END_OPTIONS       default: break; }

#define OPTION(name)      case OPTION_ ## name : {

#define ENDOPT            } break;

#define UPDATE_OPT(option, val)                                                \
        STMT_START {                                                           \
          if ((IV) THIS->option != val)                                        \
          {                                                                    \
            THIS->option = val;                                                \
            DID_CHANGE(1);                                                     \
          }                                                                    \
        } STMT_END

#define FLAG_OPTION(name, flag, layout, pp)                                    \
          case OPTION_ ## name :                                               \
            IMPACTS_LAYOUT(layout);                                            \
            IMPACTS_PREPROC(pp);                                               \
            if (sv_val)                                                        \
            {                                                                  \
              if (SvROK(sv_val))                                               \
                Perl_croak(aTHX_ #name " must be a boolean value, "            \
                                       "not a reference");                     \
              else if (THIS->flag != SvIV(sv_val) ? 1 : 0)                     \
              {                                                                \
                THIS->flag = SvIV(sv_val) ? 1 : 0;                             \
                DID_CHANGE(1);                                                 \
              }                                                                \
            }                                                                  \
            if (rval)                                                          \
              *rval = newSViv(THIS->flag ? 1 : 0);                             \
            break;

#define IVAL_OPTION(name, config, layout, pp)                                  \
          case OPTION_ ## name :                                               \
            IMPACTS_LAYOUT(layout);                                            \
            IMPACTS_PREPROC(pp);                                               \
            if (sv_val)                                                        \
            {                                                                  \
              IV val;                                                          \
              if (check_integer_option(aTHX_ name ## Option,                   \
                                       sizeof(name ## Option) / sizeof(IV),    \
                                       sv_val, &val, #name))                   \
                UPDATE_OPT(config, val);                                       \
            }                                                                  \
            if (rval)                                                          \
              *rval = newSViv(THIS->config);                                   \
            break;

#define TRISTATE_FLAG_OPTION(name, state, flag, layout, pp)                    \
          case OPTION_ ## name :                                               \
            IMPACTS_LAYOUT(layout);                                            \
            IMPACTS_PREPROC(pp);                                               \
            if (sv_val)                                                        \
            {                                                                  \
              unsigned isdef = SvOK(sv_val) != 0;                              \
              int changed = isdef != THIS->state;                              \
              THIS->state = isdef;                                             \
              if (isdef)                                                       \
              {                                                                \
                if (SvROK(sv_val))                                             \
                  Perl_croak(aTHX_ #name " must be undef or a boolean "        \
                                         "value, not a reference");            \
                else if (THIS->flag != SvIV(sv_val) ? 1 : 0)                   \
                {                                                              \
                  THIS->flag = SvIV(sv_val) ? 1 : 0;                           \
                  changed = 1;                                                 \
                }                                                              \
              }                                                                \
              DID_CHANGE(changed);                                             \
            }                                                                  \
            if (rval)                                                          \
              *rval = THIS->state ? newSViv(THIS->flag ? 1 : 0) : &PL_sv_undef;\
            break;

#define TRISTATE_INT_OPTION(name, state, config, layout, pp)                   \
          case OPTION_ ## name :                                               \
            IMPACTS_LAYOUT(layout);                                            \
            IMPACTS_PREPROC(pp);                                               \
            if (sv_val)                                                        \
            {                                                                  \
              unsigned isdef = SvOK(sv_val) != 0;                              \
              int changed = isdef != THIS->state;                              \
              THIS->state = isdef;                                             \
              if (isdef)                                                       \
              {                                                                \
                if (SvROK(sv_val))                                             \
                  Perl_croak(aTHX_ #name " must be undef or an integer "       \
                                         "value, not a reference");            \
                else if (THIS->config != SvIV(sv_val))                         \
                {                                                              \
                  THIS->config = SvIV(sv_val);                                 \
                  changed = 1;                                                 \
                }                                                              \
              }                                                                \
              DID_CHANGE(changed);                                             \
            }                                                                  \
            if (rval)                                                          \
              *rval = THIS->state ? newSViv(THIS->config) : &PL_sv_undef;      \
            break;

#define STRLIST_OPTION(name, config, layout, pp)                               \
          case OPTION_ ## name :                                               \
            IMPACTS_LAYOUT(layout);                                            \
            IMPACTS_PREPROC(pp);                                               \
            handle_string_list(aTHX_ #name, THIS->config, sv_val, rval);       \
            DID_CHANGE(sv_val != NULL);                                        \
            break;

#define INVALID_OPTION                                                         \
          default:                                                             \
            Perl_croak(aTHX_ "Invalid option '%s'", option);                   \
            break;

void handle_option(pTHX_ CBC *THIS, SV *opt, SV *sv_val, SV **rval, HandleOptionResult *p_res)
{
  START_OPTIONS

    FLAG_OPTION(OrderMembers,      order_members,          0, 0)

    FLAG_OPTION(Warnings,          cfg.issue_warnings,     0, 0)
    FLAG_OPTION(HasCPPComments,    cfg.has_cpp_comments,   0, 1)
    FLAG_OPTION(HasMacroVAARGS,    cfg.has_macro_vaargs,   0, 1)
    FLAG_OPTION(UnsignedChars,     cfg.unsigned_chars,     0, 0)
    FLAG_OPTION(UnsignedBitfields, cfg.unsigned_bitfields, 0, 0)

    IVAL_OPTION(PointerSize,       cfg.layout.ptr_size,           1, 0)
    IVAL_OPTION(EnumSize,          cfg.layout.enum_size,          1, 0)
    IVAL_OPTION(IntSize,           cfg.layout.int_size,           1, 0)
    IVAL_OPTION(CharSize,          cfg.layout.char_size,          1, 0)
    IVAL_OPTION(ShortSize,         cfg.layout.short_size,         1, 0)
    IVAL_OPTION(LongSize,          cfg.layout.long_size,          1, 0)
    IVAL_OPTION(LongLongSize,      cfg.layout.long_long_size,     1, 0)
    IVAL_OPTION(FloatSize,         cfg.layout.float_size,         1, 0)
    IVAL_OPTION(DoubleSize,        cfg.layout.double_size,        1, 0)
    IVAL_OPTION(LongDoubleSize,    cfg.layout.long_double_size,   1, 0)
    IVAL_OPTION(Alignment,         cfg.layout.alignment,          1, 0)
    IVAL_OPTION(CompoundAlignment, cfg.layout.compound_alignment, 1, 0)

    TRISTATE_FLAG_OPTION(HostedC, cfg.has_std_c_hosted, cfg.is_std_c_hosted, 0, 1)

    TRISTATE_INT_OPTION(StdCVersion, cfg.has_std_c, cfg.std_c_version, 0, 1)

    STRLIST_OPTION(Include, cfg.includes,   0, 1)
    STRLIST_OPTION(Define,  cfg.defines,    0, 1)
    STRLIST_OPTION(Assert,  cfg.assertions, 0, 1)

    OPTION(DisabledKeywords)
      IMPACTS_LAYOUT(0);
      disabled_keywords(aTHX_ &THIS->cfg.disabled_keywords, sv_val, rval,
                        &THIS->cfg.keywords);
      DID_CHANGE(sv_val != NULL);
    ENDOPT

    OPTION(KeywordMap)
      IMPACTS_LAYOUT(0);
      keyword_map(aTHX_ &THIS->cfg.keyword_map, sv_val, rval);
      DID_CHANGE(sv_val != NULL);
    ENDOPT

    OPTION(ByteOrder)
      IMPACTS_LAYOUT(1);
      if (sv_val)
      {
        const StringOption *pOpt = GET_STR_OPTION(ByteOrder, 0, sv_val);
        UPDATE_OPT(cfg.layout.byte_order, pOpt->value);
      }
      if (rval)
      {
        const StringOption *pOpt = GET_STR_OPTION(ByteOrder,
                                     THIS->cfg.layout.byte_order, NULL);
        *rval = newSVpv(CONST_CHAR(pOpt->string), 0);
      }
    ENDOPT

    OPTION(EnumType)
      IMPACTS_LAYOUT(0);
      if (sv_val)
      {
        const StringOption *pOpt = GET_STR_OPTION(EnumType, 0, sv_val);
        UPDATE_OPT(enumType, pOpt->value);
      }
      if (rval)
      {
        const StringOption *pOpt = GET_STR_OPTION(EnumType, THIS->enumType, NULL);
        *rval = newSVpv(CONST_CHAR(pOpt->string), 0);
      }
    ENDOPT

    OPTION(Bitfields)
      IMPACTS_LAYOUT(1);
      bitfields_option(aTHX_ &THIS->cfg.layout.bflayouter, sv_val, rval);
      DID_CHANGE(sv_val != NULL);
    ENDOPT

    INVALID_OPTION

  POST_PROCESS

    OPTION(OrderMembers)
      if (sv_val && THIS->order_members && THIS->ixhash == NULL)
        load_indexed_hash_module(aTHX_ THIS);
    ENDOPT

  END_OPTIONS
}

#undef START_OPTIONS
#undef END_OPTIONS
#undef OPTION
#undef ENDOPT
#undef UPDATE_OPT
#undef FLAG_OPTION
#undef IVAL_OPTION
#undef TRISTATE_FLAG_OPTION
#undef TRISTATE_INT_OPTION
#undef STRLIST_OPTION

/*******************************************************************************
*
*   ROUTINE: get_configuration
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

#define FLAG_OPTION(name, flag)                                                \
          sv = newSViv(THIS->flag);                                            \
          HV_STORE_CONST(hv, #name, sv);

#define STRLIST_OPTION(name, config)                                           \
          handle_string_list(aTHX_ #name, THIS->config, NULL, &sv);            \
          HV_STORE_CONST(hv, #name, sv);

#define IVAL_OPTION(name, config)                                              \
          sv = newSViv(THIS->config);                                          \
          HV_STORE_CONST(hv, #name, sv);

#define TRISTATE_FLAG_OPTION(name, state, flag)                                \
	  sv = THIS->state ? newSViv(THIS->flag ? 1 : 0) : &PL_sv_undef;       \
          HV_STORE_CONST(hv, #name, sv);

#define TRISTATE_INT_OPTION(name, state, config)                               \
	  sv = THIS->state ? newSViv(THIS->config) : &PL_sv_undef;             \
          HV_STORE_CONST(hv, #name, sv);

#define STRING_OPTION(name, value)                                             \
          sv = newSVpv(CONST_CHAR(GET_STR_OPTION(name, value, NULL)->string), 0);\
          HV_STORE_CONST(hv, #name, sv);

SV *get_configuration(pTHX_ CBC *THIS)
{
  HV *hv = newHV();
  SV *sv;

  FLAG_OPTION(OrderMembers,      order_members         )

  FLAG_OPTION(Warnings,          cfg.issue_warnings    )
  FLAG_OPTION(HasCPPComments,    cfg.has_cpp_comments  )
  FLAG_OPTION(HasMacroVAARGS,    cfg.has_macro_vaargs  )
  FLAG_OPTION(UnsignedChars,     cfg.unsigned_chars    )
  FLAG_OPTION(UnsignedBitfields, cfg.unsigned_bitfields)

  IVAL_OPTION(PointerSize,       cfg.layout.ptr_size          )
  IVAL_OPTION(EnumSize,          cfg.layout.enum_size         )
  IVAL_OPTION(IntSize,           cfg.layout.int_size          )
  IVAL_OPTION(CharSize,          cfg.layout.char_size         )
  IVAL_OPTION(ShortSize,         cfg.layout.short_size        )
  IVAL_OPTION(LongSize,          cfg.layout.long_size         )
  IVAL_OPTION(LongLongSize,      cfg.layout.long_long_size    )
  IVAL_OPTION(FloatSize,         cfg.layout.float_size        )
  IVAL_OPTION(DoubleSize,        cfg.layout.double_size       )
  IVAL_OPTION(LongDoubleSize,    cfg.layout.long_double_size  )
  IVAL_OPTION(Alignment,         cfg.layout.alignment         )
  IVAL_OPTION(CompoundAlignment, cfg.layout.compound_alignment)

  TRISTATE_FLAG_OPTION(HostedC, cfg.has_std_c_hosted, cfg.is_std_c_hosted)

  TRISTATE_INT_OPTION(StdCVersion, cfg.has_std_c, cfg.std_c_version)

  STRLIST_OPTION(Include,          cfg.includes         )
  STRLIST_OPTION(Define,           cfg.defines          )
  STRLIST_OPTION(Assert,           cfg.assertions       )
  STRLIST_OPTION(DisabledKeywords, cfg.disabled_keywords)

  keyword_map(aTHX_ &THIS->cfg.keyword_map, NULL, &sv);
  HV_STORE_CONST(hv, "KeywordMap", sv);

  STRING_OPTION(ByteOrder, THIS->cfg.layout.byte_order)
  STRING_OPTION(EnumType,  THIS->enumType)

  bitfields_option(aTHX_ &THIS->cfg.layout.bflayouter, NULL, &sv);
  HV_STORE_CONST(hv, "Bitfields", sv);

  return newRV_noinc((SV *) hv);
}

#undef FLAG_OPTION
#undef STRLIST_OPTION
#undef IVAL_OPTION
#undef STRING_OPTION

/*******************************************************************************
*
*   ROUTINE: get_native_property
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

SV *get_native_property(pTHX_ const char *property)
{
  static const char *native_byteorder =
#if ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_BIG_ENDIAN
		  "BigEndian"
#elif ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_LITTLE_ENDIAN
		  "LittleEndian"
#else
#error "unknown native byte order"
#endif
		;

#if defined(__STDC_VERSION__)
# define STD_C_NATIVE newSViv(__STDC_VERSION__)
#else
# define STD_C_NATIVE &PL_sv_undef
#endif

#ifdef __STDC_HOSTED__
# define HOSTED_C_NATIVE newSViv(__STDC_HOSTED__)
#else
# define HOSTED_C_NATIVE &PL_sv_undef
#endif

  if (property == NULL)
  {
    HV *h = newHV();
    
    HV_STORE_CONST(h, "PointerSize",       newSViv(CTLIB_POINTER_SIZE));
    HV_STORE_CONST(h, "IntSize",           newSViv(CTLIB_int_SIZE));
    HV_STORE_CONST(h, "CharSize",          newSViv(CTLIB_char_SIZE));
    HV_STORE_CONST(h, "ShortSize",         newSViv(CTLIB_short_SIZE));
    HV_STORE_CONST(h, "LongSize",          newSViv(CTLIB_long_SIZE));
    HV_STORE_CONST(h, "LongLongSize",      newSViv(CTLIB_long_long_SIZE));
    HV_STORE_CONST(h, "FloatSize",         newSViv(CTLIB_float_SIZE));
    HV_STORE_CONST(h, "DoubleSize",        newSViv(CTLIB_double_SIZE));
    HV_STORE_CONST(h, "LongDoubleSize",    newSViv(CTLIB_long_double_SIZE));
    HV_STORE_CONST(h, "Alignment",         newSViv(CTLIB_ALIGNMENT));
    HV_STORE_CONST(h, "CompoundAlignment", newSViv(CTLIB_COMPOUND_ALIGNMENT));
    HV_STORE_CONST(h, "EnumSize",          newSViv(get_native_enum_size()));
    HV_STORE_CONST(h, "ByteOrder",         newSVpv(native_byteorder, 0));
    HV_STORE_CONST(h, "UnsignedChars",     newSViv(get_native_unsigned_chars()));
    HV_STORE_CONST(h, "UnsignedBitfields", newSViv(get_native_unsigned_bitfields()));
    HV_STORE_CONST(h, "StdCVersion",       STD_C_NATIVE);
    HV_STORE_CONST(h, "HostedC",           HOSTED_C_NATIVE);
    
    return newRV_noinc((SV *)h);
  }

  switch (get_config_option(property))
  {
    case OPTION_PointerSize:       return newSViv(CTLIB_POINTER_SIZE);
    case OPTION_IntSize:           return newSViv(CTLIB_int_SIZE);
    case OPTION_CharSize:          return newSViv(CTLIB_char_SIZE);
    case OPTION_ShortSize:         return newSViv(CTLIB_short_SIZE);
    case OPTION_LongSize:          return newSViv(CTLIB_long_SIZE);
    case OPTION_LongLongSize:      return newSViv(CTLIB_long_long_SIZE);
    case OPTION_FloatSize:         return newSViv(CTLIB_float_SIZE);
    case OPTION_DoubleSize:        return newSViv(CTLIB_double_SIZE);
    case OPTION_LongDoubleSize:    return newSViv(CTLIB_long_double_SIZE);
    case OPTION_Alignment:         return newSViv(CTLIB_ALIGNMENT);
    case OPTION_CompoundAlignment: return newSViv(CTLIB_COMPOUND_ALIGNMENT);
    case OPTION_EnumSize:          return newSViv(get_native_enum_size());
    case OPTION_ByteOrder:         return newSVpv(native_byteorder, 0);
    case OPTION_UnsignedChars:     return newSViv(get_native_unsigned_chars());
    case OPTION_UnsignedBitfields: return newSViv(get_native_unsigned_bitfields());
    case OPTION_StdCVersion:       return STD_C_NATIVE;
    case OPTION_HostedC:           return HOSTED_C_NATIVE;
    default:
      return NULL;
  }
}

