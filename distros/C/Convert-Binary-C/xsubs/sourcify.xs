################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: sourcify
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
#   CHANGED BY:                                   ON:
#
################################################################################

SV *
CBC::sourcify(...)
  PREINIT:
    CBC_METHOD(sourcify);
    SourcifyConfig sc;

  CODE:
    CT_DEBUG_METHOD;

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    /* preset with defaults */
    sc.context = 0;
    sc.defines = 0;

    if (items == 2 && SvROK(ST(1)))
    {
      SV *sv = SvRV(ST(1));

      if (SvTYPE(sv) == SVt_PVHV)
        get_sourcify_config(aTHX_ (HV *) sv, &sc);
      else
        Perl_croak(aTHX_ "Need a hash reference for configuration options");
    }
    else if (items >= 2)
      Perl_croak(aTHX_ "Sourcification of individual types is not yet supported");

    RETVAL = get_parsed_definitions_string(aTHX_ &THIS->cpi, &sc);

  OUTPUT:
    RETVAL

