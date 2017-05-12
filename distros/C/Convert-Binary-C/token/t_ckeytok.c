switch (name[0])
{
  case 'a':
    switch (name[1])
    {
      case 's':
        if (name[2] == 'm' &&
            name[3] == '\0')
        {                                         /* asm      */
          static const CKeywordToken ckt = { ASM_TOK, "asm" };
          return &ckt;
        }

        goto unknown;

      case 'u':
        if (name[2] == 't' &&
            name[3] == 'o' &&
            name[4] == '\0')
        {                                         /* auto     */
          static const CKeywordToken ckt = { AUTO_TOK, "auto" };
          return &ckt;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'b':
    if (name[1] == 'r' &&
        name[2] == 'e' &&
        name[3] == 'a' &&
        name[4] == 'k' &&
        name[5] == '\0')
    {                                             /* break    */
      static const CKeywordToken ckt = { BREAK_TOK, "break" };
      return &ckt;
    }

    goto unknown;

  case 'c':
    switch (name[1])
    {
      case 'a':
        if (name[2] == 's' &&
            name[3] == 'e' &&
            name[4] == '\0')
        {                                         /* case     */
          static const CKeywordToken ckt = { CASE_TOK, "case" };
          return &ckt;
        }

        goto unknown;

      case 'h':
        if (name[2] == 'a' &&
            name[3] == 'r' &&
            name[4] == '\0')
        {                                         /* char     */
          static const CKeywordToken ckt = { CHAR_TOK, "char" };
          return &ckt;
        }

        goto unknown;

      case 'o':
        switch (name[2])
        {
          case 'n':
            switch (name[3])
            {
              case 's':
                if (name[4] == 't' &&
                    name[5] == '\0')
                {                                 /* const    */
                  static const CKeywordToken ckt = { CONST_TOK, "const" };
                  return &ckt;
                }

                goto unknown;

              case 't':
                if (name[4] == 'i' &&
                    name[5] == 'n' &&
                    name[6] == 'u' &&
                    name[7] == 'e' &&
                    name[8] == '\0')
                {                                 /* continue */
                  static const CKeywordToken ckt = { CONTINUE_TOK, "continue" };
                  return &ckt;
                }

                goto unknown;

              default:
                goto unknown;
            }

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'd':
    switch (name[1])
    {
      case 'e':
        if (name[2] == 'f' &&
            name[3] == 'a' &&
            name[4] == 'u' &&
            name[5] == 'l' &&
            name[6] == 't' &&
            name[7] == '\0')
        {                                         /* default  */
          static const CKeywordToken ckt = { DEFAULT_TOK, "default" };
          return &ckt;
        }

        goto unknown;

      case 'o':
        switch (name[2])
        {
          case '\0':
            {                                     /* do       */
              static const CKeywordToken ckt = { DO_TOK, "do" };
              return &ckt;
            }

          case 'u':
            if (name[3] == 'b' &&
                name[4] == 'l' &&
                name[5] == 'e' &&
                name[6] == '\0')
            {                                     /* double   */
              static const CKeywordToken ckt = { DOUBLE_TOK, "double" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'e':
    switch (name[1])
    {
      case 'l':
        if (name[2] == 's' &&
            name[3] == 'e' &&
            name[4] == '\0')
        {                                         /* else     */
          static const CKeywordToken ckt = { ELSE_TOK, "else" };
          return &ckt;
        }

        goto unknown;

      case 'n':
        if (name[2] == 'u' &&
            name[3] == 'm' &&
            name[4] == '\0')
        {                                         /* enum     */
          static const CKeywordToken ckt = { ENUM_TOK, "enum" };
          return &ckt;
        }

        goto unknown;

      case 'x':
        if (name[2] == 't' &&
            name[3] == 'e' &&
            name[4] == 'r' &&
            name[5] == 'n' &&
            name[6] == '\0')
        {                                         /* extern   */
          static const CKeywordToken ckt = { EXTERN_TOK, "extern" };
          return &ckt;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'f':
    switch (name[1])
    {
      case 'l':
        if (name[2] == 'o' &&
            name[3] == 'a' &&
            name[4] == 't' &&
            name[5] == '\0')
        {                                         /* float    */
          static const CKeywordToken ckt = { FLOAT_TOK, "float" };
          return &ckt;
        }

        goto unknown;

      case 'o':
        if (name[2] == 'r' &&
            name[3] == '\0')
        {                                         /* for      */
          static const CKeywordToken ckt = { FOR_TOK, "for" };
          return &ckt;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'g':
    if (name[1] == 'o' &&
        name[2] == 't' &&
        name[3] == 'o' &&
        name[4] == '\0')
    {                                             /* goto     */
      static const CKeywordToken ckt = { GOTO_TOK, "goto" };
      return &ckt;
    }

    goto unknown;

  case 'i':
    switch (name[1])
    {
      case 'f':
        if (name[2] == '\0')
        {                                         /* if       */
          static const CKeywordToken ckt = { IF_TOK, "if" };
          return &ckt;
        }

        goto unknown;

      case 'n':
        switch (name[2])
        {
          case 'l':
            if (name[3] == 'i' &&
                name[4] == 'n' &&
                name[5] == 'e' &&
                name[6] == '\0')
            {                                     /* inline   */
              static const CKeywordToken ckt = { INLINE_TOK, "inline" };
              return &ckt;
            }

            goto unknown;

          case 't':
            if (name[3] == '\0')
            {                                     /* int      */
              static const CKeywordToken ckt = { INT_TOK, "int" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'l':
    if (name[1] == 'o' &&
        name[2] == 'n' &&
        name[3] == 'g' &&
        name[4] == '\0')
    {                                             /* long     */
      static const CKeywordToken ckt = { LONG_TOK, "long" };
      return &ckt;
    }

    goto unknown;

  case 'r':
    switch (name[1])
    {
      case 'e':
        switch (name[2])
        {
          case 'g':
            if (name[3] == 'i' &&
                name[4] == 's' &&
                name[5] == 't' &&
                name[6] == 'e' &&
                name[7] == 'r' &&
                name[8] == '\0')
            {                                     /* register */
              static const CKeywordToken ckt = { REGISTER_TOK, "register" };
              return &ckt;
            }

            goto unknown;

          case 's':
            if (name[3] == 't' &&
                name[4] == 'r' &&
                name[5] == 'i' &&
                name[6] == 'c' &&
                name[7] == 't' &&
                name[8] == '\0')
            {                                     /* restrict */
              static const CKeywordToken ckt = { RESTRICT_TOK, "restrict" };
              return &ckt;
            }

            goto unknown;

          case 't':
            if (name[3] == 'u' &&
                name[4] == 'r' &&
                name[5] == 'n' &&
                name[6] == '\0')
            {                                     /* return   */
              static const CKeywordToken ckt = { RETURN_TOK, "return" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 's':
    switch (name[1])
    {
      case 'h':
        if (name[2] == 'o' &&
            name[3] == 'r' &&
            name[4] == 't' &&
            name[5] == '\0')
        {                                         /* short    */
          static const CKeywordToken ckt = { SHORT_TOK, "short" };
          return &ckt;
        }

        goto unknown;

      case 'i':
        switch (name[2])
        {
          case 'g':
            if (name[3] == 'n' &&
                name[4] == 'e' &&
                name[5] == 'd' &&
                name[6] == '\0')
            {                                     /* signed   */
              static const CKeywordToken ckt = { SIGNED_TOK, "signed" };
              return &ckt;
            }

            goto unknown;

          case 'z':
            if (name[3] == 'e' &&
                name[4] == 'o' &&
                name[5] == 'f' &&
                name[6] == '\0')
            {                                     /* sizeof   */
              static const CKeywordToken ckt = { SIZEOF_TOK, "sizeof" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 't':
        switch (name[2])
        {
          case 'a':
            if (name[3] == 't' &&
                name[4] == 'i' &&
                name[5] == 'c' &&
                name[6] == '\0')
            {                                     /* static   */
              static const CKeywordToken ckt = { STATIC_TOK, "static" };
              return &ckt;
            }

            goto unknown;

          case 'r':
            if (name[3] == 'u' &&
                name[4] == 'c' &&
                name[5] == 't' &&
                name[6] == '\0')
            {                                     /* struct   */
              static const CKeywordToken ckt = { STRUCT_TOK, "struct" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 'w':
        if (name[2] == 'i' &&
            name[3] == 't' &&
            name[4] == 'c' &&
            name[5] == 'h' &&
            name[6] == '\0')
        {                                         /* switch   */
          static const CKeywordToken ckt = { SWITCH_TOK, "switch" };
          return &ckt;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 't':
    if (name[1] == 'y' &&
        name[2] == 'p' &&
        name[3] == 'e' &&
        name[4] == 'd' &&
        name[5] == 'e' &&
        name[6] == 'f' &&
        name[7] == '\0')
    {                                             /* typedef  */
      static const CKeywordToken ckt = { TYPEDEF_TOK, "typedef" };
      return &ckt;
    }

    goto unknown;

  case 'u':
    switch (name[1])
    {
      case 'n':
        switch (name[2])
        {
          case 'i':
            if (name[3] == 'o' &&
                name[4] == 'n' &&
                name[5] == '\0')
            {                                     /* union    */
              static const CKeywordToken ckt = { UNION_TOK, "union" };
              return &ckt;
            }

            goto unknown;

          case 's':
            if (name[3] == 'i' &&
                name[4] == 'g' &&
                name[5] == 'n' &&
                name[6] == 'e' &&
                name[7] == 'd' &&
                name[8] == '\0')
            {                                     /* unsigned */
              static const CKeywordToken ckt = { UNSIGNED_TOK, "unsigned" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'v':
    switch (name[1])
    {
      case 'o':
        switch (name[2])
        {
          case 'i':
            if (name[3] == 'd' &&
                name[4] == '\0')
            {                                     /* void     */
              static const CKeywordToken ckt = { VOID_TOK, "void" };
              return &ckt;
            }

            goto unknown;

          case 'l':
            if (name[3] == 'a' &&
                name[4] == 't' &&
                name[5] == 'i' &&
                name[6] == 'l' &&
                name[7] == 'e' &&
                name[8] == '\0')
            {                                     /* volatile */
              static const CKeywordToken ckt = { VOLATILE_TOK, "volatile" };
              return &ckt;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'w':
    if (name[1] == 'h' &&
        name[2] == 'i' &&
        name[3] == 'l' &&
        name[4] == 'e' &&
        name[5] == '\0')
    {                                             /* while    */
      static const CKeywordToken ckt = { WHILE_TOK, "while" };
      return &ckt;
    }

    goto unknown;

  default:
    goto unknown;
}
