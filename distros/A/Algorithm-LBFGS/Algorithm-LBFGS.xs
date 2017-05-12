/**************************************************************************
 * XS of Algorithm::LBFGS
 * -> by Laye Suen
 **************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "lbfgs.h"

/* Macros for debugging */

/* uncomment the line below to enable tracing and timing */
/* #define __ENABLE_TRACING__ */

#ifdef __ENABLE_TRACING__

#include "time.h"

#define TRACE(msg) \
    printf(msg); \
    printf(": %0.10f s\n", 1.0 * (clock() - _c) / CLOCKS_PER_SEC); \
    fflush(stdout); \
    _c = clock()
#define dTRACE clock_t _c = clock()

#else

#define TRACE(msg)
#define dTRACE

#endif

/* Other macros */

#define newSVpv_(x) newSVpv(x, strlen(x))

/**************************************************************************
 * NON-EXPORTED SUBS
 **************************************************************************/

/* Evaluation callback for L-BFGS */
lbfgsfloatval_t lbfgs_evaluation_cb(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    lbfgsfloatval_t*         g,
    const int                n,
    const lbfgsfloatval_t    step)
{
    int i;
    SV *lbfgs_eval, *user_data, *sv_f;
    AV *av_x, *av_g;
    lbfgsfloatval_t f;
    dSP;
    dTRACE;
    /* fetch refs to user evaluation callback and extra data */
    TRACE("lbfgs_evaluation_cb: enter");
    lbfgs_eval = ((SV**)instance)[0];
    user_data = ((SV**)instance)[2];
    /* create an AV av_x from the C array x */
    av_x = newAV();
    av_extend(av_x, n - 1);
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    /* call the user evaluation callback */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_x)));
    XPUSHs(sv_2mortal(newSVnv(step)));
    XPUSHs(user_data);
    PUTBACK;
    TRACE("lbfgs_evaluation_cb: finish arguments preparation");
    call_sv(lbfgs_eval, G_ARRAY);
    TRACE("lbfgs_evaluation_cb: finish calling");
    SPAGAIN;
    av_g = (AV*)SvRV(POPs);
    sv_f = POPs;
    f = SvNV(sv_f);
    for (i = 0; i < n; i++)
        g[i] = SvNV(*av_fetch(av_g, i, 0));
    PUTBACK;
    FREETMPS;
    LEAVE;
    /* clean up (for non-mortal return values) */
    if (SvREFCNT(av_g) > 0) av_undef(av_g);
    if (SvREFCNT(sv_f) > 0) SvREFCNT_dec(sv_f);
    TRACE("lbfgs_evaluation_cb: leave");
    return f;
}

/* Progress callback for L-BFGS */
int lbfgs_progress_cb(
    void*                    instance,
    const lbfgsfloatval_t*   x,
    const lbfgsfloatval_t*   g,
    const lbfgsfloatval_t    fx,
    const lbfgsfloatval_t    xnorm,
    const lbfgsfloatval_t    gnorm,
    const lbfgsfloatval_t    step,
    int                      n,
    int                      k,
    int                      ls)
{
    int i, r;
    SV *lbfgs_prgr, *user_data, *sv_r;
    AV *av_x, *av_g;
    dSP;
    dTRACE;
    /* fetch refs to the user progress callback and extra data */
    TRACE("lbfgs_progress_cb: enter");
    lbfgs_prgr = ((SV**)instance)[1];
    user_data = ((SV**)instance)[2];
    /* create AVs for C array x and g */
    av_x = newAV();
    for (i = 0; i < n; i++) av_store(av_x, i, newSVnv(x[i]));
    av_g = newAV();
    for (i = 0; i < n; i++) av_store(av_g, i, newSVnv(g[i]));
    /* call the user progress callback */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_x)));
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av_g)));
    XPUSHs(sv_2mortal(newSVnv(fx)));
    XPUSHs(sv_2mortal(newSVnv(xnorm)));
    XPUSHs(sv_2mortal(newSVnv(gnorm)));
    XPUSHs(sv_2mortal(newSVnv(step)));
    XPUSHs(sv_2mortal(newSViv(k)));
    XPUSHs(sv_2mortal(newSViv(ls)));
    XPUSHs(user_data);
    PUTBACK;
    TRACE("lbfgs_progress_cb: finish arguments preparation");
    call_sv(lbfgs_prgr, G_ARRAY);
    TRACE("lbfgs_progress_cb: finish calling");
    SPAGAIN;
    sv_r = POPs;
    r = SvIV(sv_r);
    PUTBACK;
    FREETMPS;
    LEAVE;
    /* clean up (for non-mortal return values) */
    if (SvREFCNT(sv_r) > 0) SvREFCNT_dec(sv_r);
    TRACE("lbfgs_progress_cb: leave");
    return r;
}

/**************************************************************************
 * EXPORTED XSUBS
 **************************************************************************/
MODULE = Algorithm::LBFGS		PACKAGE = Algorithm::LBFGS

void*
create_lbfgs_instance(lbfgs_eval, lbfgs_prgr, user_data)
        SV*     lbfgs_eval
	SV*     lbfgs_prgr
	SV*	user_data
    PREINIT:
        void* instance = malloc(3 * sizeof(SV*));
    CODE:
        ((SV**)instance)[0] = lbfgs_eval; /* ref to Perl eval callback */
	((SV**)instance)[1] = lbfgs_prgr; /* ref to Perl monitor callback */
	((SV**)instance)[2] = user_data;  /* ref to Perl user data */
	RETVAL = instance;
    OUTPUT:
        RETVAL

void
destroy_lbfgs_instance(li)
        void*   li
    CODE:
        free(li);


void*
create_lbfgs_param()
    PREINIT:
        void* lp = malloc(sizeof(lbfgs_parameter_t));
    CODE:
        lbfgs_parameter_init((lbfgs_parameter_t*)lp);
	RETVAL = lp;
    OUTPUT:
        RETVAL

void
destroy_lbfgs_param(lp)
        void*   lp
    CODE:
        free(lp);

SV*
set_lbfgs_param(lp, name, val)
        void*   lp
	char*   name
	SV*     val
    PREINIT:
        lbfgs_parameter_t* p = (lbfgs_parameter_t*)lp;
	SV* r = &PL_sv_undef;
    CODE:
        if (strcmp(name, "m") == 0) {
	    if (SvIOK(val)) p->m = SvIV(val);
	    r = newSViv(p->m);
	}
	else if (strcmp(name, "epsilon") == 0) {
	    if (SvNOK(val)) p->epsilon = SvNV(val);
	    r = newSVnv(p->epsilon);
	}
	else if (strcmp(name, "max_iterations") == 0) {
	    if (SvIOK(val)) p->max_iterations = SvIV(val);
	    r = newSViv(p->max_iterations);
	}
	else if (strcmp(name, "max_linesearch") == 0) {
	    if (SvIOK(val)) p->max_linesearch = SvIV(val);
	    r = newSViv(p->max_linesearch);
	}
	else if (strcmp(name, "min_step") == 0) {
	    if (SvNOK(val)) p->min_step = SvNV(val);
	    r = newSVnv(p->min_step);
	}
	else if (strcmp(name, "max_step") == 0) {
	    if (SvNOK(val)) p->max_step = SvNV(val);
	    r = newSVnv(p->max_step);
	}
	else if (strcmp(name, "ftol") == 0) {
	    if (SvNOK(val)) p->ftol = SvNV(val);
	    r = newSVnv(p->ftol);
	}
	else if (strcmp(name, "gtol") == 0) {
	    if (SvNOK(val)) p->gtol = SvNV(val);
	    r = newSVnv(p->gtol);
	}
	else if (strcmp(name, "xtol") == 0) {
	    if (SvNOK(val)) p->xtol = SvNV(val);
	    r = newSVnv(p->xtol);
	}
	else if (strcmp(name, "orthantwise_c") == 0) {
	    if (SvNOK(val)) p->orthantwise_c = SvNV(val);
	    r = newSVnv(p->orthantwise_c);
	}
	RETVAL = r;
    OUTPUT:
        RETVAL

SV*
do_lbfgs(param, instance, x0)
        void*   param
	void*   instance
	SV*     x0
    PREINIT:
        AV* av_x0 = (AV*)SvRV(x0);
	int n = av_len(av_x0) + 1;
	int i, s;
    CODE:
	/* build C array carr_x0 from Perl array ref x0 */
	lbfgsfloatval_t* carr_x0 = (lbfgsfloatval_t*)
	    malloc(n * sizeof(lbfgsfloatval_t));
	for (i = 0; i < n; i++) carr_x0[i] = SvNV(*av_fetch(av_x0, i, 0));
	/* call L-BFGS */
	s = lbfgs(n, carr_x0, NULL, 
                  SvOK(((SV**)instance)[0]) ? &lbfgs_evaluation_cb : NULL,
                  SvOK(((SV**)instance)[1]) ? &lbfgs_progress_cb : NULL,
                  instance, (lbfgs_parameter_t*)param);
        /* store the result back to the Perl array ref x0 */
	for (i = 0; i < n; i++) av_store(av_x0, i, newSVnv(carr_x0[i]));
	/* release the C array */
	free(carr_x0);
	RETVAL = newSViv(s);
    OUTPUT:
        RETVAL

SV*
status_2pv(status)
        int     status
    CODE:
        switch (status) {
	case 0:
	    RETVAL = newSVpv_("LBFGS_OK"); break;
	case LBFGSERR_UNKNOWNERROR:
	    RETVAL = newSVpv_("LBFGSERR_UNKNOWNERROR"); break;
	case LBFGSERR_LOGICERROR:
	    RETVAL = newSVpv_("LBFGSERR_LOGICERROR"); break;
	case LBFGSERR_OUTOFMEMORY:
	    RETVAL = newSVpv_("LBFGSERR_OUTOFMEMORY"); break;
	case LBFGSERR_CANCELED:
	    RETVAL = newSVpv_("LBFGSERR_CANCELED"); break;
	case LBFGSERR_INVALID_N:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_N"); break;
	case LBFGSERR_INVALID_N_SSE:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_N_SSE"); break;
	case LBFGSERR_INVALID_MINSTEP:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_MINSTEP"); break;
	case LBFGSERR_INVALID_MAXSTEP:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_MAXSTEP"); break;
	case LBFGSERR_INVALID_FTOL:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_FTOL"); break;
	case LBFGSERR_INVALID_GTOL:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_GTOL"); break;
	case LBFGSERR_INVALID_XTOL:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_XTOL"); break;
	case LBFGSERR_INVALID_MAXLINESEARCH:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_MAXLINESEARCH"); break;
	case LBFGSERR_INVALID_ORTHANTWISE:
	    RETVAL = newSVpv_("LBFGSERR_INVALID_ORTHANTWISE"); break;
	case LBFGSERR_OUTOFINTERVAL:
	    RETVAL = newSVpv_("LBFGSERR_OUTOFINTERVAL"); break;
	case LBFGSERR_INCORRECT_TMINMAX:
	    RETVAL = newSVpv_("LBFGSERR_INCORRECT_TMINMAX"); break;
	case LBFGSERR_ROUNDING_ERROR:
	    RETVAL = newSVpv_("LBFGSERR_ROUNDING_ERROR"); break;
	case LBFGSERR_MINIMUMSTEP:
	    RETVAL = newSVpv_("LBFGSERR_MINIMUMSTEP"); break;
	case LBFGSERR_MAXIMUMSTEP:
	    RETVAL = newSVpv_("LBFGSERR_MAXIMUMSTEP"); break;
	case LBFGSERR_MAXIMUMLINESEARCH:
	    RETVAL = newSVpv_("LBFGSERR_MAXIMUMLINESEARCH"); break;
	case LBFGSERR_MAXIMUMITERATION:
	    RETVAL = newSVpv_("LBFGSERR_MAXIMUMITERATION"); break;
	case LBFGSERR_WIDTHTOOSMALL:
	    RETVAL = newSVpv_("LBFGSERR_WIDTHTOOSMALL"); break;
	case LBFGSERR_INVALIDPARAMETERS:
	    RETVAL = newSVpv_("LBFGSERR_INVALIDPARAMETERS"); break;
	case LBFGSERR_INCREASEGRADIENT:
	    RETVAL = newSVpv_("LBFGSERR_INCREASEGRADIENT"); break;
	default:
	    RETVAL = newSVpv_(""); break;
	}
    OUTPUT:
        RETVAL

