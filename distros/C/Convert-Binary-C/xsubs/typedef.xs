################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: typedef_names
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::typedef_names()
  PREINIT:
    CBC_METHOD(typedef_names);
    ListIterator tli, ti;
    TypedefList *pTDL;
    Typedef     *pTypedef;
    int          count = 0;
    U32          context;

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    LL_foreach(pTDL, tli, THIS->cpi.typedef_lists)
      LL_foreach(pTypedef, ti, pTDL->typedefs)
        if (is_typedef_defined(pTypedef))
        {
          if (context == G_ARRAY)
            XPUSHs(sv_2mortal(newSVpv(pTypedef->pDecl->identifier, 0)));
          count++;
        }

    if (context == G_ARRAY)
      XSRETURN(count);
    else
      XSRETURN_IV(count);


################################################################################
#
#   METHOD: typedef
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::typedef(...)
  PREINIT:
    CBC_METHOD(typedef);
    Typedef *pTypedef;
    U32      context;

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    if (context == G_SCALAR && items != 2)
      XSRETURN_IV(items > 1 ? items-1 : HT_count(THIS->cpi.htTypedefs));

    NEED_PARSE_DATA;

    if (items > 1)
    {
      int i;

      for (i = 1; i < items; i++)
      {
        const char *name = SvPV_nolen(ST(i));

        pTypedef = HT_get(THIS->cpi.htTypedefs, name, 0, 0);

        if (pTypedef)
          PUSHs(sv_2mortal(get_typedef_def(aTHX_ &THIS->cfg, pTypedef)));
        else
          PUSHs(&PL_sv_undef);
      }

      XSRETURN(items-1);
    }
    else
    {
      ListIterator tli, ti;
      TypedefList *pTDL;
      int size = HT_count(THIS->cpi.htTypedefs);

      if (size <= 0)
        XSRETURN_EMPTY;

      EXTEND(SP, size);

      LL_foreach(pTDL, tli, THIS->cpi.typedef_lists)
        LL_foreach(pTypedef, ti, pTDL->typedefs)
          PUSHs(sv_2mortal(get_typedef_def(aTHX_ &THIS->cfg, pTypedef)));

      XSRETURN(size);
    }

