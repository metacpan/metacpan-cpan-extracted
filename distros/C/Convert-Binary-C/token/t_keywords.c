switch (str[0])
{
  case 'a':
    switch (str[1])
    {
      case 's':
        if (str[2] == 'm' &&
            str[3] == '\0')
        {                                         /* asm      */
          keywords &= ~HAS_KEYWORD_ASM;
          goto success;
        }

        goto unknown;

      case 'u':
        if (str[2] == 't' &&
            str[3] == 'o' &&
            str[4] == '\0')
        {                                         /* auto     */
          keywords &= ~HAS_KEYWORD_AUTO;
          goto success;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'c':
    if (str[1] == 'o' &&
        str[2] == 'n' &&
        str[3] == 's' &&
        str[4] == 't' &&
        str[5] == '\0')
    {                                             /* const    */
      keywords &= ~HAS_KEYWORD_CONST;
      goto success;
    }

    goto unknown;

  case 'd':
    if (str[1] == 'o' &&
        str[2] == 'u' &&
        str[3] == 'b' &&
        str[4] == 'l' &&
        str[5] == 'e' &&
        str[6] == '\0')
    {                                             /* double   */
      keywords &= ~HAS_KEYWORD_DOUBLE;
      goto success;
    }

    goto unknown;

  case 'e':
    switch (str[1])
    {
      case 'n':
        if (str[2] == 'u' &&
            str[3] == 'm' &&
            str[4] == '\0')
        {                                         /* enum     */
          keywords &= ~HAS_KEYWORD_ENUM;
          goto success;
        }

        goto unknown;

      case 'x':
        if (str[2] == 't' &&
            str[3] == 'e' &&
            str[4] == 'r' &&
            str[5] == 'n' &&
            str[6] == '\0')
        {                                         /* extern   */
          keywords &= ~HAS_KEYWORD_EXTERN;
          goto success;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'f':
    if (str[1] == 'l' &&
        str[2] == 'o' &&
        str[3] == 'a' &&
        str[4] == 't' &&
        str[5] == '\0')
    {                                             /* float    */
      keywords &= ~HAS_KEYWORD_FLOAT;
      goto success;
    }

    goto unknown;

  case 'i':
    if (str[1] == 'n' &&
        str[2] == 'l' &&
        str[3] == 'i' &&
        str[4] == 'n' &&
        str[5] == 'e' &&
        str[6] == '\0')
    {                                             /* inline   */
      keywords &= ~HAS_KEYWORD_INLINE;
      goto success;
    }

    goto unknown;

  case 'l':
    if (str[1] == 'o' &&
        str[2] == 'n' &&
        str[3] == 'g' &&
        str[4] == '\0')
    {                                             /* long     */
      keywords &= ~HAS_KEYWORD_LONG;
      goto success;
    }

    goto unknown;

  case 'r':
    switch (str[1])
    {
      case 'e':
        switch (str[2])
        {
          case 'g':
            if (str[3] == 'i' &&
                str[4] == 's' &&
                str[5] == 't' &&
                str[6] == 'e' &&
                str[7] == 'r' &&
                str[8] == '\0')
            {                                     /* register */
              keywords &= ~HAS_KEYWORD_REGISTER;
              goto success;
            }

            goto unknown;

          case 's':
            if (str[3] == 't' &&
                str[4] == 'r' &&
                str[5] == 'i' &&
                str[6] == 'c' &&
                str[7] == 't' &&
                str[8] == '\0')
            {                                     /* restrict */
              keywords &= ~HAS_KEYWORD_RESTRICT;
              goto success;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 's':
    switch (str[1])
    {
      case 'h':
        if (str[2] == 'o' &&
            str[3] == 'r' &&
            str[4] == 't' &&
            str[5] == '\0')
        {                                         /* short    */
          keywords &= ~HAS_KEYWORD_SHORT;
          goto success;
        }

        goto unknown;

      case 'i':
        if (str[2] == 'g' &&
            str[3] == 'n' &&
            str[4] == 'e' &&
            str[5] == 'd' &&
            str[6] == '\0')
        {                                         /* signed   */
          keywords &= ~HAS_KEYWORD_SIGNED;
          goto success;
        }

        goto unknown;

      case 't':
        if (str[2] == 'a' &&
            str[3] == 't' &&
            str[4] == 'i' &&
            str[5] == 'c' &&
            str[6] == '\0')
        {                                         /* static   */
          keywords &= ~HAS_KEYWORD_STATIC;
          goto success;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'u':
    if (str[1] == 'n' &&
        str[2] == 's' &&
        str[3] == 'i' &&
        str[4] == 'g' &&
        str[5] == 'n' &&
        str[6] == 'e' &&
        str[7] == 'd' &&
        str[8] == '\0')
    {                                             /* unsigned */
      keywords &= ~HAS_KEYWORD_UNSIGNED;
      goto success;
    }

    goto unknown;

  case 'v':
    switch (str[1])
    {
      case 'o':
        switch (str[2])
        {
          case 'i':
            if (str[3] == 'd' &&
                str[4] == '\0')
            {                                     /* void     */
              keywords &= ~HAS_KEYWORD_VOID;
              goto success;
            }

            goto unknown;

          case 'l':
            if (str[3] == 'a' &&
                str[4] == 't' &&
                str[5] == 'i' &&
                str[6] == 'l' &&
                str[7] == 'e' &&
                str[8] == '\0')
            {                                     /* volatile */
              keywords &= ~HAS_KEYWORD_VOLATILE;
              goto success;
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
