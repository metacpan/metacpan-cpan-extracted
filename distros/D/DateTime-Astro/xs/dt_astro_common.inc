#ifndef __DT_ASTRO_COMMON_C__
#define __DT_ASTRO_COMMON_C__
#include "dt_astro.h"

STATIC_INLINE
int
__binary_search(mpfr_t *result, mpfr_t *lo, mpfr_t *hi, 
    int (*phi)(mpfr_t *, void *args, int n_args),
    void *args,
    int n_args,
    int (*mu)(mpfr_t *, mpfr_t *)
) {
    int loop = 1;
    while (loop) {
        mpfr_t x;
        mpfr_init_set(x, *lo, GMP_RNDN);
        mpfr_add(x, x, *hi, GMP_RNDN);
        mpfr_div_ui(x, x, 2, GMP_RNDN);

        if (mu(lo, hi) || mpfr_cmp(*hi, x) == 0 || mpfr_cmp(*lo, x) == 0) {
            mpfr_set(*result, x, GMP_RNDN);
            loop = 0;
        } else if (phi(&x, args, n_args)) {
            mpfr_set(*hi, x, GMP_RNDN);
        } else {
            mpfr_set(*lo, x, GMP_RNDN);
        }
        mpfr_clear(x);
    }

    return 1;
}

STATIC_INLINE
int
__search_next(mpfr_t *result, mpfr_t *base, 
    int (*check)(mpfr_t *x, void *args),
    void *check_args,
    int (*next_val)(mpfr_t *next, mpfr_t *x, void *args),
    void *next_args
) {
    mpfr_t x;

#if (0)
mpfr_fprintf(stderr,
    "__search_next for %.10RNf\n", *base);
#endif

    mpfr_init_set(x, *base, GMP_RNDN);
    while ( ! check(&x, check_args) ) {
        mpfr_t next;
        mpfr_init(next);
        next_val(&next, &x, next_args);
        mpfr_set(x, next, GMP_RNDN);
        mpfr_clear(next);
#if (0)
mpfr_fprintf(stderr,
    "x = %.10RNf\n", x);
#endif
    }
    mpfr_set( *result, x, GMP_RNDN );
    mpfr_clear(x);
    return 1;
}

STATIC_INLINE
int
dt_astro_mod( mpfr_t *result, mpfr_t *target, mpfr_t *base ) {
    mpfr_t p, r;

    /* target - floor(target / base) * base */
    mpfr_init_set( p, *target, GMP_RNDN );
    mpfr_div( p, p, *base, GMP_RNDN );
    mpfr_floor( p, p );

    mpfr_mul( p, p, *base, GMP_RNDN );
    mpfr_init_set( r, *target, GMP_RNDN );
    mpfr_sub( *result, r, p, GMP_RNDN );
    mpfr_clear(r);
    mpfr_clear(p);
    return 1;
}

STATIC_INLINE
int
dt_astro_sin( mpfr_t *result, mpfr_t *degrees ) {
    mpfr_t pi2, r;

    mpfr_init(pi2);
    mpfr_const_pi(pi2, GMP_RNDN);
    mpfr_mul_ui(pi2, pi2, 2, GMP_RNDN); /* pi * 2 */

    mpfr_init_set(r, pi2, GMP_RNDN);
    mpfr_div_ui(r, r, 360, GMP_RNDN);
    mpfr_mul(r, r, *degrees, GMP_RNDN);

    dt_astro_mod( &r, &r, &pi2 );
    mpfr_sin( *result, r, GMP_RNDN );

    mpfr_clear(r);
    mpfr_clear(pi2);
    return 1;
}

STATIC_INLINE
int
dt_astro_cos( mpfr_t *result, mpfr_t *degrees ) {
    mpfr_t pi2, r;

    mpfr_init(pi2);
    mpfr_const_pi(pi2, GMP_RNDN);
    mpfr_mul_ui(pi2, pi2, 2, GMP_RNDN); /* pi * 2 */

    mpfr_init_set(r, pi2, GMP_RNDN);
    mpfr_div_ui(r, r, 360, GMP_RNDN);
    mpfr_mul(r, r, *degrees, GMP_RNDN);

    dt_astro_mod( &r, &r, &pi2 );
    mpfr_cos( *result, r, GMP_RNDN );

    mpfr_clear(r);
    mpfr_clear(pi2);
    return 1;
}

STATIC_INLINE
int
dt_astro_polynomial( mpfr_t *result, mpfr_t *x, int howmany, mpfr_t **coefs) {
    int i;
    mpfr_t *m;

    mpfr_set_ui( *result, 0, GMP_RNDN);
    if (howmany <= 0) {
        return 0;
    }

    m = coefs[0];
    for (i = howmany - 1; i > 0; i--) {
        mpfr_t p; /* v + next */
        mpfr_init(p);
        mpfr_add( p, *result, *(coefs[i]), GMP_RNDN );
        mpfr_mul( *result, *x, p, GMP_RNDN );
        mpfr_clear(p);
    }

    mpfr_add(*result, *result, *m, GMP_RNDN);
    return 1;
}

STATIC_INLINE
int
polynomial(mpfr_t *result, mpfr_t *x, int howmany, ...) {
    va_list argptr;
    mpfr_t **coefs;
    int i;

    va_start(argptr, howmany);
    mpfr_set_ui( *result, 0, GMP_RNDN );

    Newxz(coefs, howmany, mpfr_t *);
    for(i = 0; i < howmany; i++) {
        coefs[i] = va_arg(argptr, mpfr_t *);
    }
    va_end(argptr);

    dt_astro_polynomial( result, x, howmany, coefs);

    Safefree(coefs);

    return 1;
}

STATIC_INLINE
int
is_leap_year(int y) {
    if (y % 4) return 0;
    if (y % 100) return 1;
    if (y % 400) return 0;
    return 1;
}

STATIC_INLINE
long
gregorian_year_from_rd(long rd) {
    double approx;
    double start;

    approx = floor( (rd - RD_GREGORIAN_EPOCH + 2) * 400 / 146097 );
    start = RD_GREGORIAN_EPOCH + 365 * approx + floor(approx/4) - floor(approx/100) + floor(approx/400);

    if (rd < start) {
        return (int) approx;
    } else {
        return (int) (approx + 1);
    }
}

STATIC_INLINE
int
fixed_from_ymd(int y, int m, int d) {
    return
        365 * (y -1) +
        floor( (y - 1) / 4 ) -
        floor( (y - 1) / 100 ) +
        floor( (y - 1) / 400 ) +
        floor( (367 * m - 362) / 12 ) +
        ( m <= 2 ? 0 :
          m  > 2 && is_leap_year(y) ? -1 :
          -2 
        ) + d
    ;
}

STATIC_INLINE
int
gregorian_components_from_rd(long rd, long *y, int *m, int *d) {
    int prior_days;
    *y = gregorian_year_from_rd( RD_GREGORIAN_EPOCH - 1 + rd + 306);

    prior_days = rd - fixed_from_ymd( *y - 1, 3, 1 );
    *m = (int) ( ((int) floor((5 * prior_days + 155) / 153) + 2) % 12 );
    if (*m == 0) *m = 12;
    *y = (long) (*y - floor( (*m + 9) / 12 ));
    *d = (int) ( rd - fixed_from_ymd(*y, *m, 1) + 1);
    return 1;
}

STATIC_INLINE
int
ymd_seconds_from_moment(mpfr_t *moment, long *y, int *m, int *d, int *s) {
    long rd;
    mpfr_t frac;

    rd = mpfr_get_si( *moment, GMP_RNDN );
    gregorian_components_from_rd( rd, y, m, d );
    mpfr_init_set(frac, *moment, GMP_RNDN);
    mpfr_sub_ui(frac, frac, rd, GMP_RNDN); /* now only fractional part */
    mpfr_mul_ui(frac, frac, 86400, GMP_RNDN); /* now seconds */

    *s = mpfr_get_si( frac, GMP_RNDN );
    mpfr_clear(frac);
    return 1;
}

static int
EC_C(mpfr_t *result, int y) {
    mpfr_set_d(
        *result,
        fixed_from_ymd(y, 7, 1) - RD_MOMENT_1900_JAN_1,
        GMP_RNDN
    );
    mpfr_div_ui( *result, *result, 3652510, GMP_RNDN );
    return 1;
}

STATIC_INLINE
int
EC2(mpfr_t *correction, mpfr_t *ec_c) {
    mpfr_t a, b, c, d, e, f, g, h;
    mpfr_init_set_d(a, -0.00002, GMP_RNDN);
    mpfr_init_set_d(b,  0.000297, GMP_RNDN);
    mpfr_init_set_d(c,  0.025184, GMP_RNDN);
    mpfr_init_set_d(d, -0.181133, GMP_RNDN);
    mpfr_init_set_d(e,  0.553040, GMP_RNDN);
    mpfr_init_set_d(f, -0.861938, GMP_RNDN);
    mpfr_init_set_d(g,  0.677066, GMP_RNDN);
    mpfr_init_set_d(h, -0.212591, GMP_RNDN);

    polynomial(correction, ec_c, 8, &a, &b, &c, &d, &e, &f, &g, &h);

    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    mpfr_clear(d);
    mpfr_clear(e);
    mpfr_clear(f);
    mpfr_clear(g);
    mpfr_clear(h);
    return 1;
}

STATIC_INLINE
int
EC3(mpfr_t *correction, mpfr_t *ec_c) {
    mpfr_t a, b, c, d, e, f, g, h, i, j, k;
    mpfr_init_set_d(a, -0.000009, GMP_RNDN);
    mpfr_init_set_d(b, 0.003844, GMP_RNDN);
    mpfr_init_set_d(c, 0.083563, GMP_RNDN);
    mpfr_init_set_d(d, 0.865736, GMP_RNDN);
    mpfr_init_set_d(e, 4.867575, GMP_RNDN);
    mpfr_init_set_d(f, 15.845535, GMP_RNDN);
    mpfr_init_set_d(g, 31.332267, GMP_RNDN);
    mpfr_init_set_d(h, 38.291999, GMP_RNDN);
    mpfr_init_set_d(i, 28.316289, GMP_RNDN);
    mpfr_init_set_d(j, 11.636204, GMP_RNDN);
    mpfr_init_set_d(k, 2.043794, GMP_RNDN);

    polynomial(correction, ec_c, 11, &a, &b, &c, &d, &e, &f, &g, &h, &i, &j, &k);

    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    mpfr_clear(d);
    mpfr_clear(e);
    mpfr_clear(f);
    mpfr_clear(g);
    mpfr_clear(h);
    mpfr_clear(i);
    mpfr_clear(j);
    mpfr_clear(k);

    return 1;
}

STATIC_INLINE
int
EC4(mpfr_t *correction, int year) {
    mpfr_t y, a, b, c, d;

    mpfr_init_set_si(y, year, GMP_RNDN);
    mpfr_init_set_d(a, 8.118780842, GMP_RNDN);
    mpfr_init_set_d(b, -0.005092142, GMP_RNDN);
    mpfr_init_set_d(c, 0.003336121, GMP_RNDN);
    mpfr_init_set_d(d, -0.0000266484, GMP_RNDN);

    polynomial(correction, &y, 4, &a, &b, &c, &d);
    mpfr_div_ui(*correction, *correction, 86400, GMP_RNDN);
    mpfr_clear(y);
    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    mpfr_clear(d);
    return 1;
}

STATIC_INLINE
int
EC5(mpfr_t *correction, int year) {
    mpfr_t y, a, b, c;

    mpfr_init_set_si(y, year, GMP_RNDN);
    mpfr_init_set_d(a, 196.58333, GMP_RNDN);
    mpfr_init_set_d(b, -4.0675, GMP_RNDN);
    mpfr_init_set_d(c, 0.0219167, GMP_RNDN);
    polynomial(correction, &y, 3, &a, &b, &c);
    mpfr_div_ui(*correction, *correction, 86400, GMP_RNDN);

    mpfr_clear(y);
    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    return 1;
}

STATIC_INLINE
int
EC6(mpfr_t *correction, int year) {
    mpfr_t x;

    { /* used to be called EC_X... now inlined */
        mpfr_init(x);
        mpfr_set_d(
            x,
            fixed_from_ymd(year, 1, 1) - RD_MOMENT_1810_JAN_1,
            GMP_RNDN
        );
    }

    mpfr_pow_ui( *correction, x, 2, GMP_RNDN );
    mpfr_div_ui( *correction, *correction, 41048480, GMP_RNDN );
    mpfr_sub_ui( *correction, *correction, 15, GMP_RNDN );
    mpfr_div_ui( *correction, *correction, 86400, GMP_RNDN );

    mpfr_clear(x);
    return 1;
}

STATIC_INLINE
int
ephemeris_correction(mpfr_t *correction, int y) {
    if (1988 <= y && y <= 2019) {
        mpfr_set_si( *correction, y - 1933, GMP_RNDN );
        mpfr_div_si( *correction, *correction, 86400, GMP_RNDN );
    } else if ( 1900 <= y && y <= 1987 ) {
        mpfr_t c;
        mpfr_init(c);
        EC_C(&c, y);
        EC2(correction, &c);
        mpfr_clear(c);
    } else if ( 1800 <= y && y <= 1899 ) {
        mpfr_t c;
        mpfr_init(c);
        EC_C(&c, y);
        EC3(correction, &c);
        mpfr_clear(c);
    } else if ( 1700 <= y && y <= 1799 ) {
        EC4(correction, y - 1700);
    } else if ( 1620 <= y && y <= 1699 ) {
        EC5(correction, y - 1600);
    } else {
        EC6(correction, y);
    }
    return 1;
}

STATIC_INLINE
int
dynamical_moment(mpfr_t *result, mpfr_t *moment) {
    mpfr_t correction;
    long rd;
    mpfr_init(correction);
    mpfr_set( *result, *moment, GMP_RNDN );

    rd = mpfr_get_si(*moment, GMP_RNDN);

    ephemeris_correction(&correction, gregorian_year_from_rd(rd));
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "moment = %.10RNf, correction = %.10RNf\n",
    *moment, correction);
#endif
#endif
    mpfr_add( *result, *result, correction, GMP_RNDN );
    mpfr_clear(correction);
    return 1;
}

STATIC_INLINE
int
julian_centuries(mpfr_t *result, mpfr_t *moment) {
    dynamical_moment(result, moment);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "moment = %.10RNf, dynamical = %.10RNf\n",
    *moment, *result );
#endif
#endif
    mpfr_sub_d( *result, *result, RD_MOMENT_J2000, GMP_RNDN );
    mpfr_div_ui( *result, *result, 36525, GMP_RNDN );
    return 1;
}

STATIC_INLINE
int
aberration(mpfr_t *result, mpfr_t *moment) {
    /* 0.0000974 * cos( 177.63 + 35999.01848 * julian_centuries(moment) ) - 0.0005575 */
    julian_centuries(result, moment);
    mpfr_mul_d( *result, *result, 35999.01848, GMP_RNDN );
    mpfr_add_d( *result, *result, 177.63, GMP_RNDN );
    dt_astro_cos( result, result );
    mpfr_mul_d( *result, *result, 0.000094, GMP_RNDN );
    mpfr_sub_d( *result, *result, 0.0005575, GMP_RNDN );

    return 1;
}

STATIC_INLINE
int
nutation( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t A, B, C;
    mpfr_init(C);
    julian_centuries(&C, moment);

    {
        mpfr_t a, b, c;
        mpfr_init(A);
        mpfr_init_set_d( a, 124.90, GMP_RNDN );
        mpfr_init_set_d( b, -1934.134, GMP_RNDN );
        mpfr_init_set_d( c, 0.002063, GMP_RNDN );

        polynomial(&A, &C, 3, &a, &b, &c);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(B);
        mpfr_init_set_d( a, 201.11, GMP_RNDN );
        mpfr_init_set_d( b, 72001.5377, GMP_RNDN );
        mpfr_init_set_d( c, 0.00057, GMP_RNDN );
        polynomial(&B, &C, 3, &a, &b, &c);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    dt_astro_sin(&A, &A);
    mpfr_mul_d(A, A, -0.004778, GMP_RNDN);
    dt_astro_sin(&B, &B);
    mpfr_mul_d(B, B, -0.0003667, GMP_RNDN);
    mpfr_add(*result, A, B, GMP_RNDN);

    mpfr_clear(A);
    mpfr_clear(B);
    mpfr_clear(C);
    return 1;
}

#endif /** __DT_ASTRO_COMMON_C__ **/

