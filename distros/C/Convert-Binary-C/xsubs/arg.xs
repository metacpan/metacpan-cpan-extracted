################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: arg
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jun 2004
#   CHANGED BY:                                   ON:
#
################################################################################
#
# DESCRIPTION: Turn string arguments into blessed object, so we can recognize
#              them later on.
#
################################################################################

void
CBC::arg(...)
  PREINIT:
    CBC_METHOD(arg);
    int i;

  PPCODE:
    CT_DEBUG_METHOD;

    CHECK_VOID_CONTEXT;

    for (i = 1; i < items; i++)
    {
      const char *argstr;
      STRLEN len;
      HookArgType type;
      SV *sv;

      argstr = SvPV(ST(i), len);

      if (strEQ(argstr, "SELF"))
        type = HOOK_ARG_SELF;
      else if (strEQ(argstr, "TYPE"))
        type = HOOK_ARG_TYPE;
      else if (strEQ(argstr, "DATA"))
        type = HOOK_ARG_DATA;
      else if (strEQ(argstr, "HOOK"))
        type = HOOK_ARG_HOOK;
      else
        Perl_croak(aTHX_ "Unknown argument type '%s' in %s", argstr, method);

      sv = newRV_noinc(newSViv(type));
      sv_bless(sv, gv_stashpv(ARGTYPE_PACKAGE, 1));
      ST(i-1) = sv_2mortal(sv);
    }

    XSRETURN(items-1);

