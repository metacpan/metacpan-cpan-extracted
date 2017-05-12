switch (tokstr[0])
{
  case 'p':
    switch (tokstr[1])
    {
      case 'a':
        if (tokstr[2] == 'c' &&
            tokstr[3] == 'k' &&
            tokstr[4] == PRAGMA_TOKEN_END)
        {                                         /* pack */
          toklen = 4;
          tokval = PACK_TOK;
          goto success;
        }

        goto unknown;

      case 'o':
        if (tokstr[2] == 'p' &&
            tokstr[3] == PRAGMA_TOKEN_END)
        {                                         /* pop  */
          toklen = 3;
          tokval = POP_TOK;
          goto success;
        }

        goto unknown;

      case 'u':
        if (tokstr[2] == 's' &&
            tokstr[3] == 'h' &&
            tokstr[4] == PRAGMA_TOKEN_END)
        {                                         /* push */
          toklen = 4;
          tokval = PUSH_TOK;
          goto success;
        }

        goto unknown;

      default:
        goto unknown;
    }

  default:
    goto unknown;
}
