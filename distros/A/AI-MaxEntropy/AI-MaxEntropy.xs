/**************************************************************************
 * XS of AI:MaxEntropy
 * -> by Laye Suen
 **************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


/* Macros for debugging */

/* uncomment the line below to enable tracing and timing */
/*#define __ENABLE_TRACING__*/

#ifdef __ENABLE_TRACING__

#include "time.h"

#define TRACE(msg) \
    printf(_fn); printf(": "); printf(msg); \
    printf(": %0.10f s\n", 1.0 * (clock() - _t) / CLOCKS_PER_SEC); \
    fflush(stdout); _t = clock()
#define dTRACE(fn) clock_t _t = clock(); char* _fn = fn

#else

#define TRACE(msg)
#define dTRACE

#endif

/* Other macros */

#define hvref_fetch(hvref, key) \
    hv_fetch((HV*)SvRV(hvref), key, strlen(key), 0)
#define hvref_exists(hvref, key) \
    hv_exists((HV*)SvRV(hvref), key, strlen(key))
#define hvref_store(hvref, key, value) \
    hv_store((HV*)SvRV(hvref), key, strlen(key), value, 0)
#define hvref_delete(hvref, key) \
    hv_delete((HV*)SvRV(hvref), key, strlen(key), G_DISCARD)

/* internal structures */

struct samples_t {
    int s_num;
    int* x_len;
    int** x;
    int* y;
    double* w;
};

struct f_map_t {
    int y_num;
    int** lambda_idx;
};

/**************************************************************************
 * EXPORTED XSUBS
 **************************************************************************/
MODULE = AI::MaxEntropy		PACKAGE = AI::MaxEntropy

void
_neg_log_likelihood(lambda_in, step, self, OUTLIST SV* f, OUTLIST SV* g)
        AV*     lambda_in
	SV*     step
	SV*     self
    PREINIT:
	dTRACE("_neg_log_likelihood");
        /* fetch the pre-cached samples and f_map */
	SV* _c = *hvref_fetch(self, "_c");
	struct samples_t* samples =
	    INT2PTR(struct samples_t*, SvIV(*hvref_fetch(_c, "samples")));
	struct f_map_t* f_map =
	    INT2PTR(struct f_map_t*, SvIV(*hvref_fetch(_c, "f_map")));
	int** lambda_idx = f_map->lambda_idx;
	/* fetch other useful data */
	SV* smoother = *hvref_fetch(self, "smoother");
        int x_num = SvIV(*hvref_fetch(self, "x_num"));
	int y_num = SvIV(*hvref_fetch(self, "y_num"));
	int f_num = SvIV(*hvref_fetch(self, "f_num"));
	/* intermediate variables */
	AV* av_d_log_lh;
	char* smoother_type;
	int i, j, x, y, lambda_i;
        double log_lh, sum_exp_lambda_f, sigma, fxy;
	double* lambda_f = (double*)malloc(sizeof(double) * y_num);
	double* exp_lambda_f = (double*)malloc(sizeof(double) * y_num);
	double* d_log_lh = (double*)malloc(sizeof(double) * f_num);
	double* lambda = (double*)malloc(sizeof(double) * f_num);
    CODE:
        /* initialize */
	TRACE("enter");
	for (i = 0; i < f_num; i++)
	    lambda[i] = SvNV(*av_fetch(lambda_in, i, 0));
	log_lh = 0;	
	for (i = 0; i < f_num; i++) d_log_lh[i] = 0;
	TRACE("finish initializing");
	/* calculate log likelihood and its gradient */
        for (i = 0; i < samples->s_num; i++) {
	    /* log likelihood */
	    for (sum_exp_lambda_f = 0, y = 0; y < y_num; y++) {
	        for (lambda_f[y] = 0, j = 0; j < samples->x_len[i]; j++) {
		    lambda_i = lambda_idx[y][samples->x[i][j]];
		    if (lambda_i != -1) lambda_f[y] += lambda[lambda_i];
		}
		sum_exp_lambda_f += (exp_lambda_f[y] = exp(lambda_f[y]));
	    }
	    log_lh += samples->w[i] * 
	        (lambda_f[samples->y[i]] - log(sum_exp_lambda_f));
	    /* gradient */
	    for (y = 0; y < y_num; y++) {
		fxy = (y == samples->y[i] ? 1.0 : 0.0);
		for (j = 0; j < samples->x_len[i]; j++) {
		    lambda_i = lambda_idx[y][samples->x[i][j]];
		    if (lambda_i != -1)
		        d_log_lh[lambda_i] += samples->w[i] *
			    (fxy - exp_lambda_f[y] / sum_exp_lambda_f);
		}
	    }
	}
	TRACE("finish log likelihood and gradient");
	/* smoothing */
	if (SvOK(smoother) && hvref_exists(smoother, "type")) {
	    smoother_type = SvPV_nolen(*hvref_fetch(smoother, "type"));
	    if (strcmp(smoother_type, "gaussian") == 0) {
	        sigma = SvOK(*hvref_fetch(smoother, "sigma")) ?
		    SvNV(*hvref_fetch(smoother, "sigma")) : 1.0;
		for (i = 0; i < f_num; i++) {
		    log_lh -= (lambda[i] * lambda[i]) / (2 * sigma * sigma);
		    d_log_lh[i] -= lambda[i] / (sigma * sigma);
		}
	    }
	}
	TRACE("finish smoothing");
	/* negate the value and finish */
	log_lh = -log_lh;
        av_d_log_lh = newAV();
	av_extend(av_d_log_lh, f_num - 1);
	for (i = 0; i < f_num; i++)
	    av_store(av_d_log_lh, i, newSVnv(-d_log_lh[i]));
	f = sv_2mortal(newSVnv(log_lh));
	g = sv_2mortal(newRV_noinc((SV*)av_d_log_lh));
	TRACE("leave");
    CLEANUP:
	free(lambda_f);
	free(exp_lambda_f);
	free(d_log_lh);
	free(lambda);

SV*
_apply_gis(self, progress_cb, epsilon)
        SV*     self
	SV*     progress_cb
	double  epsilon
    PREINIT:
        dSP;
	dTRACE("_apply_gis");
        /* fetch the pre-cached samples and f_map */
        SV* _c = *hvref_fetch(self, "_c");
	struct samples_t* samples =
	    INT2PTR(struct samples_t*, SvIV(*hvref_fetch(_c, "samples")));
	struct f_map_t* f_map =
	    INT2PTR(struct f_map_t*, SvIV(*hvref_fetch(_c, "f_map")));
	int** lambda_idx = f_map->lambda_idx;
	/* fetch other useful data */
	AV* f_freq = (AV*)SvRV(*hvref_fetch(self, "f_freq"));
        int x_num = SvIV(*hvref_fetch(self, "x_num"));
	int y_num = SvIV(*hvref_fetch(self, "y_num"));
	int f_num = SvIV(*hvref_fetch(self, "f_num"));
	int af_num = SvIV(*hvref_fetch(self, "af_num"));
	/* intermediate variables */
	SV *sv_r;
	AV *av_lambda, *av_d_lambda;
	int i, j, k, y, lambda_i, r;
	double sum_exp_lambda_f, pxy;
	double d_lambda_norm, lambda_norm;
        double* p_f = (double*)malloc(sizeof(double) * f_num);
	double* p1_f = (double*)malloc(sizeof(double) * f_num);
	double* lambda = (double*)malloc(sizeof(double) * f_num);
	double* d_lambda = (double*)malloc(sizeof(double) * f_num);
	double* exp_lambda_f = (double*)malloc(sizeof(double) * y_num);
    CODE:
        TRACE("enter");
	/* initiate lambda */
	for (i = 0; i < f_num; i++) lambda[i] = 0;
	/* initiate p(f) */
        for (j = 0; j < y_num; j++)
	    for (i = 0; i < x_num; i++) {
	        lambda_i = lambda_idx[j][i];
	        if (lambda_i != -1) p_f[lambda_i] = SvNV(
		    *av_fetch((AV*)SvRV(*av_fetch(f_freq, j, 0)), i, 0)) +
		    1e-5;
            }
	/* iterate */
	k = 0;
	do {
	    TRACE("iteration");
	    /* get p1(f) for current lambda */
	    for (i = 0; i < f_num; i++) p1_f[i] = 0;
	    for (i = 0; i < samples->s_num; i++) {	        
	        for (sum_exp_lambda_f = 0, y = 0; y < y_num; y++) {
		    for (exp_lambda_f[y] = 0, j = 0; j < af_num; j++) {
		        lambda_i = lambda_idx[y][samples->x[i][j]];
		        if (lambda_i != -1)
			    exp_lambda_f[y] += lambda[lambda_i];
		    }
		    exp_lambda_f[y] = exp(exp_lambda_f[y]);
		    sum_exp_lambda_f += exp_lambda_f[y];
		}
		for (y = 0; y < y_num; y++) {
		    pxy = exp_lambda_f[y] / sum_exp_lambda_f;
		    for (j = 0; j < af_num; j++) {
		        lambda_i = lambda_idx[y][samples->x[i][j]];
			if (lambda_i != -1)
			    p1_f[lambda_i] += pxy * samples->w[i];
		    }
		}
	    }
	    /* lambda = lambda + d_lambda */
	    d_lambda_norm = 0;
	    lambda_norm = 0;
	    for (i = 0; i < f_num; i++) {
	        d_lambda[i] = (1.0 / af_num) * log(p_f[i] / p1_f[i]);
		lambda[i] += d_lambda[i];
		d_lambda_norm += d_lambda[i] * d_lambda[i];
		lambda_norm += lambda[i] * lambda[i];
	    }
	    d_lambda_norm = sqrt(d_lambda_norm);
	    lambda_norm = sqrt(lambda_norm);
	    /* call progress_cb if defined */
	    if (SvOK(progress_cb) && SvROK(progress_cb) &&
	        SvTYPE(SvRV(progress_cb)) == SVt_PVCV) {
	        TRACE("call progress_cb");
	        av_lambda = newAV();
		av_d_lambda = newAV();
		av_extend(av_lambda, f_num - 1);
		av_extend(av_d_lambda, f_num - 1);
		for (i = 0; i < f_num; i++) {
		    av_store(av_lambda, i, newSVnv(lambda[i]));
		    av_store(av_d_lambda, i, newSVnv(d_lambda[i]));
		}
	        ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSViv(k)));
		XPUSHs(sv_2mortal(newRV_noinc((SV*)av_lambda)));
		XPUSHs(sv_2mortal(newRV_noinc((SV*)av_d_lambda)));
		XPUSHs(sv_2mortal(newSVnv(lambda_norm)));
		XPUSHs(sv_2mortal(newSVnv(d_lambda_norm)));
		PUTBACK;
		call_sv(progress_cb, G_ARRAY);
		SPAGAIN;
		sv_r = POPs;
		r = SvIV(sv_r);
	        PUTBACK;
		FREETMPS;
		LEAVE;
                while (SvREFCNT(sv_r) > 0) { SvREFCNT_dec(sv_r); }
		if (r != 0) break;
	    }
	    k++;
	} while (d_lambda_norm > lambda_norm * epsilon);
	/* finish */
	av_lambda = newAV();
	av_extend(av_lambda, f_num - 1);
	for (i = 0; i < f_num; i++)
	    av_store(av_lambda, i, newSVnv(lambda[i]));
	RETVAL = newRV_noinc((SV*)av_lambda);
	TRACE("leave");
    OUTPUT:
        RETVAL
    CLEANUP:
        free(p_f);
	free(p1_f);
	free(lambda);
	free(d_lambda);
	free(exp_lambda_f);

void
_cache_samples(self)
        SV*     self
    PREINIT:
        SV* _c = *hvref_fetch(self, "_c");
        AV* samples = (AV*)SvRV(*hvref_fetch(self, "samples"));
	AV *sample, *x;	
        struct samples_t* ss =
	    (struct samples_t*)malloc(sizeof(struct samples_t));;
	int i, j;
    CODE:
        ss->s_num = av_len(samples) + 1;
        ss->x_len = (int*)malloc(sizeof(int) * ss->s_num);
	ss->x = (int**)malloc(sizeof(int*) * ss->s_num);
	ss->y = (int*)malloc(sizeof(int) * ss->s_num);
	ss->w = (double*)malloc(sizeof(double) * ss->s_num);
	for (i = 0; i < ss->s_num; i++) {
	    sample = (AV*)SvRV(*av_fetch(samples, i, 0));
	    x = (AV*)SvRV(*av_fetch(sample, 0, 0));
	    ss->x_len[i] = av_len(x) + 1;
	    ss->x[i] = (int*)malloc(sizeof(int) * ss->x_len[i]);
	    for (j = 0; j < ss->x_len[i]; j++)
	        ss->x[i][j] = SvIV(*av_fetch(x, j, 0));
	    ss->y[i] = SvIV(*av_fetch(sample, 1, 0));
	    ss->w[i] = SvNV(*av_fetch(sample, 2, 0));
        }
	hvref_store(_c, "samples", newSViv(PTR2IV(ss)));

void
_free_cache_samples(self)
        SV*     self
    PREINIT:
        SV* _c = *hvref_fetch(self, "_c");
        struct samples_t* ss = 
	    INT2PTR(struct samples_t*, SvIV(*hvref_fetch(_c, "samples")));
        int i;	
    CODE:
        free(ss->x_len);
	for (i = 0; i < ss->s_num; i++) free(ss->x[i]);
	free(ss->x);
	free(ss->y);
	free(ss->w);
	free(ss);
	hvref_delete(_c, "samples");
        
void
_cache_f_map(self)
        SV*     self
    PREINIT:
        SV* _c = *hvref_fetch(self, "_c");
        AV* f_map = (AV*)SvRV(*hvref_fetch(self, "f_map"));
	AV* f_map_y;
        struct f_map_t* fm =
	    (struct f_map_t*)malloc(sizeof(struct f_map_t));;
	int i, j, x_num;
    CODE:
	fm->y_num = av_len(f_map) + 1;
	fm->lambda_idx = (int**)malloc(sizeof(int*) * fm->y_num);
        for (j = 0; j < fm->y_num; j++) {
	    f_map_y = (AV*)SvRV(*av_fetch(f_map, j, 0));
	    x_num = av_len(f_map_y) + 1;
	    fm->lambda_idx[j] = (int*)malloc(sizeof(int) * x_num);
	    for (i = 0; i < x_num; i++)
	        fm->lambda_idx[j][i] = SvIV(*av_fetch(f_map_y, i, 0));
	}
	hvref_store(_c, "f_map", newSVuv(PTR2IV(fm)));

void
_free_cache_f_map(self)
        SV*     self
    PREINIT:
        SV* _c = *hvref_fetch(self, "_c");
        struct f_map_t* fm =
	    INT2PTR(struct f_map_t*, SvIV(*hvref_fetch(_c, "f_map")));
        int i;
    CODE:
        for (i = 0; i < fm->y_num; i++) free(fm->lambda_idx[i]);
        free(fm->lambda_idx); 
	free(fm);
	hvref_delete(_c, "f_map");

