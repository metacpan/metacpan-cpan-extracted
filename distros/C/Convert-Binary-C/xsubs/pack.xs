################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: pack
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::pack(type, data = &PL_sv_undef, string = NULL)
  const char *type
  SV *data
  SV *string

  PREINIT:
    CBC_METHOD(pack);
    char *buffer;
    MemberInfo mi;
    PackHandle pack;
    SV *rv;
    dXCPT;

  CODE:
    CT_DEBUG_METHOD1("'%s'", type);

    if (string == NULL && GIMME_V == G_VOID)
    {
      WARN_VOID_CONTEXT;
      XSRETURN_EMPTY;
    }

    if (string != NULL)
    {
      SvGETMAGIC(string);
      
      if ((SvFLAGS(string) & (SVf_POK|SVp_POK)) == 0)
        Perl_croak(aTHX_ "Type of arg 3 to pack must be string");

      if (GIMME_V == G_VOID && SvREADONLY(string))
        Perl_croak(aTHX_ "Modification of a read-only value attempted");
    }

    NEED_PARSE_DATA;

    if (!get_member_info(aTHX_ THIS, type, &mi, 0))
      Perl_croak(aTHX_ "Cannot find '%s'", type);

    if (mi.flags)
      WARN_FLAGS(type, mi.flags);

    if (string == NULL)
    {
      rv = newSV(mi.size);

      /* force rv into a PV when mi.size is zero (bug #3753) */
      if (mi.size == 0)
        sv_grow(rv, 1);

      SvPOK_only(rv);
      SvCUR_set(rv, mi.size);
      buffer = SvPVX(rv);

      /* We get an mi.size+1 buffer from newSV. So the following */
      /* call will properly \0-terminate our return value.       */
      Zero(buffer, mi.size+1, char);
    }
    else
    {
      STRLEN len = SvCUR(string);
      STRLEN max = mi.size > len ? mi.size : len;

      if (GIMME_V == G_VOID)
      {
        rv = NULL;
        buffer = SvGROW(string, max+1);
        SvCUR_set(string, max);
      }
      else
      {
        rv = newSV(max);
        SvPOK_only(rv);
        buffer = SvPVX(rv);
        SvCUR_set(rv, max);
        Copy(SvPVX(string), buffer, len, char);
      }

      if(max > len)
        Zero(buffer+len, max+1-len, char);
    }

    pack = pk_create(THIS, ST(0));
    pk_set_type(pack, type);
    pk_set_buffer(pack, rv ? rv : string, buffer, mi.size);

    SvGETMAGIC(data);

    XCPT_TRY_START
    {
      pk_pack(aTHX_ pack, &mi.type, mi.pDecl, mi.level, data);
    }
    XCPT_TRY_END

    pk_delete(pack);

    XCPT_CATCH
    {
      if (rv)
        SvREFCNT_dec(rv);

      XCPT_RETHROW;
    }

    /* this makes substr() as third argument work */
    if (string)
      SvSETMAGIC(string);

    if (rv == NULL)
      XSRETURN_EMPTY;

    ST(0) = sv_2mortal(rv);
    XSRETURN(1);


################################################################################
#
#   METHOD: unpack
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Jan 2002
#   CHANGED BY:                                   ON:
#
################################################################################

void
CBC::unpack(type, string)
  const char *type
  SV *string

  PREINIT:
    CBC_METHOD(unpack);
    char *buf;
    STRLEN len;
    MemberInfo mi;
    unsigned long count;

  PPCODE:
    CT_DEBUG_METHOD1("'%s'", type);

    CHECK_VOID_CONTEXT;

    SvGETMAGIC(string);

    if ((SvFLAGS(string) & (SVf_POK|SVp_POK)) == 0)
      Perl_croak(aTHX_ "Type of arg 2 to unpack must be string");

    NEED_PARSE_DATA;

    if (!get_member_info(aTHX_ THIS, type, &mi, 0))
      Perl_croak(aTHX_ "Cannot find '%s'", type);

    if (mi.flags)
      WARN_FLAGS(type, mi.flags);

    buf = SvPV(string, len);

    if (GIMME_V == G_SCALAR)
    {
      if (mi.size > len)
        WARN((aTHX_ "Data too short"));

      count = 1;
    }
    else
      count = mi.size == 0 ? 1 : len / mi.size;

    if (count > 0)
    {
      dXCPT;
      unsigned long i;
      PackHandle pack;
      SV **sva;

      /* newHV_indexed() messes with the stack, so we cannot
       * store the return values on the stack immediately...
       */

      Newz(0, sva, count, SV *);

      pack = pk_create(THIS, ST(0));
      pk_set_buffer(pack, NULL, buf, len);

      XCPT_TRY_START
      {
        for (i = 0; i < count; i++)
        {
          pk_set_buffer_pos(pack, i*mi.size);
          sva[i] = pk_unpack(aTHX_ pack, &mi.type, mi.pDecl, mi.level);
        }

      }
      XCPT_TRY_END

      pk_delete(pack);
	      
      XCPT_CATCH
      {
        for (i = 0; i < count; i++)
          if (sva[i])
            SvREFCNT_dec(sva[i]);

        Safefree(sva);

        XCPT_RETHROW;
      }

      /* A hook may have moved our stack */
      SPAGAIN;
      SP -= items;

      EXTEND(SP, count);

      for (i = 0; i < count; i++)
        PUSHs(sv_2mortal(sva[i]));

      Safefree(sva);
    }

    XSRETURN(count);

