#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_newSV_type
#include "ppport.h"

#ifndef CxLABEL
#define CxLABEL(cx) ((cx)->blk_loop.label)
#endif

#ifndef CxFOREACH
#define CxFOREACH(cx) (CxTYPE(cx) == CXt_LOOP && CxITERVAR(cx) != NULL)
#endif

#ifndef CX_LOOP_NEXTOP_GET
#if PERL_BCDVERSION >= 0x5013005
#define CX_LOOP_NEXTOP_GET(cx) ((cx)->blk_loop.my_op->op_nextop)
#else
#define CX_LOOP_NEXTOP_GET(cx) ((cx)->blk_loop.next_op)
#endif
#endif

#ifdef CXt_LOOP_FOR /* >= 5.11 */
#define CxLOOP_FOR(cx)    (CxTYPE(cx) == CXt_LOOP_FOR)
#define CxLOOP_LAZYSV(cx) (CxTYPE(cx) == CXt_LOOP_LAZYSV)

#define CxITERARY(cx)     ((cx)->blk_loop.state_u.ary.ary)
#define CxITERARY_IS_STACK(cx) (CxITERARY(cx) == NULL)
#define CxITERIX(cx)      ((cx)->blk_loop.state_u.ary.ix)
#define CxLAZYSV_CUR(cx)  ((cx)->blk_loop.state_u.lazysv.cur)
#define CxLAZYSV_END(cx)  ((cx)->blk_loop.state_u.lazysv.end)
#define CxLAZYIV_CUR(cx)  ((cx)->blk_loop.state_u.lazyiv.cur)
#define CxLAZYIV_END(cx)  ((cx)->blk_loop.state_u.lazyiv.end)
#else
#define CxLOOP_FOR(cx)    (SvTYPE(CxITERARY(cx)) == SVt_PVAV)
#define CxLOOP_LAZYSV(cx) ((cx)->blk_loop.iterlval != NULL)

#define CxITERARY(cx)     ((cx)->blk_loop.iterary)
#define CxITERARY_IS_STACK(cx) (CxITERARY(cx) == PL_curstack)
#define CxITERIX(cx)      ((cx)->blk_loop.iterix)
#define CxLAZYSV_CUR(cx)  ((cx)->blk_loop.iterlval)
#define CxLAZYSV_END(cx)  ((SV*)(cx)->blk_loop.iterary)
#define CxLAZYIV_CUR(cx)  ((cx)->blk_loop.iterix)
#define CxLAZYIV_END(cx)  ((cx)->blk_loop.itermax)
#endif

#define LoopIsReversed(cx) (CX_LOOP_NEXTOP_GET(cx)->op_next->op_private & OPpITER_REVERSED ? TRUE : FALSE)


static PERL_CONTEXT*
my_find_cx(pTHX_ const OP* const loop_op){
	dVAR;
	PERL_CONTEXT* const cxstk = cxstack;
	I32 i;
	for (i = cxstack_ix; i >= 0; i--) {
		PERL_CONTEXT* const cx = &cxstk[i];
		if(CxFOREACH(cx) && CX_LOOP_NEXTOP_GET(cx) == loop_op){
			return cx;
		}
	}

	Perl_croak(aTHX_ "Out of scope for the foreach iterator");
	return NULL;
}

static PERL_CONTEXT*
my_find_foreach(pTHX_ SV* const label){
	dVAR;
	PERL_CONTEXT* const cxstk  = cxstack;
	const char* const label_pv = SvOK(label) ? SvPV_nolen_const(label) : NULL;
	I32 i;

	for (i = cxstack_ix; i >= 0; i--) {
		PERL_CONTEXT* const cx = &cxstk[i];
		if(CxFOREACH(cx)){
			if(label_pv){
				if(CxLABEL(cx) && strEQ(CxLABEL(cx), label_pv)){
					return cx;
				}
			}
			else{
				return cx;
			}
		}
	}

	if(label_pv){
		Perl_croak(aTHX_ "No foreach loops found for \"%s\"", label_pv);
	}
	else{
		Perl_croak(aTHX_ "No foreach loops found");
	}
	return NULL; /* not reached */
}

typedef SV* SVREF;

MODULE = B::Foreach::Iterator	PACKAGE = B::Foreach::Iterator

PROTOTYPES: DISABLE

SV*
iter(label = NULL)
PREINIT:
	const PERL_CONTEXT* const cx = my_find_foreach(aTHX_ items == 1 ? ST(0) : &PL_sv_undef);
	SV* const iterator           = newSV_type(SVt_PVMG);
CODE:
	sv_setiv(iterator, PTR2IV(CX_LOOP_NEXTOP_GET(cx)));
	RETVAL = sv_bless(newRV_noinc(iterator), GvSTASH(CvGV(cv)));
OUTPUT:
	RETVAL

#define need_increment (ix == 0)

#define ITERMAX(cx) (av_is_stack ? cx->blk_oldsp : AvFILL(av))

#ifdef CXt_LOOP_FOR
#define ITERMIN(cx) (av_is_stack ? cx->blk_loop.resetsp + 1 : 0)
#else
#define ITERMIN(cx) (cx->blk_loop.itermax)
#endif

SV*
next(SVREF iterator)
ALIAS:
	next    = 0
	peek    = 1
	is_last = 2
PREINIT:
	PERL_CONTEXT* cx;
CODE:
	cx      = my_find_cx(aTHX_ INT2PTR(OP*, SvIV(iterator)));
	RETVAL  = NULL;

	/* see also pp_iter() in pp_hot.c */
	if(CxLOOP_FOR(cx)) { /* foreach(list) */
		bool const av_is_stack = CxITERARY_IS_STACK(cx);
		AV*  const av          = av_is_stack ? PL_curstack : CxITERARY(cx);
		bool const reversed    = LoopIsReversed(cx);
		bool const in_range    = reversed ? (--CxITERIX(cx) >= ITERMIN(cx))
		                                  : (++CxITERIX(cx) <= ITERMAX(cx));

		if (in_range){
			if (SvMAGICAL(av) || AvREIFY(av)){
				SV** const svp = av_fetch(av, CxITERIX(cx), FALSE);
				if(svp) RETVAL = *svp;
			}
			else{
				RETVAL = AvARRAY(av)[CxITERIX(cx)];
			}
		}

		if (!need_increment){
			reversed ? ++CxITERIX(cx) : --CxITERIX(cx);
		}
	}
	else { /* foreach (min .. max) */
		if(CxLOOP_LAZYSV(cx)) {
			SV* const cur = CxLAZYSV_CUR(cx);

			if (strNE(SvPV_nolen_const(cur), "0")){
				if(need_increment){
					dXSTARG;

					RETVAL = TARG;
					sv_setsv(RETVAL, cur);

					if(sv_eq(cur, CxLAZYSV_END(cx))){
						sv_setiv(cur, 0);
					}
					else{
						sv_inc(cur);
					}
				}
				else{
					RETVAL = cur;
				}
			}
		}
		else { /* LOOP_LAZYIV */
			if (CxLAZYIV_CUR(cx) <= CxLAZYIV_END(cx)){
				dXSTARG;
				RETVAL = TARG;
				sv_setiv(RETVAL, CxLAZYIV_CUR(cx));
			}

			if (need_increment) CxLAZYIV_CUR(cx)++;
		}
	}

	if(ix != 2){ /* next(), peek() */
		if(!RETVAL){
			RETVAL = &PL_sv_undef;
		}
	}
	else{ /* is_last() */
		RETVAL = boolSV(RETVAL == NULL);
	}

	ST(0) = RETVAL;
	XSRETURN(1);


const char*
label(SVREF iterator)
PREINIT:
	const PERL_CONTEXT* cx;
CODE:
	cx     = my_find_cx(aTHX_ INT2PTR(OP*, SvIV(iterator)));
	RETVAL = CxLABEL(cx); /* can be NULL */
OUTPUT:
	RETVAL
