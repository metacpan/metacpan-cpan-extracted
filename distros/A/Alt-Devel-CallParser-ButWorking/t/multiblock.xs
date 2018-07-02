#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "multiblock_callparser0.h"
#include "XSUB.h"

static OP *THX_parse_args_multiblock(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	OP *argsop = NULL;
	I32 c;
	bool is_expr;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	lex_read_space(0);
	c = lex_peek_unichar(0);
	is_expr = c == '('/*)*/;
	if(is_expr) {
		lex_read_unichar(0);
		lex_read_space(0);
		c = lex_peek_unichar(0);
	}
	while(c == '{'/*}*/) {
		I32 floor = start_subparse(0, CVf_ANON);
		OP *blkop;
		SAVEFREESV(PL_compcv);
		blkop = parse_block(0);
		SvREFCNT_inc_simple_void((SV*)PL_compcv);
		blkop = newANONATTRSUB(floor, NULL, NULL, blkop);
		argsop = op_append_elem(OP_LIST, argsop, blkop);
		lex_read_space(0);
		c = lex_peek_unichar(0);
	}
	if(is_expr) {
		if(c != /*(*/')') croak("syntax error");
		lex_read_unichar(0);
		*flags_p |= CALLPARSER_PARENS;
	} else {
		*flags_p |= CALLPARSER_STATEMENT;
	}
	return argsop;
}

MODULE = t::multiblock PACKAGE = t::multiblock

PROTOTYPES: DISABLE

void
cv_set_call_parser_multiblock(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_parser(cv, THX_parse_args_multiblock, &PL_sv_undef);
