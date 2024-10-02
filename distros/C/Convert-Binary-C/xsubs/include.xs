################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: Include / Define / Assert
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::Include(...)
  ALIAS:
    Define = 1
    Assert = 2

  PREINIT:
    CBC_METHOD_VAR;
    LinkedList list;
    int hasRval;
    SV *rval, *inval;

  PPCODE:
    switch (ix)
    {
      case 1:  /* Define */
        CBC_METHOD_SET("Define");
        list = THIS->cfg.defines;
        break;
      case 2:  /* Assert */
        CBC_METHOD_SET("Assert");
        list = THIS->cfg.assertions;
        break;
      default: /* Include */
        CBC_METHOD_SET("Include");
        list = THIS->cfg.includes;
        break;
    }

    CT_DEBUG_METHOD;

    hasRval = GIMME_V != G_VOID && items <= 1;

    if (GIMME_V == G_VOID && items <= 1)
    {
      WARN_VOID_CONTEXT;
      XSRETURN_EMPTY;
    }

    if (items > 1 && !SvROK(ST(1)))
    {
      int i;
      inval = NULL;

      for (i = 1; i < items; i++)
      {
        if (SvROK(ST(i)))
          Perl_croak(aTHX_ "Argument %d to %s must not be a reference", i, method);

        LL_push(list, string_new_fromSV(aTHX_ ST(i)));
      }
    }
    else
    {
      if (items > 2)
        Perl_croak(aTHX_ "Invalid number of arguments to %s", method);

      inval = items == 2 ? ST(1) : NULL;
    }

    if (inval != NULL || hasRval)
      handle_string_list(aTHX_ method, list, inval, hasRval ? &rval : NULL);

    if (hasRval)
      ST(0) = sv_2mortal(rval);

    reset_preprocessor(&THIS->cpi);

    XSRETURN(1);


