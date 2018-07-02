#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "getset0_callparser0.h"
#include "XSUB.h"

static OP *THX_parse_args_a(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	PERL_UNUSED_ARG(flags_p);
	return newOP(OP_NULL, 0);
}

static OP *THX_parse_args_b(pTHX_ GV *namegv, SV *psobj, U32 *flags_p)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(flags_p);
	return newSVOP(OP_CONST, 0, SvREFCNT_inc(psobj));
}

MODULE = t::getset0 PACKAGE = t::getset0

PROTOTYPES: DISABLE

void
test_cv_getset_call_parser()
PROTOTYPE:
PREINIT:
	CV *t0_cv, *t1_cv;
	Perl_call_parser psfun;
	SV *psobj;
CODE:
#define croak_fail() croak("fail at " __FILE__ " line %d", __LINE__)
#define croak_fail_ne(h, w) \
	croak("fail %p!=%p at " __FILE__ " line %d", (h), (w), __LINE__)
#define check_cp(cv, xpsfun, xpsobj) \
	do { \
		cv_get_call_parser((cv), &psfun, &psobj); \
		if (psfun != (xpsfun)) \
			croak_fail_ne(FPTR2DPTR(void *, psfun), xpsfun); \
		if (psobj != (xpsobj)) \
			croak_fail_ne(FPTR2DPTR(void *, psobj), xpsobj); \
	} while(0)
	t0_cv = get_cv("t::getset0::t0", 0);
	t1_cv = get_cv("t::getset0::t1", 0);
	check_cp(t0_cv, (Perl_call_parser)NULL, (SV*)NULL);
	check_cp(t1_cv, (Perl_call_parser)NULL, (SV*)NULL);
	cv_set_call_parser(t1_cv, THX_parse_args_a, &PL_sv_yes);
	check_cp(t0_cv, (Perl_call_parser)NULL, (SV*)NULL);
	check_cp(t1_cv, THX_parse_args_a, &PL_sv_yes);
	cv_set_call_parser(t0_cv, THX_parse_args_b, &PL_sv_no);
	check_cp(t0_cv, THX_parse_args_b, &PL_sv_no);
	check_cp(t1_cv, THX_parse_args_a, &PL_sv_yes);
	cv_set_call_parser(t1_cv, (Perl_call_parser)NULL, (SV*)NULL);
	check_cp(t0_cv, THX_parse_args_b, &PL_sv_no);
	check_cp(t1_cv, (Perl_call_parser)NULL, (SV*)NULL);
	cv_set_call_parser(t0_cv, (Perl_call_parser)NULL, (SV*)NULL);
	check_cp(t0_cv, (Perl_call_parser)NULL, (SV*)NULL);
	check_cp(t1_cv, (Perl_call_parser)NULL, (SV*)NULL);
	if (SvMAGICAL((SV*)t0_cv) || SvMAGIC((SV*)t0_cv)) croak_fail();
	if (SvMAGICAL((SV*)t1_cv) || SvMAGIC((SV*)t1_cv)) croak_fail();
#undef check_cp
#undef croak_fail_ne
#undef croak_fail

void
t0()
PROTOTYPE:
CODE:
	;

void
t1()
PROTOTYPE:
CODE:
	;
