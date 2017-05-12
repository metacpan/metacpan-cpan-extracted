################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: configure
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

SV *
CBC::configure(...)
  PREINIT:
    CBC_METHOD(configure);

  CODE:
    CT_DEBUG_METHOD;

    if (items <= 2 && GIMME_V == G_VOID)
    {
      WARN_VOID_CONTEXT;
      XSRETURN_EMPTY;
    }
    else if (items == 1)
      RETVAL = get_configuration(aTHX_ THIS);
    else if (items == 2)
      handle_option(aTHX_ THIS, ST(1), NULL, &RETVAL, NULL);
    else if (items % 2)
    {
      int i, changes = 0, layout = 0, preproc = 0;
      HandleOptionResult res;

      for (i = 1; i < items; i += 2)
      {
        handle_option(aTHX_ THIS, ST(i), ST(i+1), NULL, &res);
        if (res.option_modified)
          changes = 1;
        if (res.impacts_layout)
          layout = 1;
        if (res.impacts_preproc)
          preproc = 1;
      }

      if (changes)
      {
        if (layout)
        {
          basic_types_reset(THIS->basic);

          if (THIS->cpi.available && THIS->cpi.ready)
            reset_parse_info(&THIS->cpi);
        }

        if (preproc)
        {
          reset_preprocessor(&THIS->cpi);
        }
      }

      XSRETURN(1);
    }
    else
      Perl_croak(aTHX_ "Invalid number of arguments to %s", method);

  OUTPUT:
    RETVAL

