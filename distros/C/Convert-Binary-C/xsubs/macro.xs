################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: macro_names
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::macro_names()
  PREINIT:
    CBC_METHOD(macro_names);

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    if (GIMME_V == G_ARRAY)
    {
      LinkedList ll = macros_get_names(aTHX_ &THIS->cpi, NULL);
      int count = LL_count(ll);
      SV *sv;

      EXTEND(SP, count);
      while ((sv = LL_pop(ll)) != NULL)
        PUSHs(sv_2mortal(sv));

      assert(LL_count(ll) == 0);
      LL_delete(ll);

      XSRETURN(count);
    }
    else
    {
      size_t count;
      (void) macros_get_names(aTHX_ &THIS->cpi, &count);
      XSRETURN_IV((int)count);
    }

################################################################################
#
#   METHOD: macro
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Feb 2006
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::macro(...)
  PREINIT:
    CBC_METHOD(macro);

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    if (GIMME_V == G_SCALAR && items != 2)
    {
      if (items > 1)
      {
        XSRETURN_IV(items-1);
      }
      else
      {
        size_t count;
        (void) macros_get_names(aTHX_ &THIS->cpi, &count);
        XSRETURN_IV((int)count);
      }
    }

    if (items > 1)
    {
      int i;

      for (i = 1; i < items; i++)
      {
        const char *name = SvPV_nolen(ST(i));
        size_t len;
        char *def = macro_get_def(&THIS->cpi, name, &len);

        if (def)
        {
          PUSHs(sv_2mortal(newSVpvn(def, len)));
          macro_free_def(def);
        }
        else
          PUSHs(&PL_sv_undef);
      }

      XSRETURN(items-1);
    }
    else
    {
      LinkedList ll = macros_get_definitions(aTHX_ &THIS->cpi);
      int count = LL_count(ll);
      SV *sv;

      EXTEND(SP, count);
      while ((sv = LL_pop(ll)) != NULL)
        PUSHs(sv_2mortal(sv));

      assert(LL_count(ll) == 0);
      LL_delete(ll);

      XSRETURN(count);
    }

