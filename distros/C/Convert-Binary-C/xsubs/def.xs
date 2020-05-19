################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################


################################################################################
#
#   METHOD: def
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2002
#   CHANGED BY:                                   ON:
#
################################################################################

char *
CBC::def(type)
  const char *type

  PREINIT:
    CBC_METHOD(def);
    MemberInfo mi;
    const char *member = NULL;

  CODE:
    CT_DEBUG_METHOD1("'%s'", type);

    CHECK_VOID_CONTEXT;

    if (get_type_spec(THIS, type, &member, &mi.type) == 0)
      XSRETURN_UNDEF;

    if (mi.type.ptr == NULL)
      RETVAL = "basic";
    else
    {
      void *ptr = mi.type.ptr;
      switch (GET_CTYPE(ptr))
      {
        case TYP_TYPEDEF:
          RETVAL = is_typedef_defined((Typedef *) ptr) ? "typedef" : "";
          break;

        case TYP_STRUCT:
          if (((Struct *) ptr)->declarations)
            RETVAL = ((Struct *) ptr)->tflags & T_STRUCT ? "struct" : "union";
          else
            RETVAL = "";
          break;

        case TYP_ENUM:
          RETVAL = ((EnumSpecifier *) ptr)->enumerators ? "enum" : "";
          break;

        default:
          fatal("Invalid type (%d) in " XSCLASS "::%s( '%s' )",
                GET_CTYPE(ptr), method, type);
          break;
      }
      if (member && *member != '\0' && *RETVAL != '\0')
      {
        mi.pDecl = NULL;
        mi.level = 0;
        RETVAL = get_member(aTHX_ &mi, member, NULL, CBC_GM_DONT_CROAK | CBC_GM_NO_OFFSET_SIZE_CALC)
                 ? "member" : "";
      }
    }

  OUTPUT:
    RETVAL

