#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define CORE_PRIVATE
#include "mod_perl.h"

char *
_get(Apache r) {
   core_dir_config *conf = ap_get_module_config(r->per_dir_config, &core_module);
   return conf->add_default_charset_name;
}

void
_set(Apache r, char *charset) {
    core_dir_config *conf = ap_get_module_config(r->per_dir_config, &core_module);
    conf->add_default_charset_name = charset;
    return;
}

MODULE = Apache::DefaultCharset   PACKAGE = Apache::DefaultCharset

PROTOTYPES: DISABLE

char *
_get(r)
  Apache r;
  CODE:
    RETVAL = _get(r);
  OUTPUT:
    RETVAL

void
_set(r, charset)
  Apache r;
  char *charset;
  CODE:
    _set(r, charset);

