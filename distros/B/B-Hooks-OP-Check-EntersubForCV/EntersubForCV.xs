#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "BUtils.h"

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#include "hook_op_check_entersubforcv.h"

typedef struct userdata_St {
	CV *cv;
	hook_op_check_entersubforcv_cb cb;
	void *ud;
} userdata_t;

STATIC OP *
entersub_cb (pTHX_ OP *op, void *user_data) {
	OP *kid, *last;
	GV *gv;
	CV *cv;
	userdata_t *ud = (userdata_t *)user_data;

	if (op->op_type != OP_ENTERSUB) {
		return op;
	}

	/* we currently ignore anything caused by &foo because \&foo also creates
	 * an entersub op before ck_doref removes it again */
	if (op->op_private & OPpENTERSUB_AMPER) {
		return op;
	}

	if (op->op_type == OP_NULL) {
		return op;
	}

	kid = cUNOPx (op)->op_first;

	if (!kid) {
		return op;
	}

	/* pushmark for method call */
	if (kid->op_type != OP_NULL) {
		return op;
	}

	last = cLISTOPx (kid)->op_last;

	/* not what we expected */
	if (last->op_type != OP_NULL) {
		return op;
	}

	kid = cUNOPx (last)->op_first;

	/* not a GV */
	if (kid->op_type != OP_GV) {
		return op;
	}

	gv = cGVOPx_gv (kid);
	cv = SvTYPE (gv) == SVt_PVGV ? GvCV (gv) :
		SvROK ((SV*)gv) ? (CV*) SvRV ((SV*)gv) : (CV*)NULL;

	if (ud->cv == cv) {
		op = ud->cb (aTHX_ op, cv, ud->ud);
	}

	return op;
}

hook_op_check_id
hook_op_check_entersubforcv (CV *cv, hook_op_check_entersubforcv_cb cb, void *user_data) {
	userdata_t *ud;

	Newx (ud, 1, userdata_t);
	ud->cv = cv;
	ud->cb = cb;
	ud->ud = user_data;

	return hook_op_check (OP_ENTERSUB, entersub_cb, ud);
}

void *
hook_op_check_entersubforcv_remove (hook_op_check_id id) {
	void *ret;
	userdata_t *ud = hook_op_check_remove (OP_ENTERSUB, id);

	if (!ud) {
		return NULL;
	}

	ret = ud->ud;

	Safefree (ud);

	return ret;
}

STATIC OP *
perl_cb (pTHX_ OP *op, CV *cv, void *ud) {
	SV *opsv;
	dSP;

	ENTER;
	SAVETMPS;

	opsv = sv_newmortal ();
	sv_setiv (newSVrv (opsv, BUtils_cc_opclassname (aTHX_ op)), PTR2IV (op));

	PUSHMARK (SP);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newRV ((SV *)cv)));
	PUSHs (opsv);
	PUTBACK;

	call_sv ((SV *)ud, G_VOID|G_DISCARD);

	SPAGAIN;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return op;
}

MODULE = B::Hooks::OP::Check::EntersubForCV  PACKAGE = B::Hooks::OP::Check::EntersubForCV

PROTOTYPES: DISABLE

UV
register (cv, cb)
		CV *cv
		SV *cb
	CODE:
		RETVAL = (UV)hook_op_check_entersubforcv (cv, perl_cb, newSVsv (cb));
	OUTPUT:
		RETVAL

void
unregister (id)
		UV id
	PREINIT:
		SV *ud;
	CODE:
		ud = hook_op_check_entersubforcv_remove ((hook_op_check_id)id);

		if (ud) {
			SvREFCNT_dec (ud);
		}
