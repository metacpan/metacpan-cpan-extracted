################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   FUNCTION: feature
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################
#
# DESCRIPTION: Check if the module was compiled with a certain feature.
#
################################################################################

void
feature(...)
  PREINIT:
    CBC_METHOD(feature);
    int method_call;
    const char *feat;

  PPCODE:
    method_call = items > 0 && sv_isobject(ST(0));

    if (items != (method_call ? 2 : 1))
      Perl_croak(aTHX_ "Usage: Convert::Binary::C::feature(feat)");

    CHECK_VOID_CONTEXT;

    feat = (const char *)SvPV_nolen(ST(items-1));

    switch (*feat)
    {
      case 'd':
        if (strEQ(feat, "debug"))
#ifdef CBC_DEBUGGING
          XSRETURN_YES;
#else
          XSRETURN_NO;
#endif
        break;

      case 'i':
        if (strEQ(feat, "ieeefp"))
#ifdef CBC_HAVE_IEEE_FP
          XSRETURN_YES;
#else
          XSRETURN_NO;
#endif
        break;
    }

    XSRETURN_UNDEF;

