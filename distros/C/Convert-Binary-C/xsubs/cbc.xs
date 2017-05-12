################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   CONSTRUCTOR
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::new(...)
  PREINIT:
    CBC_METHOD(new);

  PPCODE:
    CT_DEBUG_METHOD;

    if (items % 2 == 0)
      Perl_croak(aTHX_ "Number of configuration arguments "
                       "to %s must be even", method);
    else
    {
      int i;
      CBC *THIS = cbc_new(aTHX);

      if (gs_DisableParser)
      {
        Perl_warn(aTHX_ XSCLASS " parser is DISABLED");
        THIS->cfg.disable_parser = 1;
      }

      /* Only preset the option here, user may explicitly */
      /* disable OrderMembers in the constructor          */
      if (gs_OrderMembers)
        THIS->order_members = 1;

      /*
       *  bless the new object here, because handle_option()
       *  may croak and DESTROY would not be called to free
       *  the memory that has been allocated
       */
      ST(0) = sv_2mortal(cbc_bless(aTHX_ THIS, CLASS));

      for (i = 1; i < items; i += 2)
        handle_option(aTHX_ THIS, ST(i), ST(i+1), NULL, NULL);

      if (gs_OrderMembers && THIS->order_members)
        load_indexed_hash_module(aTHX_ THIS);

      XSRETURN(1);
    }


################################################################################
#
#   DESTRUCTOR
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::DESTROY()
  PREINIT:
    CBC_METHOD(DESTROY);

  CODE:
    CT_DEBUG_METHOD;

    cbc_delete(aTHX_ THIS);

