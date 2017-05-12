#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_op_check.h"

typedef OP *(*orig_check_t) (pTHX_ OP *op);

STATIC orig_check_t orig_PL_check[OP_max];
STATIC AV *check_cbs[OP_max];

#define run_orig_check(type, op) (CALL_FPTR (orig_PL_check[(type)])(aTHX_ op))

STATIC void *
get_mg_ptr (SV *sv) {
	MAGIC *mg;

	if ((mg = mg_find (sv, PERL_MAGIC_ext))) {
		return mg->mg_ptr;
	}

	return NULL;
}

STATIC OP *
check_cb (pTHX_ OP *op) {
	I32 i;
	AV *hooks = check_cbs[op->op_type];
	OP *ret = run_orig_check (op->op_type, op);

	if (!hooks) {
		return ret;
	}

	for (i = 0; i <= av_len (hooks); i++) {
		hook_op_check_cb cb;
		void *user_data;
		SV **hook = av_fetch (hooks, i, 0);

		if (!hook || !*hook) {
			continue;
		}

		user_data = get_mg_ptr (*hook);

		cb = INT2PTR (hook_op_check_cb, SvUV (*hook));
		ret = CALL_FPTR (cb)(aTHX_ ret, user_data);
	}

	return ret;
}

hook_op_check_id
hook_op_check (opcode type, hook_op_check_cb cb, void *user_data) {
	AV *hooks;
	SV *hook;

	hooks = check_cbs[type];

	if (!hooks) {
		hooks = newAV ();
		check_cbs[type] = hooks;
		orig_PL_check[type] = PL_check[type];
		PL_check[type] = check_cb;
	}

	hook = newSVuv (PTR2UV (cb));
	sv_magic (hook, NULL, PERL_MAGIC_ext, (const char *)user_data, 0);
	av_push (hooks, hook);

	return (hook_op_check_id)PTR2UV (hook);
}

void *
hook_op_check_remove (opcode type, hook_op_check_id id) {
	AV *hooks;
	I32 i;
	void *ret = NULL;

	hooks = check_cbs[type];

	if (!hooks) {
		return NULL;
	}

	for (i = 0; i <= av_len (hooks); i++) {
		SV **hook = av_fetch (hooks, i, 0);

		if (!hook || !*hook) {
			continue;
		}

		if ((hook_op_check_id)PTR2UV (*hook) == id) {
			ret = get_mg_ptr (*hook);
			av_delete (hooks, i, G_DISCARD);
		}
	}

	return ret;
}

MODULE = B::Hooks::OP::Check  PACKAGE = B::Hooks::OP::Check

PROTOTYPES: DISABLE
