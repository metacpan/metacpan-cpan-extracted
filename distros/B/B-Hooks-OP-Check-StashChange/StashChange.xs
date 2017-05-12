#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check_stashchange.h"

typedef struct userdata_St {
	hook_op_check_stashchange_cb cb;
	void *ud;
} userdata_t;

STATIC char *last_stash = NULL;

STATIC OP *
stash_change_cb (pTHX_ OP *op, void *user_data) {
	userdata_t *ud = (userdata_t *)user_data;
	char *new_stash = HvNAME (PL_curstash);

	if (!last_stash || strNE (last_stash, new_stash)) {
		op = ud->cb(aTHX_ op, new_stash, last_stash, ud->ud);
		last_stash = new_stash;
	}

	return op;
}

UV
hook_op_check_stashchange (hook_op_check_stashchange_cb cb, void *user_data) {
	I32 i;
	userdata_t *ud;
	AV *ret = newAV ();

	Newx (ud, 1, userdata_t);
	ud->cb = cb;
	ud->ud = user_data;

	av_extend (ret, OP_max);
	for (i = 0; i < OP_max; i++) {
		av_store (ret, i, newSVuv ((UV) hook_op_check (i, stash_change_cb, ud)));
	}

	return PTR2UV (ret);
}

void *
hook_op_check_stashchange_remove (UV id) {
	void *ret;
	AV *ids = INT2PTR (AV *, id);
	I32 i;
	userdata_t *ud;

	for (i = 0; i < OP_max; i++) {
		SV **sv = av_fetch (ids, i, 0);

		if (!sv || !*sv) {
			continue;
		}

		ud = (userdata_t *)hook_op_check_remove (i, (hook_op_check_id)SvUV (*sv));
	}

	SvREFCNT_dec ((SV *)ids);

	if (!ud) {
		return NULL;
	}

	ret = ud->ud;
	Safefree (ud);

	return ret;
}

STATIC OP *
perl_cb (pTHX_ OP *op, const char *new_stash, const char *old_stash, void *user_data) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK (SP);
    EXTEND (SP, 2);
    PUSHs (sv_2mortal (newSVpv (new_stash, 0)));
    PUSHs (old_stash ? sv_2mortal (newSVpv (old_stash, 0)) : &PL_sv_undef);
    PUTBACK;

    call_sv ((SV *)user_data, G_VOID|G_DISCARD);

    PUTBACK;
    FREETMPS;
    LEAVE;

	return op;
}

MODULE = B::Hooks::OP::Check::StashChange  PACKAGE = B::Hooks::OP::Check::StashChange

PROTOTYPES: DISABLE

UV
register (cb)
		SV *cb
	CODE:
		RETVAL = hook_op_check_stashchange (perl_cb, newSVsv (cb));
	OUTPUT:
		RETVAL

void
unregister (id)
		UV id
	PREINIT:
		SV *sv;
	CODE:
		sv = hook_op_check_stashchange_remove (id);

		if (sv) {
			SvREFCNT_dec (sv);
		}
