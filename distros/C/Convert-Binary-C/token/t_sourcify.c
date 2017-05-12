typedef enum {
  SOURCIFY_OPTION_Context,
  SOURCIFY_OPTION_Defines,
  INVALID_SOURCIFY_OPTION
} SourcifyConfigOption;

static SourcifyConfigOption get_sourcify_config_option( const char *option )
{
switch (option[0])
{
  case 'C':
    if (option[1] == 'o' &&
        option[2] == 'n' &&
        option[3] == 't' &&
        option[4] == 'e' &&
        option[5] == 'x' &&
        option[6] == 't' &&
        option[7] == '\0')
    {                                             /* Context */
      return SOURCIFY_OPTION_Context;
    }

    goto unknown;

  case 'D':
    if (option[1] == 'e' &&
        option[2] == 'f' &&
        option[3] == 'i' &&
        option[4] == 'n' &&
        option[5] == 'e' &&
        option[6] == 's' &&
        option[7] == '\0')
    {                                             /* Defines */
      return SOURCIFY_OPTION_Defines;
    }

    goto unknown;

  default:
    goto unknown;
}

unknown:
  return INVALID_SOURCIFY_OPTION;
}
