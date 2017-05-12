################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   FUNCTION: native
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Aug 2004
#   CHANGED BY:                                   ON:
#
################################################################################
#
# DESCRIPTION: Get property of the native platform.
#
################################################################################

SV *
native(...)
  PREINIT:
    CBC_METHOD(native);
    int method_call;

  CODE:
    method_call = items > 0 && sv_isobject(ST(0));

    if (items > (method_call ? 2 : 1))
      Perl_croak(aTHX_ "Usage: Convert::Binary::C::native(property)");

    CHECK_VOID_CONTEXT;

    if (items == (method_call ? 1 : 0))
    {
      RETVAL = get_native_property(aTHX_ NULL);
    }
    else
    {
      const char *property = (const char *)SvPV_nolen(ST(items-1));

      RETVAL = get_native_property(aTHX_ property);

      if (RETVAL == NULL)
        Perl_croak(aTHX_ "Invalid property '%s'", property);
    }

  OUTPUT:
    RETVAL

