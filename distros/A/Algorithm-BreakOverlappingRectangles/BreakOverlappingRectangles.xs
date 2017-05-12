/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define X0 0
#define Y0 1
#define X1 2
#define Y1 3

#define IDOFFSET (sizeof(NV) * 4)
#define BRUTEFORCECUTOFF 40

#if 1
#define DP(f)
#define DUMP(msg, av, start)
#define my_assert(a) assert(a)
#else

#define my_assert(a)  if(!(a)) _failed_assertion(aTHX_ #a, __LINE__, __FILE__) 

#define DP(f) f
#define DUMP(msg, av, start) _dump(aTHX_ (msg), (av), (start))
static void
_dump(pTHX_ char *msg, AV *rects, I32 start) {
    I32 end = av_len(rects) + 1;
    SV **svs = AvARRAY(rects);
    I32 i;
    fprintf (stderr, "%s = start: %d, end: %d", msg, start, end);
    for (i = start; i < end; i++) {
        SV *sv = svs[i];
        if (SvOK(sv)) {
            STRLEN len, j;
            NV* nv = (NV*)SvPV(svs[i], len);
            IV* iv = (IV*)(SvPV_nolen(svs[i]) + IDOFFSET);
            len = (len - IDOFFSET) / sizeof(IV);
            fprintf (stderr, " [%.0f %.0f %.0f %.0f |", nv[0], nv[1], nv[2], nv[3]);
            for (j = 0; j < len; j++)
                fprintf(stderr, " %d", iv[j]);
            fprintf(stderr, "]");
        }
        else
            fprintf(stderr, " undef");
    }
    fprintf(stderr, "\n");
    fflush(stderr);
}
void _failed_assertion(pTHX_ char *str, int line, char *file) {
    fprintf(stderr, "assertion %s failed at %s line %d\n", str, line, file);
    fflush(stderr);
    exit(1);
}

#endif

static SV *
av_sure_fetch(pTHX_ AV *av, I32 i) {
    SV **sv = av_fetch(av, i, 0);
    my_assert(sv);
    return *sv;
}

static NV
sqr (NV a) {
    return a * a;
}
int

double_cmp(pTHX_ double *a, double *b) {
    double fa = *a;
    double fb = *b;
    DP(printf("cmp(%f, %f) => %d\n", fa, fb, (fa < fb) ? -1 : ((fa > fb) ? 1 : 0)));
    return (fa < fb) ? -1 : ((fa > fb) ? 1 : 0);
}

void
sort_inplace(pTHX_ double **v, int size) {
    sortsv((SV**)v, size, (SVCOMPARE_t)&double_cmp);
}

static NV
find_best_cut(pTHX_ AV *rects, I32 start, I32 end, int dir, NV *bestv) {
    NV **v0, **v1, **vc0, **vc1;
    NV v, med, best;
    int op, cl;
    int i;
    SV **svs;
    I32 size = end - start;

    my_assert(bestv);
    
    DUMP("fbc  in", rects, start);
    DP(fprintf(stderr, "end: %d\n", end));
    
    Newx(v0, size + 1, NV *);
    Newx(v1, size + 1, NV *);
    
    v0[size] = v1[size] = NULL;
    
    vc0 = v0; vc1 = v1;

    svs = AvARRAY(rects) + start;
    size = end - start;
    
    for (i = 0; i < size; i++) {
        NV *nv = (NV*)SvPV_nolen(svs[i]);
        if (dir == 'x') {
            v0[i] = nv + X0;
            v1[i] = nv + X1;
        }
        else {
            v0[i] = nv + Y0;
            v1[i] = nv + Y1;
        }
    }
    v0[size] = v1[size] = NULL;

    sort_inplace(aTHX_ v0, size);
    sort_inplace(aTHX_ v1, size);
    
    op = cl = 0;
    med = 0.5 * size;
    best =  .24 * sqr(size);

    my_assert(best >= 0);
             
    while (*v0 && *v1) {
        NV v, good;
        NV l, r;
        
        v =  (**v0 <= **v1) ? **v0 : **v1;

        while (*v0 && v == **v0) {
            op++;
            v0++;
        }
        while (*v1 && v == **v1) {
            cl++;
            v1++;
        }

        my_assert(op > 0 && op <= size);
        my_assert(cl >= 0 && cl <= size);
        
        l = op - med;
        r = size - cl - med;
        good = sqr(l) + sqr(r);

        my_assert(good >= 0);
        
        if (good < best) {
            DP(fprintf(stderr, "find_best_cut l: %.2f, r: %.2f, good: %.2f\n", l, r, good));
            best = good;
            *bestv = v;
        }
    }

    Safefree(vc0);
    Safefree(vc1);
    
    return best;
}

static void
_break(pTHX_ AV *rects, I32 start, AV *parts);

static void
_brute_force_merge(pTHX_ AV *rects, I32 start, AV *parts) {
    I32 i, len;
    for (i = start; i <= av_len(rects); i++) {
        SV *svr = (AvARRAY(rects))[i];
        I32 j;
        for (j=0; j <= av_len(parts);) {
            NV *r = (NV*) SvPV_nolen(svr);
            SV *svp = (AvARRAY(parts))[j];
            NV *p = (NV*) SvPV_nolen(svp);
            
            if ((r[X1] > p[X0]) &&
                (r[X0] < p[X1]) &&
                (r[Y1] > p[Y0]) &&
                (r[Y0] < p[Y1])) {
                if ((r[X0] == p[X0]) &&
                    (r[Y0] == p[Y0]) &&
                    (r[X1] == p[X1]) &&
                    (r[Y1] == p[Y1])) {
                    SV *last;
                    STRLEN len;
                    char *pv = SvPV(svp, len);
                    sv_catpvn(svr, pv + IDOFFSET, len - IDOFFSET);
                    last = av_pop(parts);
                    if (last == svp)
                        SvREFCNT_dec(last);
                    else
                        av_store(parts, j, last);
                }
                else {
                    NV x[4], y[4];
                    /* sort xs and ys */
                    if (r[X0] < p[X0]) {
                        x[0] = r[X0]; x[1] = p[X0];
                    }
                    else {
                        x[0] = p[X0]; x[1] = r[X0];
                    }
                    if (r[X1] < p[X1]) {
                        x[2] = r[X1]; x[3] = p[X1];
                    }
                    else {
                        x[2] = p[X1]; x[3] = r[X1];
                    }
                    if (r[Y0] < p[Y0]) {
                        y[0] = r[Y0]; y[1] = p[Y0];
                    }
                    else {
                        y[0] = p[Y0]; y[1] = r[Y0];
                    }
                    if (r[Y1] < p[Y1]) {
                        y[2] = r[Y1]; y[3] = p[Y1];
                    }
                    else {
                        y[2] = p[Y1]; y[3] = r[Y1];
                    }
                    
                    if ( ( ((x[3] - x[0]) > (y[3] - y[0])) &&
                           ((x[0] != x[1]) || (x[2] != x[3])) ) ||
                         ((y[0] == y[1]) && (y[2] == y[3])) ) {
                        NV b = ((sqr(x[1] - x[0]) + sqr(x[1] - x[3]))
                                < (sqr(x[2] - x[0]) + sqr(x[2] - x[3])) ? x[1] : x[2]);
                        if ((r[X0] < b) && (r[X1] > b)) {
                            SV *svcp = newSVsv(svr);
                            NV *cp = (NV*)SvPV_nolen(svcp);
                            cp[X0] = b;
                            av_push(rects, svcp);
                            
                            /* fprintf(stderr, "[%f %f %f %f] -> [%f %f %f %f], [%f %f %f %f]\n",
                               r[0], r[1], r[2], r[3],
                               cp[0], cp[1], cp[2], cp[3],
                               b, r[1], r[2], r[3]); fflush(stderr); */
                            
                            r[X1] = b;
                        }
                        if ((p[X0] < b) && (p[X1] > b)) {
                            SV *svcp = newSVsv(svp);
                            NV *cp = (NV*)SvPV_nolen(svcp);
                            cp[X0] = b;
                            av_push(parts, svcp);
                            
                            /* fprintf(stderr, "[%f %f %f %f] -> [%f %f %f %f], [%f %f %f %f]\n",
                               p[0], p[1], p[2], p[3],
                               cp[0], cp[1], cp[2], cp[3],
                               p[0], p[1], b, p[3]); fflush(stderr); */
                            
                            p[X1] = b;
                        }
                    }
                    else {
                        NV b = ((sqr(y[1] - y[0]) + sqr(y[1] - y[3]))
                                < (sqr(y[2] - y[0]) + sqr(y[2] - y[3])) ? y[1] : y[2]);
                        if ((r[Y0] < b) && (r[Y1] > b)) {
                            SV *svcp = newSVsv(svr);
                            NV *cp = (NV*)SvPV_nolen(svcp);
                            cp[Y0] = b;
                            av_push(rects, svcp);
                            
                            /* fprintf(stderr, "[%f %f %f %f] -> [%f %f %f %f], [%f %f %f %f]\n",
                               r[0], r[1], r[2], r[3],
                               cp[0], cp[1], cp[2], cp[3],
                               r[0], b, r[2], r[3]); fflush(stderr); */
                            
                            r[Y1] = b;
                        }
                        if ((p[Y0] < b) && (p[Y1] > b)) {
                            SV *svcp = newSVsv(svp);
                            NV *cp = (NV*)SvPV_nolen(svcp);
                            cp[Y0] = b;
                            av_push(parts, svcp);
                            
                            /* fprintf(stderr, "[%f %f %f %f] -> [%f %f %f %f], [%f %f %f %f]\n",
                               p[0], p[1], p[2], p[3],
                               cp[0], cp[1], cp[2], cp[3],
                               p[0], p[1], p[2], b); fflush(stderr); */
                            
                            p[Y1] = b;
                        }
                    }
                    continue;
                }
            }
            j++;
        }
    }
    /*
    for (i = av_len(parts); i >= 0; i--)
        av_push(rects, av_pop(parts));
    */
    if ((len = av_len(parts)) >= 0) {
        SV **svrs, **svps;
        I32 start = av_len(rects) + 1;
        av_extend(rects, start + len);
        svrs = AvARRAY(rects) + start;
        svps = AvARRAY(parts);
        AvFILLp(parts) = -1;
        AvFILLp(rects) = start + len;

        do {
            svrs[len] = svps[len];
            svps[len] = &PL_sv_undef;
        } while (--len >= 0);
    }
}

static void
_brute_force_break(pTHX_ AV *rects, I32 start, AV *parts) {
    I32 i, j, end1;

    DUMP("bfb  in", rects, start);

    end1 = av_len(rects);
    if (end1 < start + 1)
        return;

    if (end1 - start > 2 * BRUTEFORCECUTOFF ) {
        SV **svs;
        I32 end;
        I32 middle = (start + end1 + 1) / 2;
        _break(aTHX_ rects, middle, parts);

        svs = AvARRAY(rects);
    
        end = av_len(rects) + 1;

        i = start;
        j = end;
        while (i < middle && j > middle) {
            j--;
            SV *tmp = svs[i];
            svs[i] = svs[j];
            svs[j] = tmp;
            i++;
        }

        middle = start + end - middle;
        _break(aTHX_ rects, middle, parts);
        
        end = av_len(rects);

        if ((end - start) > (end1 - start) * 1.2)
            return _break(aTHX_ rects, start, parts);

        while (end-- >= middle)
            av_push(parts, av_pop(rects));

        return _brute_force_merge(aTHX_ rects, start, parts);
    }

    while (--end1 >= start) {
        SV *last, *next;
        SV **svs;

        DP(fprintf(stderr, "bfb: start: %d, end1: %d, end: %d\n", start, end1, av_len(rects) + 1));

        svs = AvARRAY(rects);
        last = svs[AvFILLp(rects)];
        svs[AvFILLp(rects)--] = &PL_sv_undef;
        next = svs[end1];
        svs[end1] = last;
        av_push(parts, next);

        _brute_force_merge(aTHX_ rects, end1, parts);
    }
    return;
}

static void
_break(pTHX_ AV *rects, I32 start, AV *parts) {
    NV bestx, bestxx, besty, bestyy, div;
    int off;
    I32 i, j, middle, end;
    SV **svs;
    
    DUMP("break", rects, start);

    while (1) {

        end = av_len(rects) + 1;

        if ((end - start) <= BRUTEFORCECUTOFF)
            return _brute_force_break(aTHX_ rects, start, parts);

        bestx = find_best_cut(aTHX_ rects, start, end, 'x', &bestxx);
        besty = ((bestx == 0) ? 1 : find_best_cut(aTHX_ rects, start, end, 'y', &bestyy));

        if (bestx < besty) {
            off = X0;
            div = bestxx;
            DP(fprintf(stderr, "cutting at x=%.0f, best=%.2f\n", bestxx, bestx));
        }
        else {
            off = Y0;
            div = bestyy;
            DP(fprintf(stderr, "cutting at y=%.0f, best=%.2f\n", bestyy, besty));
        }
    
        svs = AvARRAY(rects);
        i = start;
        middle = end;
        while (i < middle) {
            SV *sv = svs[i];
            NV n0 = ((NV*)SvPV_nolen(sv))[off];
            if (n0 < div) {
                middle--;
                svs[i] = svs[middle];
                svs[middle] = sv;
            }
            else
                i++;
        }

        DUMP("b0", rects, start);
    
        if (middle == start || middle == end)
            return _brute_force_break(aTHX_ rects, start, parts);


        _break(aTHX_ rects, middle, parts);

        DUMP("b1", rects, start);

        svs = AvARRAY(rects);
    
        end = av_len(rects) + 1;

        i = start;
        j = end;
        while (i < middle && j > middle) {
            j--;
            SV *tmp = svs[i];
            svs[i] = svs[j];
            svs[j] = tmp;
            i++;
        }

        DUMP("b2", rects, start);

        end += start - middle;

        off += 2;
        i = start;
        middle = end;
        DP(fprintf(stderr, "i: %d, middle: %d\n", i, middle));
        while (i < middle) {
            SV *sv = svs[i];
            NV n0 = ((NV*)SvPV_nolen(sv))[off];
            if (n0 > div) {
                middle--;
                svs[i] = svs[middle];
                svs[middle] = sv;
            }
            else
                i++;
        }

        DUMP("b3", rects, start);

        if (middle == start)
            return _brute_force_break(aTHX_ rects, start, parts);

        start = middle;
    }
    /* _break(aTHX_ rects, middle); */
}

MODULE = Algorithm::BreakOverlappingRectangles		PACKAGE = Algorithm::BreakOverlappingRectangles		
PROTOTYPES: DISABLE

void
_break_rectangles(rects)
    AV *rects;
CODE:
    if (SvMAGICAL((SV*)rects))
        Perl_croak(aTHX_ "internal error: unacceptable magic AV found");
    _break(aTHX_ rects, 0, (AV*)sv_2mortal((SV*)newAV()));
