#include "mod_perl.h"
#include "mod_icon.h"

typedef char * Apache__Icon;

static void icon_add_magic(SV *sv, request_rec *r)
{
    sv_magic(SvRV(sv), Nullsv, '~', (char *)r, sizeof(request_rec));
}

#define default_by_path S_ISDIR(r->finfo.st_mode) ? 1 : 0
#define default_r       perl_request_rec(NULL)

MODULE = Apache::Icon   PACKAGE = Apache::Icon   PREFIX = ap_icon_

BOOT:
    ap_add_module(&icon_module);

PROTOTYPES: DISABLE

Apache::Icon
new(class, r=default_r)
    char *class
    Apache r

    CODE:
    RETVAL = class;

    OUTPUT:
    RETVAL

    CLEANUP:
    icon_add_magic(ST(0), r);

char *
ap_icon_find(r, po=default_by_path)
    Apache r
    int po

char *
ap_icon_alt(r, po=default_by_path)
    Apache r
    int po

char *
ap_icon_default(r, name=NULL)
    Apache r
    char *name



