################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: compound_names / struct_names / union_names
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::compound_names()
  ALIAS:
    struct_names = 1
    union_names  = 2

  PREINIT:
    CBC_METHOD_VAR;
    ListIterator li;
    Struct *pStruct;
    int count = 0;
    U32 context;
    u_32 mask;

  PPCODE:
    switch (ix)
    {
      case 1:  /* struct_names */
        CBC_METHOD_SET("struct_names");
        mask = T_STRUCT;
        break;
      case 2:  /* union_names */
        CBC_METHOD_SET("union_names");
        mask = T_UNION;
        break;
      default: /* compound_names */
        CBC_METHOD_SET("compound_names");
        mask = T_STRUCT | T_UNION;
        break;
    }

    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    LL_foreach(pStruct, li, THIS->cpi.structs)
      if (pStruct->identifier[0] &&
          pStruct->declarations &&
          pStruct->tflags & mask)
      {
        if (context == G_ARRAY)
          XPUSHs(sv_2mortal(newSVpv(pStruct->identifier, 0)));
        count++;
      }

    if (context == G_ARRAY)
      XSRETURN(count);
    else
      XSRETURN_IV(count);


################################################################################
#
#   METHOD: compound / struct / union
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::compound(...)
  ALIAS:
    struct = 1
    union  = 2

  PREINIT:
    CBC_METHOD_VAR;
    Struct *pStruct;
    U32 context;
    u_32 mask;

  PPCODE:
    switch(ix)
    {
      case 1:  /* struct */
        CBC_METHOD_SET("struct");
        mask = T_STRUCT;
        break;
      case 2:  /* union */
        CBC_METHOD_SET("union");
        mask = T_UNION;
        break;
      default: /* compound */
        CBC_METHOD_SET("compound");
        mask = T_STRUCT | T_UNION;
        break;
    }

    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    context = GIMME_V;

    if (context == G_SCALAR && items != 2)
    {
      if (items > 1)
        XSRETURN_IV(items-1);
      else if (mask == (T_STRUCT|T_UNION))
        XSRETURN_IV(LL_count(THIS->cpi.structs));
      else
      {
        ListIterator li;
        int count = 0;

        LL_foreach(pStruct, li, THIS->cpi.structs)
          if (pStruct->tflags & mask)
            count++;

        XSRETURN_IV(count);
      }
    }

    NEED_PARSE_DATA;

    if (items > 1)
    {
      int i;

      for (i = 1; i < items; i++)
      {
        const char *name;
        u_32 limit = mask;

        name = SvPV_nolen(ST(i));

        /* skip optional union/struct */
        if(mask & T_UNION && 
           name[0] == 'u' && 
           name[1] == 'n' && 
           name[2] == 'i' && 
           name[3] == 'o' && 
           name[4] == 'n' && 
           isSPACE(name[5]))
        {
          name += 6;
          limit = T_UNION;
        }
        else
        if(mask & T_STRUCT && 
           name[0] == 's'  && 
           name[1] == 't'  && 
           name[2] == 'r'  && 
           name[3] == 'u'  && 
           name[4] == 'c'  && 
           name[5] == 't'  && 
           isSPACE(name[6]))
        {
          name += 7;
          limit = T_STRUCT;
        }

        while (isSPACE(*name))
          name++;

        pStruct = HT_get(THIS->cpi.htStructs, name, 0, 0);

        if (pStruct && pStruct->tflags & limit)
          PUSHs(sv_2mortal(get_struct_spec_def(aTHX_ &THIS->cfg, pStruct)));
        else
          PUSHs(&PL_sv_undef);
      }

      XSRETURN(items-1);
    }
    else
    {
      ListIterator li;
      int count = 0;

      LL_foreach(pStruct, li, THIS->cpi.structs)
        if (pStruct->tflags & mask)
        {
          XPUSHs(sv_2mortal(get_struct_spec_def(aTHX_ &THIS->cfg, pStruct)));
          count++;
        }

      XSRETURN(count);
    }

