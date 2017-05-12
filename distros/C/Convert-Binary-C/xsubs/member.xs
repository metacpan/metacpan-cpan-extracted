################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: member
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::member(type, offset = NULL)
  const char *type
  SV *offset

  PREINIT:
    CBC_METHOD(member);
    MemberInfo mi;
    int have_offset, off;

  PPCODE:
    off = (have_offset = DEFINED(offset)) ? SvIV(offset) : 0;

    CT_DEBUG_METHOD2("'%s', %d", type, off);

    CHECK_PARSE_DATA;
    CHECK_VOID_CONTEXT;

    NEED_PARSE_DATA;

    if (!get_member_info(aTHX_ THIS, type, &mi, 0))
      Perl_croak(aTHX_ "Cannot find '%s'", type);

    check_allowed_types(aTHX_ &mi, method, ALLOW_STRUCTS
                                         | ALLOW_UNIONS
                                         | ALLOW_ARRAYS);

    if (mi.flags)
    {
      u_32 flags = mi.flags;

      /* bitfields are not a problem without offset given */
      if (!have_offset)
        flags &= ~T_HASBITFIELD;

      WARN_FLAGS(type, flags);
    }

    if (have_offset)
    {
      if (off < 0 || off >= (int) mi.size)
        Perl_croak(aTHX_ "Offset %d out of range (0 <= offset < %d)", off, mi.size);

      if (GIMME_V == G_ARRAY)
      {
        ListIterator li;
        GMSInfo info;
        SV     *member;
        int     count;

        info.hit = LL_new();
        info.off = LL_new();
        info.pad = LL_new();

        (void) get_member_string(aTHX_ &mi, off, &info);

        count = LL_count(info.hit)
              + LL_count(info.off)
              + LL_count(info.pad);

        EXTEND(SP, count);

        LL_foreach(member, li, info.hit)
          PUSHs(member);

        LL_foreach(member, li, info.off)
          PUSHs(member);

        LL_foreach(member, li, info.pad)
          PUSHs(member);

        LL_destroy(info.hit, NULL);
        LL_destroy(info.off, NULL);
        LL_destroy(info.pad, NULL);

        XSRETURN(count);
      }
      else
      {
        SV *member = get_member_string(aTHX_ &mi, off, NULL);
        PUSHs(member);
        XSRETURN(1);
      }
    }
    else
    {
      LinkedList list;
      SV *member;
      int count;

      list = GIMME_V == G_ARRAY ? LL_new() : NULL;
      count = get_all_member_strings(aTHX_ &mi, list);

      if (GIMME_V == G_ARRAY)
      {
        ListIterator li;

        EXTEND(SP, count);

        LL_foreach(member, li, list)
          PUSHs(member);

        LL_destroy(list, NULL);

        XSRETURN(count);
      }
      else
        XSRETURN_IV(count);
    }

