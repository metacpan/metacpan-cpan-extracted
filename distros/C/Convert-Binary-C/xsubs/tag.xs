################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: tag / untag
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Dec 2004
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::tag(type, ...)
  const char *type

  ALIAS:
    untag = 1

  PREINIT:
    CBC_METHOD_VAR;
    TagTypeInfo tti;
    CtTagList *taglist;

  CODE:
    switch (ix)
    {
      case 0:
        CBC_METHOD_SET("tag");
        break;

      case 1:
        CBC_METHOD_SET("untag");
        break;

      default:
        fatal("Invalid alias (%d) for tag method", ix);
        break;
    }

    CT_DEBUG_METHOD1("'%s'", type);

    if (ix == 0 && items <= 3 && GIMME_V == G_VOID)
    {
      WARN_VOID_CONTEXT;
      XSRETURN_EMPTY;
    }

    NEED_PARSE_DATA;

    tti.type = type;

    if (!get_member_info(aTHX_ THIS, type, &tti.mi, 0))
      Perl_croak(aTHX_ "Cannot find '%s'", type);

    if (tti.mi.level != 0)
      Perl_croak(aTHX_ "Cannot tag array members");

    taglist = tti.mi.pDecl ? &tti.mi.pDecl->tags
                           : find_taglist_ptr(tti.mi.type.ptr);

    assert(taglist != NULL);

    if (ix == 0) /* tag */
    {
      if (items == 2)
        ST(0) = get_tags(aTHX_ &tti, *taglist);
      else if (items == 3)
        handle_tag(aTHX_ &tti, taglist, ST(2), NULL, &ST(0));
      else if (items % 2 == 0)
      {
        int i;
        for (i = 2; i < items; i += 2)
          handle_tag(aTHX_ &tti, taglist, ST(i), ST(i+1), NULL);
      }
      else
        Perl_croak(aTHX_ "Invalid number of arguments to %s", method);
    }
    else /* untag */
    {
      if (items == 2)
        delete_all_tags(taglist);
      else
      {
        int i;
        for (i = 2; i < items; i++)
          handle_tag(aTHX_ &tti, taglist, ST(i), &PL_sv_undef, NULL);
      }
    }

    XSRETURN(1);

