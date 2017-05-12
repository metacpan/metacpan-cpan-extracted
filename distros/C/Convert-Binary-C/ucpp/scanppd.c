static enum {
  PPDIR_DEFINE,
  PPDIR_UNDEF,
  PPDIR_IF,
  PPDIR_IFDEF,
  PPDIR_IFNDEF,
  PPDIR_ELSE,
  PPDIR_ELIF,
  PPDIR_ENDIF,
  PPDIR_INCLUDE,
  PPDIR_INCLUDE_NEXT,
  PPDIR_PRAGMA,
  PPDIR_ERROR,
  PPDIR_LINE,
  PPDIR_ASSERT,
  PPDIR_UNASSERT,
  PPDIR_IDENT,
  PPDIR_WARNING,
  PPDIR_UNKNOWN
}
scan_pp_directive(const char *ppdir)
{
switch( ppdir[0] )
{
  case 'a':
    if( ppdir[1] == 's' &&
        ppdir[2] == 's' &&
        ppdir[3] == 'e' &&
        ppdir[4] == 'r' &&
        ppdir[5] == 't' &&
        ppdir[6] == '\0' )
    {                                             /* assert     */
      return PPDIR_ASSERT;
    }

    goto unknown;

  case 'd':
    if( ppdir[1] == 'e' &&
        ppdir[2] == 'f' &&
        ppdir[3] == 'i' &&
        ppdir[4] == 'n' &&
        ppdir[5] == 'e' &&
        ppdir[6] == '\0' )
    {                                             /* define     */
      return PPDIR_DEFINE;
    }

    goto unknown;

  case 'e':
    switch( ppdir[1] )
    {
      case 'l':
        switch( ppdir[2] )
        {
          case 'i':
            if( ppdir[3] == 'f' &&
                ppdir[4] == '\0' )
            {                                     /* elif       */
              return PPDIR_ELIF;
            }

            goto unknown;

          case 's':
            if( ppdir[3] == 'e' &&
                ppdir[4] == '\0' )
            {                                     /* else       */
              return PPDIR_ELSE;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 'n':
        if( ppdir[2] == 'd' &&
            ppdir[3] == 'i' &&
            ppdir[4] == 'f' &&
            ppdir[5] == '\0' )
        {                                         /* endif      */
          return PPDIR_ENDIF;
        }

        goto unknown;

      case 'r':
        if( ppdir[2] == 'r' &&
            ppdir[3] == 'o' &&
            ppdir[4] == 'r' &&
            ppdir[5] == '\0' )
        {                                         /* error      */
          return PPDIR_ERROR;
        }

        goto unknown;

      default:
        goto unknown;
    }

  case 'i':
    switch( ppdir[1] )
    {
      case 'd':
        if( ppdir[2] == 'e' &&
            ppdir[3] == 'n' &&
            ppdir[4] == 't' &&
            ppdir[5] == '\0' )
        {                                         /* ident      */
          return PPDIR_IDENT;
        }

        goto unknown;

      case 'f':
        switch( ppdir[2] )
        {
          case '\0':
            {                                     /* if         */
              return PPDIR_IF;
            }

            goto unknown;

          case 'd':
            if( ppdir[3] == 'e' &&
                ppdir[4] == 'f' &&
                ppdir[5] == '\0' )
            {                                     /* ifdef      */
              return PPDIR_IFDEF;
            }

            goto unknown;

          case 'n':
            if( ppdir[3] == 'd' &&
                ppdir[4] == 'e' &&
                ppdir[5] == 'f' &&
                ppdir[6] == '\0' )
            {                                     /* ifndef     */
              return PPDIR_IFNDEF;
            }

            goto unknown;

          default:
            goto unknown;
        }

      case 'n':
        switch( ppdir[2] )
        {
          case 'c':
            switch( ppdir[3] )
            {
              case 'l':
                switch( ppdir[4] )
                {
                  case 'u':
                    switch( ppdir[5] )
                    {
                      case 'd':
                        switch( ppdir[6] )
                        {
                          case 'e':
                            switch( ppdir[7] )
                            {
                              case '\0':
                                {                 /* include    */
                                  return PPDIR_INCLUDE;
                                }

                                goto unknown;

                              case '_':
                                if( ppdir[8] == 'n' &&
                                    ppdir[9] == 'e' &&
                                    ppdir[10] == 'x' &&
                                    ppdir[11] == 't' &&
                                    ppdir[12] == '\0' )
                                {                 /* include_next */
                                  return PPDIR_INCLUDE_NEXT;
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

                  default:
                    goto unknown;
                }

              default:
                goto unknown;
            }

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'l':
    if( ppdir[1] == 'i' &&
        ppdir[2] == 'n' &&
        ppdir[3] == 'e' &&
        ppdir[4] == '\0' )
    {                                             /* line       */
      return PPDIR_LINE;
    }

    goto unknown;

  case 'p':
    if( ppdir[1] == 'r' &&
        ppdir[2] == 'a' &&
        ppdir[3] == 'g' &&
        ppdir[4] == 'm' &&
        ppdir[5] == 'a' &&
        ppdir[6] == '\0' )
    {                                             /* pragma     */
      return PPDIR_PRAGMA;
    }

    goto unknown;

  case 'u':
    switch( ppdir[1] )
    {
      case 'n':
        switch( ppdir[2] )
        {
          case 'a':
            if( ppdir[3] == 's' &&
                ppdir[4] == 's' &&
                ppdir[5] == 'e' &&
                ppdir[6] == 'r' &&
                ppdir[7] == 't' &&
                ppdir[8] == '\0' )
            {                                     /* unassert   */
              return PPDIR_UNASSERT;
            }

            goto unknown;

          case 'd':
            if( ppdir[3] == 'e' &&
                ppdir[4] == 'f' &&
                ppdir[5] == '\0' )
            {                                     /* undef      */
              return PPDIR_UNDEF;
            }

            goto unknown;

          default:
            goto unknown;
        }

      default:
        goto unknown;
    }

  case 'w':
    if( ppdir[1] == 'a' &&
        ppdir[2] == 'r' &&
        ppdir[3] == 'n' &&
        (ppdir[4] == '\0' ||
         (ppdir[4] == 'i' &&
          ppdir[5] == 'n' &&
          ppdir[6] == 'g' &&
          ppdir[7] == '\0' )))                       /* warning    */
    {
      return PPDIR_WARNING;
    }

    goto unknown;

  default:
    goto unknown;
}

unknown:
  return PPDIR_UNKNOWN;
}
