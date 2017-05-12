switch (c[0])
{
  case 'c':
    if (c[1] == 'h' &&
        c[2] == 'a' &&
        c[3] == 'r' &&
        c[4] == *name)
    {                                             /* char     */
      tflags |= T_CHAR;
      goto success;
    }

    goto unknown;

  case 'd':
    if (c[1] == 'o' &&
        c[2] == 'u' &&
        c[3] == 'b' &&
        c[4] == 'l' &&
        c[5] == 'e' &&
        c[6] == *name)
    {                                             /* double   */
      tflags |= T_DOUBLE;
      goto success;
    }

    goto unknown;

  case 'f':
    if (c[1] == 'l' &&
        c[2] == 'o' &&
        c[3] == 'a' &&
        c[4] == 't' &&
        c[5] == *name)
    {                                             /* float    */
      tflags |= T_FLOAT;
      goto success;
    }

    goto unknown;

  case 'i':
    if (c[1] == 'n' &&
        c[2] == 't' &&
        c[3] == *name)
    {                                             /* int      */
      tflags |= T_INT;
      goto success;
    }

    goto unknown;

  case 'l':
    if (c[1] == 'o' &&
        c[2] == 'n' &&
        c[3] == 'g' &&
        c[4] == *name)
    {                                             /* long     */
      tflags |= tflags & T_LONG ? T_LONGLONG : T_LONG;
      goto success;
    }

    goto unknown;

  case 's':
    switch (c[1])
    {
      case 'h':
        if (c[2] == 'o' &&
            c[3] == 'r' &&
            c[4] == 't' &&
            c[5] == *name)
        {                                         /* short    */
          tflags |= T_SHORT;
          goto success;
        }

        goto unknown;

      case 'i':
        if (c[2] == 'g' &&
            c[3] == 'n' &&
            c[4] == 'e' &&
            c[5] == 'd' &&
            c[6] == *name)
        {                                         /* signed   */
          tflags |= T_SIGNED;
          goto success;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'u':
    if (c[1] == 'n' &&
        c[2] == 's' &&
        c[3] == 'i' &&
        c[4] == 'g' &&
        c[5] == 'n' &&
        c[6] == 'e' &&
        c[7] == 'd' &&
        c[8] == *name)
    {                                             /* unsigned */
      tflags |= T_UNSIGNED;
      goto success;
    }

    goto unknown;

  default:
    goto unknown;
}
