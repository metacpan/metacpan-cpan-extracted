#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

I32 hash_name_filter(pTHX_ IV action, SV* val) {
	MAGIC* magic = mg_find(val, PERL_MAGIC_uvar);
	if (strstr(SvPV_nolen(magic->mg_obj), "::") == NULL)
		magic->mg_obj = sv_2mortal(newSVpvf("%s::%s", CopSTASHPV(PL_curcop), SvPV_nolen(magic->mg_obj)));
	return 0;
}

static const struct ufuncs hash_filter = { hash_name_filter, NULL, 0 };

MODULE = Class::Private				PACKAGE = Class::Private

PROTOTYPES: DISABLED

SV*
new(class)
	SV* class;
	CODE:
		HV* hash = newHV();
		sv_magic((SV*)hash, NULL, PERL_MAGIC_uvar, (const char*)&hash_filter, sizeof hash_filter);
		RETVAL = sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, GV_ADD));
	OUTPUT:
		RETVAL
