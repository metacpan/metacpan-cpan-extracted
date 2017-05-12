switch (tokstr[0])
{
  case 'a':
    switch (tokstr[1])
    {
      case 's':
        if (tokstr[2] == 'm' &&
            tokstr[3] == '\0')
        {                                         /* asm      */
          if( pState->pCPC->keywords & HAS_KEYWORD_ASM )
            return ASM_TOK;
        }

        goto unknown;

      case 'u':
        if (tokstr[2] == 't' &&
            tokstr[3] == 'o' &&
            tokstr[4] == '\0')
        {                                         /* auto     */
          if( pState->pCPC->keywords & HAS_KEYWORD_AUTO )
            return AUTO_TOK;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'b':
    if (tokstr[1] == 'r' &&
        tokstr[2] == 'e' &&
        tokstr[3] == 'a' &&
        tokstr[4] == 'k' &&
        tokstr[5] == '\0')
    {                                             /* break    */
      return BREAK_TOK;
    }

    goto unknown;

  case 'c':
    switch (tokstr[1])
    {
      case 'a':
        if (tokstr[2] == 's' &&
            tokstr[3] == 'e' &&
            tokstr[4] == '\0')
        {                                         /* case     */
          return CASE_TOK;
        }

        goto unknown;

      case 'h':
        if (tokstr[2] == 'a' &&
            tokstr[3] == 'r' &&
            tokstr[4] == '\0')
        {                                         /* char     */
          return CHAR_TOK;
        }

        goto unknown;

      case 'o':
        switch (tokstr[2])
        {
          case 'n':
            switch (tokstr[3])
            {
              case 's':
                if (tokstr[4] == 't' &&
                    tokstr[5] == '\0')
                {                                 /* const    */
                  if( pState->pCPC->keywords & HAS_KEYWORD_CONST )
                    return CONST_TOK;
                }

                goto unknown;

              case 't':
                if (tokstr[4] == 'i' &&
                    tokstr[5] == 'n' &&
                    tokstr[6] == 'u' &&
                    tokstr[7] == 'e' &&
                    tokstr[8] == '\0')
                {                                 /* continue */
                  return CONTINUE_TOK;
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
    switch (tokstr[1])
    {
      case 'e':
        if (tokstr[2] == 'f' &&
            tokstr[3] == 'a' &&
            tokstr[4] == 'u' &&
            tokstr[5] == 'l' &&
            tokstr[6] == 't' &&
            tokstr[7] == '\0')
        {                                         /* default  */
          return DEFAULT_TOK;
        }

        goto unknown;

      case 'o':
        switch (tokstr[2])
        {
          case '\0':
            {                                     /* do       */
              return DO_TOK;
            }

          case 'u':
            if (tokstr[3] == 'b' &&
                tokstr[4] == 'l' &&
                tokstr[5] == 'e' &&
                tokstr[6] == '\0')
            {                                     /* double   */
              if( pState->pCPC->keywords & HAS_KEYWORD_DOUBLE )
                return DOUBLE_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'e':
    switch (tokstr[1])
    {
      case 'l':
        if (tokstr[2] == 's' &&
            tokstr[3] == 'e' &&
            tokstr[4] == '\0')
        {                                         /* else     */
          return ELSE_TOK;
        }

        goto unknown;

      case 'n':
        if (tokstr[2] == 'u' &&
            tokstr[3] == 'm' &&
            tokstr[4] == '\0')
        {                                         /* enum     */
          if( pState->pCPC->keywords & HAS_KEYWORD_ENUM )
            return ENUM_TOK;
        }

        goto unknown;

      case 'x':
        if (tokstr[2] == 't' &&
            tokstr[3] == 'e' &&
            tokstr[4] == 'r' &&
            tokstr[5] == 'n' &&
            tokstr[6] == '\0')
        {                                         /* extern   */
          if( pState->pCPC->keywords & HAS_KEYWORD_EXTERN )
            return EXTERN_TOK;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'f':
    switch (tokstr[1])
    {
      case 'l':
        if (tokstr[2] == 'o' &&
            tokstr[3] == 'a' &&
            tokstr[4] == 't' &&
            tokstr[5] == '\0')
        {                                         /* float    */
          if( pState->pCPC->keywords & HAS_KEYWORD_FLOAT )
            return FLOAT_TOK;
        }

        goto unknown;

      case 'o':
        if (tokstr[2] == 'r' &&
            tokstr[3] == '\0')
        {                                         /* for      */
          return FOR_TOK;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'g':
    if (tokstr[1] == 'o' &&
        tokstr[2] == 't' &&
        tokstr[3] == 'o' &&
        tokstr[4] == '\0')
    {                                             /* goto     */
      return GOTO_TOK;
    }

    goto unknown;

  case 'i':
    switch (tokstr[1])
    {
      case 'f':
        if (tokstr[2] == '\0')
        {                                         /* if       */
          return IF_TOK;
        }

        goto unknown;

      case 'n':
        switch (tokstr[2])
        {
          case 'l':
            if (tokstr[3] == 'i' &&
                tokstr[4] == 'n' &&
                tokstr[5] == 'e' &&
                tokstr[6] == '\0')
            {                                     /* inline   */
              if( pState->pCPC->keywords & HAS_KEYWORD_INLINE )
                return INLINE_TOK;
            }

            goto unknown;

          case 't':
            if (tokstr[3] == '\0')
            {                                     /* int      */
              return INT_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'l':
    if (tokstr[1] == 'o' &&
        tokstr[2] == 'n' &&
        tokstr[3] == 'g' &&
        tokstr[4] == '\0')
    {                                             /* long     */
      if( pState->pCPC->keywords & HAS_KEYWORD_LONG )
        return LONG_TOK;
    }

    goto unknown;

  case 'r':
    switch (tokstr[1])
    {
      case 'e':
        switch (tokstr[2])
        {
          case 'g':
            if (tokstr[3] == 'i' &&
                tokstr[4] == 's' &&
                tokstr[5] == 't' &&
                tokstr[6] == 'e' &&
                tokstr[7] == 'r' &&
                tokstr[8] == '\0')
            {                                     /* register */
              if( pState->pCPC->keywords & HAS_KEYWORD_REGISTER )
                return REGISTER_TOK;
            }

            goto unknown;

          case 's':
            if (tokstr[3] == 't' &&
                tokstr[4] == 'r' &&
                tokstr[5] == 'i' &&
                tokstr[6] == 'c' &&
                tokstr[7] == 't' &&
                tokstr[8] == '\0')
            {                                     /* restrict */
              if( pState->pCPC->keywords & HAS_KEYWORD_RESTRICT )
                return RESTRICT_TOK;
            }

            goto unknown;

          case 't':
            if (tokstr[3] == 'u' &&
                tokstr[4] == 'r' &&
                tokstr[5] == 'n' &&
                tokstr[6] == '\0')
            {                                     /* return   */
              return RETURN_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 's':
    switch (tokstr[1])
    {
      case 'h':
        if (tokstr[2] == 'o' &&
            tokstr[3] == 'r' &&
            tokstr[4] == 't' &&
            tokstr[5] == '\0')
        {                                         /* short    */
          if( pState->pCPC->keywords & HAS_KEYWORD_SHORT )
            return SHORT_TOK;
        }

        goto unknown;

      case 'i':
        switch (tokstr[2])
        {
          case 'g':
            if (tokstr[3] == 'n' &&
                tokstr[4] == 'e' &&
                tokstr[5] == 'd' &&
                tokstr[6] == '\0')
            {                                     /* signed   */
              if( pState->pCPC->keywords & HAS_KEYWORD_SIGNED )
                return SIGNED_TOK;
            }

            goto unknown;

          case 'z':
            if (tokstr[3] == 'e' &&
                tokstr[4] == 'o' &&
                tokstr[5] == 'f' &&
                tokstr[6] == '\0')
            {                                     /* sizeof   */
              return SIZEOF_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 't':
        switch (tokstr[2])
        {
          case 'a':
            if (tokstr[3] == 't' &&
                tokstr[4] == 'i' &&
                tokstr[5] == 'c' &&
                tokstr[6] == '\0')
            {                                     /* static   */
              if( pState->pCPC->keywords & HAS_KEYWORD_STATIC )
                return STATIC_TOK;
            }

            goto unknown;

          case 'r':
            if (tokstr[3] == 'u' &&
                tokstr[4] == 'c' &&
                tokstr[5] == 't' &&
                tokstr[6] == '\0')
            {                                     /* struct   */
              return STRUCT_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 'w':
        if (tokstr[2] == 'i' &&
            tokstr[3] == 't' &&
            tokstr[4] == 'c' &&
            tokstr[5] == 'h' &&
            tokstr[6] == '\0')
        {                                         /* switch   */
          return SWITCH_TOK;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 't':
    if (tokstr[1] == 'y' &&
        tokstr[2] == 'p' &&
        tokstr[3] == 'e' &&
        tokstr[4] == 'd' &&
        tokstr[5] == 'e' &&
        tokstr[6] == 'f' &&
        tokstr[7] == '\0')
    {                                             /* typedef  */
      return TYPEDEF_TOK;
    }

    goto unknown;

  case 'u':
    switch (tokstr[1])
    {
      case 'n':
        switch (tokstr[2])
        {
          case 'i':
            if (tokstr[3] == 'o' &&
                tokstr[4] == 'n' &&
                tokstr[5] == '\0')
            {                                     /* union    */
              return UNION_TOK;
            }

            goto unknown;

          case 's':
            if (tokstr[3] == 'i' &&
                tokstr[4] == 'g' &&
                tokstr[5] == 'n' &&
                tokstr[6] == 'e' &&
                tokstr[7] == 'd' &&
                tokstr[8] == '\0')
            {                                     /* unsigned */
              if( pState->pCPC->keywords & HAS_KEYWORD_UNSIGNED )
                return UNSIGNED_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'v':
    switch (tokstr[1])
    {
      case 'o':
        switch (tokstr[2])
        {
          case 'i':
            if (tokstr[3] == 'd' &&
                tokstr[4] == '\0')
            {                                     /* void     */
              if( pState->pCPC->keywords & HAS_KEYWORD_VOID )
                return VOID_TOK;
            }

            goto unknown;

          case 'l':
            if (tokstr[3] == 'a' &&
                tokstr[4] == 't' &&
                tokstr[5] == 'i' &&
                tokstr[6] == 'l' &&
                tokstr[7] == 'e' &&
                tokstr[8] == '\0')
            {                                     /* volatile */
              if( pState->pCPC->keywords & HAS_KEYWORD_VOLATILE )
                return VOLATILE_TOK;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'w':
    if (tokstr[1] == 'h' &&
        tokstr[2] == 'i' &&
        tokstr[3] == 'l' &&
        tokstr[4] == 'e' &&
        tokstr[5] == '\0')
    {                                             /* while    */
      return WHILE_TOK;
    }

    goto unknown;

  default:
    goto unknown;
}
