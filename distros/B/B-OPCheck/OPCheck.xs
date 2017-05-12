/*#define PERL_CORE */

#include "EXTERN.h"
#include "perl.h"
#include "embed.h"
#include "BUtils.h"

#include "XSUB.h"
#define NEED_load_module
#define NEED_newRV_noinc
#define NEED_vload_module
#define NEED_sv_2pv_flags
#include "ppport.h"

STATIC AV **OPCHECK_subs;
Perl_check_t *PL_check_orig;

/* ============================================
   This is from Runops::Hook.  We need to find a way to share c functions
*/

STATIC int Runops_Trace_loaded_B;
STATIC CV *Runops_Trace_B_UNOP_first;
STATIC XSUBADDR_t Runops_Trace_B_UNOP_first_xsub;
STATIC UNOP Runops_Trace_fakeop;
STATIC SV *Runops_Trace_fakeop_sv;

STATIC void
Runops_Trace_load_B (pTHX) {
    if (!Runops_Trace_loaded_B) {
        load_module( PERL_LOADMOD_NOIMPORT, newSVpv("B", 0), (SV *)NULL );

        Runops_Trace_B_UNOP_first = get_cv("B::UNOP::first", TRUE);
        Runops_Trace_B_UNOP_first_xsub = CvXSUB(Runops_Trace_B_UNOP_first);

        Runops_Trace_fakeop_sv = sv_bless(newRV_noinc(newSVuv((UV)&Runops_Trace_fakeop)), gv_stashpv("B::UNOP", 0));

        Runops_Trace_loaded_B = 1;
    }
}

STATIC SV *
Runops_Trace_op_to_BOP (pTHX_ OP *op) {
    dSP;

    /* we fake B::UNOP object (fakeop_sv) that points to our static fakeop.
     * then we set first_op to the op we want to make an object out of, and
     * trampoline into B::UNOP->first so that it creates the B::OP of the
     * correct class for us.
     * B should really have a way to create an op from a pointer via some
     * external API. This sucks monkey balls on olympic levels */

    Runops_Trace_fakeop.op_first = op;

    PUSHMARK(SP);
    XPUSHs(Runops_Trace_fakeop_sv);
    PUTBACK;

    /* call_pv("B::UNOP::first", G_SCALAR); */
    assert(Runops_Trace_loaded_B);
    assert(Runops_Trace_B_UNOP_first);
    assert(Runops_Trace_B_UNOP_first_xsub != NULL);
    (void)Runops_Trace_B_UNOP_first_xsub(aTHX_ Runops_Trace_B_UNOP_first);

    SPAGAIN;

    return POPs;
}

/* ============================================
   End of Runops::Hook.  We need to find a way to share c functions
*/

void
OPCHECK_call_ck(pTHX_ SV *sub, OP *o) {
    SV *PL_op_object;
    dSP;

    ENTER;
    SAVETMPS;


    PL_op_object = Runops_Trace_op_to_BOP(aTHX_ o);

    PUSHMARK(SP);
    XPUSHs(PL_op_object);

    PUTBACK;

    call_sv(sub, G_DISCARD);

    SPAGAIN;

    PUTBACK;
    FREETMPS;
    LEAVE;

}

OP *OPCHECK_ck_subr(pTHX_ OP *o) {
    I32 opnum = o->op_type;

    o = PL_check_orig[opnum](aTHX_ o);

    /*
     * work around a %^H scoping bug by checking that PL_hints (which is properly scoped) & an unused
     * PL_hints bit (0x100000) is true
     */
    if ((PL_hints & 0x120000) == 0x120000) {
        AV *subs;

        if ( opnum == OP_ENTERSUB ) {
            OP *prev = ((OpSIBLING(cUNOPo->op_first)) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first;
            OP *o2 = OpSIBLING(prev);
            OP *cvop;

            for (cvop = o2; OpHAS_SIBLING(cvop); cvop = OpSIBLING(cvop));

            if (cvop->op_type == OP_METHOD_NAMED) {
                const char * meth = SvPVX_const(((SVOP *)cvop)->op_sv);
                if ( meth && ( strEQ(meth, "import") || strEQ(meth, "unimport") || strEQ(meth, "VERSION")))
                    return o;
            }
        }

        subs = OPCHECK_subs[opnum];
        if (subs) {
            int i;
            for (i = 0; i <= av_len(subs); ++i) {
                SV **sub = av_fetch(subs, i, 0);
                if (sub && SvOK(*sub)) {
                    /* FIXME replace? before? after? */
                    OPCHECK_call_ck(aTHX_ *sub, o);
                }
            }
        }
    }

    return o;
}

MODULE = B::OPCheck                PACKAGE = B::OPCheck

PROTOTYPES: ENABLE

BOOT:
Newxz(PL_check_orig, OP_CUSTOM+1, Perl_check_t);
Newxz(OPCHECK_subs, OP_CUSTOM+1, AV *);
Runops_Trace_load_B(aTHX);

void
enterscope(opname, mode, perlsub)
    SV *opname
    SV *perlsub
PROTOTYPE: $$
PREINIT:
    I32 opnum = BUtils_op_name_to_num(opname);
CODE:
    if ( !PL_check_orig[opnum] ) {
        PL_check_orig[opnum] = PL_check[opnum];
        PL_check[opnum] = OPCHECK_ck_subr;
    }

    if (!OPCHECK_subs[opnum]) {
        OPCHECK_subs[opnum] = (AV *)SvREFCNT_inc(newAV());
        SvREADONLY_off(OPCHECK_subs[opnum]);
    }

    av_push(OPCHECK_subs[opnum], SvREFCNT_inc(perlsub));

void
leavescope(opname, mode, perlsub)
    SV *opname
    SV *perlsub
PROTOTYPE: $$
PREINIT:
    AV *av;
    I32 opnum = BUtils_op_name_to_num(opname);
CODE:
    if ((av = OPCHECK_subs[opnum])) {
        I32 i;
        for ( i = av_len(av); i >= 0; i-- ) {
            SV **elem = av_fetch(av, i, 0);;
            if ( elem && *elem == perlsub ) {
                av_delete(av, i, G_DISCARD);
            }
        }

        if ( av_len(av) == -1 ) {
            SvREFCNT_dec(av);
            OPCHECK_subs[opnum] = NULL;
            PL_check[opnum] = PL_check_orig[opnum];
            PL_check_orig[opnum] = NULL;
        }
    }

void
END()
    PROTOTYPE:
    CODE: 

AV *
get_guts(opname)
    SV *opname
    I32 opnum = BUtils_op_name_to_num(opname);
	CODE:
{
    RETVAL = OPCHECK_subs[opnum];
}
	OUTPUT:
		RETVAL
    
