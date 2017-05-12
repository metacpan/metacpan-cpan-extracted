################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: enum_names
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::enum_names()
  PREINIT:
    CBC_METHOD(enum_names);
    ListIterator li;
    EnumSpecifier *pEnumSpec;
    int count = 0;
    U32 context;

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    LL_foreach(pEnumSpec, li, THIS->cpi.enums)
      if (pEnumSpec->identifier[0] && pEnumSpec->enumerators)
      {
        if (context == G_ARRAY)
          XPUSHs(sv_2mortal(newSVpv(pEnumSpec->identifier, 0)));
        count++;
      }

    if (context == G_ARRAY)
      XSRETURN(count);
    else
      XSRETURN_IV(count);


################################################################################
#
#   METHOD: enum
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::enum(...)
  PREINIT:
    CBC_METHOD(enum);
    EnumSpecifier *pEnumSpec;
    U32 context;

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    if (context == G_SCALAR && items != 2)
      XSRETURN_IV(items > 1 ? items-1 : LL_count(THIS->cpi.enums));

    if (items > 1)
    {
      int i;

      for (i = 1; i < items; i++)
      {
        const char *name = SvPV_nolen(ST(i));

        /* skip optional enum */
        if (name[0] == 'e' &&
            name[1] == 'n' &&
            name[2] == 'u' &&
            name[3] == 'm' &&
            isSPACE(name[4]))
          name += 5;

        while (isSPACE(*name))
          name++;

        pEnumSpec = HT_get(THIS->cpi.htEnums, name, 0, 0);

        if (pEnumSpec)
          PUSHs(sv_2mortal(get_enum_spec_def(aTHX_ &THIS->cfg, pEnumSpec)));
        else
          PUSHs(&PL_sv_undef);
      }

      XSRETURN(items-1);
    }
    else
    {
      ListIterator li;
      int size = LL_count(THIS->cpi.enums);

      if (size <= 0)
        XSRETURN_EMPTY;

      EXTEND(SP, size);

      LL_foreach(pEnumSpec, li, THIS->cpi.enums)
        PUSHs(sv_2mortal(get_enum_spec_def(aTHX_ &THIS->cfg, pEnumSpec)));

      XSRETURN(size);
    }

