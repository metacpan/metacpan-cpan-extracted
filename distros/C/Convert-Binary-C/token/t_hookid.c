static const char *gs_HookIdStr[] = {
  "pack",
  "unpack",
  "pack_ptr",
  "unpack_ptr"
};

static enum HookId get_hook_id(const char *hook)
{
switch (hook[0])
{
  case 'p':
    switch (hook[1])
    {
      case 'a':
        switch (hook[2])
        {
          case 'c':
            switch (hook[3])
            {
              case 'k':
                switch (hook[4])
                {
                  case '\0':
                    {                             /* pack       */
                      return HOOKID_pack;
                    }

                  case '_':
                    if (hook[5] == 'p' &&
                        hook[6] == 't' &&
                        hook[7] == 'r' &&
                        hook[8] == '\0')
                    {                             /* pack_ptr   */
                      return HOOKID_pack_ptr;
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

  case 'u':
    switch (hook[1])
    {
      case 'n':
        switch (hook[2])
        {
          case 'p':
            switch (hook[3])
            {
              case 'a':
                switch (hook[4])
                {
                  case 'c':
                    switch (hook[5])
                    {
                      case 'k':
                        switch (hook[6])
                        {
                          case '\0':
                            {                     /* unpack     */
                              return HOOKID_unpack;
                            }

                          case '_':
                            if (hook[7] == 'p' &&
                                hook[8] == 't' &&
                                hook[9] == 'r' &&
                                hook[10] == '\0')
                            {                     /* unpack_ptr */
                              return HOOKID_unpack_ptr;
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

unknown:
  return HOOKID_INVALID;
}
