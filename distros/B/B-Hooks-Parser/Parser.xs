#define __PARSER_XS__

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_parser
#include "ppport.h"

#include "hook_parser.h"
#include "stolen_chunk_of_toke.c"

#define NOT_PARSING (!PL_parser || !PL_bufptr)

#if PERL_REVISION == 5 && PERL_VERSION >= 10
#define HAS_HINTS_HASH
#endif

char *
hook_parser_get_linestr (pTHX) {
	if (NOT_PARSING) {
		return NULL;
	}

	return SvPVX (PL_linestr);
}

IV
hook_parser_get_linestr_offset (pTHX) {
	char *linestr;

	if (NOT_PARSING) {
		return -1;
	}

	linestr = SvPVX (PL_linestr);
	return PL_bufptr - linestr;
}

void
hook_parser_set_linestr (pTHX_ const char *new_value) {
	STRLEN new_len;

	if (NOT_PARSING) {
        croak ("trying to alter PL_linestr at runtime");
	}

	new_len = strlen (new_value);

	if (SvLEN (PL_linestr) < new_len+1) {
		croak ("forced to realloc PL_linestr for line %s,"
		       " bailing out before we crash harder", SvPVX (PL_linestr));
	}

	Copy (new_value, SvPVX (PL_linestr), new_len + 1, char);

	SvCUR_set (PL_linestr, new_len);
	PL_bufend = SvPVX(PL_linestr) + new_len;
}

STATIC I32
grow_linestr (pTHX_ int idx, SV *sv, int maxlen) {
	const I32 count = FILTER_READ (idx + 1, sv, maxlen);
	SvGROW (sv, 8192);
	return count;
}

STATIC OP *
grow_eval_sv (pTHX) {
	dSP;
	SV *sv, **stack;

#ifdef HAS_HINTS_HASH
	if (PL_op->op_private & OPpEVAL_HAS_HH) {
		stack = &SP[-1];
	}
	else {
		stack = &SP[0];
	}
#else
	stack = &SP[0];
#endif

	sv = *stack;

	if (SvPOK (sv)) {
		if (SvREADONLY (sv)) {
			sv = sv_2mortal (newSVsv (sv));
		}

		if (!SvLEN (sv) || SvPVX (sv)[SvLEN (sv) - 1] != ';') {
			if (!SvTEMP (sv)) {
				sv = sv_2mortal (newSVsv (sv));
			}

			sv_catpvs (sv, "\n;");
		}

		SvGROW (sv, 8192);
	}

	*stack = sv;
	return PL_ppaddr[OP_ENTEREVAL](aTHX);
}

STATIC OP *
check_eval (pTHX_ OP *op, void *user_data) {
	PERL_UNUSED_VAR(user_data);
	if (op->op_ppaddr == PL_ppaddr[OP_ENTEREVAL]) {
		op->op_ppaddr = grow_eval_sv;
	}

	return op;
}

hook_op_check_id
hook_parser_setup (pTHX) {
	filter_add (grow_linestr, NULL);
	return hook_op_check (OP_ENTEREVAL, check_eval, NULL);
}

void
hook_parser_teardown (hook_op_check_id id) {
	hook_op_check_remove (OP_ENTEREVAL, id);
}

char *
hook_parser_get_lex_stuff (pTHX) {
	if (NOT_PARSING || !PL_lex_stuff) {
		return NULL;
	}

	return SvPVX (PL_lex_stuff);
}

void
hook_parser_clear_lex_stuff (pTHX) {
	if (NOT_PARSING) {
		return;
	}

	PL_lex_stuff = (SV *)NULL;
}

char *
hook_toke_move_past_token (pTHX_ char *s) {
	STRLEN tokenbuf_len;

	while (s < PL_bufend && isSPACE (*s)) {
		s++;
	}

	tokenbuf_len = strlen (PL_tokenbuf);
	if (memEQ (s, PL_tokenbuf, tokenbuf_len)) {
		s += tokenbuf_len;
	}

	return s;
}

char *
hook_toke_scan_word (pTHX_ int offset, int handle_package, char *dest, STRLEN destlen, STRLEN *res_len) {
	char *base_s = SvPVX (PL_linestr) + offset;
	return scan_word (base_s, dest, destlen, handle_package, res_len);
}

char *
hook_toke_skipspace (pTHX_ char *s) {
	return skipspace (s);
}

char *
hook_toke_scan_str (pTHX_ char *s) {
	return scan_str (s, 0, 0);
}

MODULE = B::Hooks::Parser  PACKAGE = B::Hooks::Parser  PREFIX = hook_parser_

PROTOTYPES: DISABLE

UV
hook_parser_setup ()
CODE:
	RETVAL = hook_parser_setup (aTHX);
OUTPUT:
	RETVAL

void
hook_parser_teardown (id)
	UV id

SV *
hook_parser_get_linestr ()
CODE:
	if (NOT_PARSING) {
		RETVAL = &PL_sv_undef;
	} else {
		RETVAL = newSVsv (PL_linestr);
	}
OUTPUT:
	RETVAL

IV
hook_parser_get_linestr_offset ()
	C_ARGS:
		aTHX

void
hook_parser_set_linestr (SV *new_value)
PREINIT:
	char *new_chars;
	STRLEN new_len;
CODE:
	if (NOT_PARSING) {
		croak ("trying to alter PL_linestr at runtime");
	}
	new_chars = SvPV(new_value, new_len);
	if (SvLEN (PL_linestr) < new_len+1) {
		croak ("forced to realloc PL_linestr for line %s,"
		       " bailing out before we crash harder", SvPVX (PL_linestr));
	}
	Copy (new_chars, SvPVX (PL_linestr), new_len + 1, char);
	SvCUR_set (PL_linestr, new_len);
	PL_bufend = SvPVX(PL_linestr) + new_len;

SV *
hook_parser_get_lex_stuff ()
CODE:
	if (NOT_PARSING || !PL_lex_stuff) {
		RETVAL = &PL_sv_undef;
	}
	RETVAL = newSVsv (PL_lex_stuff);
OUTPUT:
	RETVAL

void
hook_parser_clear_lex_stuff ()
	C_ARGS:
		aTHX

MODULE = B::Hooks::Parser  PACKAGE = B::Hooks::Toke  PREFIX = hook_toke_

int
hook_toke_move_past_token (offset)
		int offset
	PREINIT:
		char *base_s, *s;
	CODE:
		base_s = SvPVX (PL_linestr) + offset;
		s = hook_toke_move_past_token (aTHX_ base_s);
		RETVAL = s - base_s;
	OUTPUT:
		RETVAL

void
hook_toke_scan_word (offset, handle_package)
		int offset
		int handle_package
	PREINIT:
		char tmpbuf[sizeof (PL_tokenbuf)];
		STRLEN retlen;
	PPCODE:
		(void)hook_toke_scan_word (aTHX_ offset, handle_package, tmpbuf, sizeof (PL_tokenbuf), &retlen);

		EXTEND (SP, 2);
		mPUSHp (tmpbuf, retlen);
		mPUSHi (retlen);

int
hook_toke_skipspace (offset)
		int offset
	PREINIT:
		char *base_s, *s;
	CODE:
		base_s = SvPVX (PL_linestr) + offset;
		s = hook_toke_skipspace (aTHX_ base_s);
		RETVAL = s - base_s;
	OUTPUT:
		RETVAL
