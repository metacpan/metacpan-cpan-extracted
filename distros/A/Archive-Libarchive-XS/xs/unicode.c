#include <string.h>

#if defined(__CYGWIN__) || !defined(_WIN32)
#include <langinfo.h>
#include <locale.h>
#endif
#include "perl_archive.h"

const char *
archive_perl_codeset(void)
{
#if defined(__CYGWIN__) || !defined(_WIN32)
  return nl_langinfo(CODESET);
#else
  return "ANSI_X3.4-1968";
#endif
}

int
archive_perl_utf8_mode(void)
{
#if defined(__CYGWIN__) || !defined(_WIN32)
  return strcmp(nl_langinfo(CODESET), "UTF-8") == 0;
#else
  return 0;
#endif
}
