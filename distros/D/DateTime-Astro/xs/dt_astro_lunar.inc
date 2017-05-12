#ifndef __DT_ASTRO_LUNAR_C__
#define __DT_ASTRO_LUNAR_C__
#include "dt_astro.h"
#define NV_1E6 1000000.0

STATIC_INLINE
int
lunar_longitude( mpfr_t *result, mpfr_t *moment ) {

    mpfr_t C, mean_moon, elongation, solar_anomaly, lunar_anomaly, moon_node, E, correction, venus, jupiter, flat_earth, N, fullangle;

    mpfr_init(C);
    julian_centuries( &C, moment );

    {
        mpfr_t a, b, c, d, e;

        mpfr_init(mean_moon);
        mpfr_init_set_d(a, 218.316591, GMP_RNDN);
        mpfr_init_set_d(b, 481267.88134236, GMP_RNDN);
        mpfr_init_set_d(c, -0.0013268, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 538841, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e, 65194000, GMP_RNDN);

        polynomial( &mean_moon, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(elongation);

        mpfr_init_set_d(a, 297.8502042, GMP_RNDN);
        mpfr_init_set_d(b, 445267.1115168, GMP_RNDN);
        mpfr_init_set_d(c, -0.00163, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 545868, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e, 113065000, GMP_RNDN);
        polynomial( &elongation, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(solar_anomaly);
        mpfr_init_set_d(a, 357.5291092, GMP_RNDN);
        mpfr_init_set_d(b, 35999.0502909, GMP_RNDN);
        mpfr_init_set_d(c,  -0.0001536, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 24490000, GMP_RNDN);
        polynomial( &solar_anomaly, &C, 4, &a, &b, &c, &d );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(lunar_anomaly);

        mpfr_init_set_d(a, 134.9634114, GMP_RNDN);
        mpfr_init_set_d(b, 477198.8676313, GMP_RNDN);
        mpfr_init_set_d(c, 0.0008997, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 69699, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e,  14712000, GMP_RNDN);
        polynomial( &lunar_anomaly, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(moon_node);
        mpfr_init_set_d(a, 93.2720993, GMP_RNDN);
        mpfr_init_set_d(b, 483202.0175273, GMP_RNDN);
        mpfr_init_set_d(c, -0.0034029, GMP_RNDN);
        mpfr_init_set_si(d, -1, GMP_RNDN);
        mpfr_div_ui(d, d, 3526000, GMP_RNDN);
        mpfr_init_set_ui(e, 1, GMP_RNDN);
        mpfr_div_ui(e, e, 863310000, GMP_RNDN);
        polynomial(&moon_node, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(E);
        mpfr_init_set_ui(a, 1, GMP_RNDN);
        mpfr_init_set_d(b, -0.002516, GMP_RNDN);
        mpfr_init_set_d(c, -0.0000074, GMP_RNDN);
        polynomial( &E, &C, 3, &a, &b, &c );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        int i;
        mpfr_t fugly;
        mpfr_init_set_ui(fugly, 0, GMP_RNDN);

        for(i = 0; i < LUNAR_LONGITUDE_ARGS_SIZE; i++) {
            mpfr_t a, b, v, w, x, y, z;
            mpfr_init_set_d( v, LUNAR_LONGITUDE_ARGS[i][0], GMP_RNDN );
            mpfr_init_set_d( w, LUNAR_LONGITUDE_ARGS[i][1], GMP_RNDN );
            mpfr_init_set_d( x, LUNAR_LONGITUDE_ARGS[i][2], GMP_RNDN );
            mpfr_init_set_d( y, LUNAR_LONGITUDE_ARGS[i][3], GMP_RNDN );
            mpfr_init_set_d( z, LUNAR_LONGITUDE_ARGS[i][4], GMP_RNDN );

            mpfr_init(b);
            mpfr_pow(b, E, x, GMP_RNDN);

            mpfr_mul(w, w, elongation, GMP_RNDN);
            mpfr_mul(x, x, solar_anomaly, GMP_RNDN);
            mpfr_mul(y, y, lunar_anomaly, GMP_RNDN);
            mpfr_mul(z, z, moon_node, GMP_RNDN);

            mpfr_init_set(a, w, GMP_RNDN);
            mpfr_add(a, a, x, GMP_RNDN);
            mpfr_add(a, a, y, GMP_RNDN);
            mpfr_add(a, a, z, GMP_RNDN);
            dt_astro_sin(&a, &a);

            mpfr_mul(a, a, v, GMP_RNDN);
            mpfr_mul(a, a, b, GMP_RNDN);
            mpfr_add(fugly, fugly, a, GMP_RNDN);

            mpfr_clear(a);
            mpfr_clear(b);
            mpfr_clear(v);
            mpfr_clear(w);
            mpfr_clear(x);
            mpfr_clear(y);
            mpfr_clear(z);
        }

        mpfr_init_set_d( correction, 0.000001, GMP_RNDN );
        mpfr_mul( correction, correction, fugly, GMP_RNDN);
        mpfr_clear(fugly);
    }

    {
        mpfr_t a, b;
        mpfr_init(venus);
        mpfr_init_set_d(a, 119.75, GMP_RNDN);
        mpfr_init_set(b, C, GMP_RNDN);
        mpfr_mul_d(b, b, 131.849, GMP_RNDN);

        mpfr_add(a, a, b, GMP_RNDN);
        dt_astro_sin(&a, &a);
        mpfr_mul_d(venus, a, 0.003957, GMP_RNDN );
        mpfr_clear(a);
        mpfr_clear(b);
    }

    {
        mpfr_t a, b;
        mpfr_init(jupiter);
        mpfr_init_set_d(a, 53.09, GMP_RNDN);
        mpfr_init_set(b, C, GMP_RNDN);
        mpfr_mul_d(b, b, 479264.29, GMP_RNDN);
    
        mpfr_add(a, a, b, GMP_RNDN);
        dt_astro_sin(&a, &a);
        mpfr_mul_d(jupiter, a, 0.000318, GMP_RNDN );
        mpfr_clear(a);
        mpfr_clear(b);
    }

    {
        mpfr_t a;
        mpfr_init(flat_earth);
        mpfr_init_set(a, mean_moon, GMP_RNDN);
        mpfr_sub(a, a, moon_node, GMP_RNDN);
        dt_astro_sin(&a, &a);
        mpfr_mul_d(flat_earth, a, 0.001962, GMP_RNDN);
        mpfr_clear(a);
    }

    mpfr_set(*result, mean_moon, GMP_RNDN);
    mpfr_add(*result, *result, correction, GMP_RNDN);
    mpfr_add(*result, *result, venus, GMP_RNDN);
    mpfr_add(*result, *result, jupiter, GMP_RNDN);
    mpfr_add(*result, *result, flat_earth, GMP_RNDN);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "mean_moon = %.10RNf\ncorrection = %.10RNf\nvenus = %.10RNf\njupiter = %.10RNf\nflat_earth = %.10RNf\n",
    mean_moon,
    correction,
    venus,
    jupiter,
    flat_earth);
#endif
#endif

    mpfr_init(N);
    nutation(&N, moment);
    mpfr_add(*result, *result, N, GMP_RNDN);

    mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "lunar = mod(%.10RNf) = ", *result );
#endif
#endif
    dt_astro_mod(result, result, &fullangle);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "%.10RNf\n", *result );
#endif
#endif

    mpfr_clear(C);
    mpfr_clear(mean_moon);
    mpfr_clear(elongation);
    mpfr_clear(solar_anomaly);
    mpfr_clear(lunar_anomaly);
    mpfr_clear(moon_node);
    mpfr_clear(E);
    mpfr_clear(correction);
    mpfr_clear(venus);
    mpfr_clear(jupiter);
    mpfr_clear(flat_earth);
    mpfr_clear(N);
    mpfr_clear(fullangle);
    return 1;
}

STATIC_INLINE
int
lunar_phase( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t sl, ll, fullangle;
    mpfr_init(sl);
    mpfr_init(ll);
    mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

    solar_longitude( &sl, moment );
    lunar_longitude( &ll, moment );
    mpfr_sub(*result, ll, sl, GMP_RNDN );
    dt_astro_mod(result, result, &fullangle);

    mpfr_clear(sl);
    mpfr_clear(ll);
    mpfr_clear(fullangle);
    return 1;
}

STATIC_INLINE
void
adjust_lunar_phase_to_zero(mpfr_t *result) {
    mpfr_t ll, delta;
    int mode = -1;
    int loop = 1;
    int count = 0;
    /* Adjust values so that it's as close as possible to 0 degrees.
     * if we have a delta of 1 degree, then we're about
     *  1 / ( 360 / MEAN_SYNODIC_MONTH )
     * days apart
     */

    mpfr_init(ll);
    mpfr_init_set_d(delta, 0.0001, GMP_RNDN);

    while (loop) {
        int flipped = mode;
        mpfr_t new_moment;
        count++;
        mpfr_init(new_moment);
        lunar_phase(&ll, result);
#if (TRACE)
mpfr_fprintf(stderr,
    "Adjusting ll from (%.30RNf) moment is %.5RNf delta is %.30RNf\n", ll, *result, delta);
#endif
        /* longitude was greater than 180, so we're looking to add a few
         * degrees to make it close to 360 ( 0 )
         */
        if (mpfr_cmp_ui( ll, 180 ) > 0) {
            mode = 1;
            mpfr_sub_ui(delta, ll, 360, GMP_RNDN);
            mpfr_div_d(delta, delta, 360 / MEAN_SYNODIC_MONTH, GMP_RNDN);
            mpfr_add( new_moment, *result, delta, GMP_RNDN );
#if (TRACE)
mpfr_fprintf(stderr, "add %.30RNf -> %.30RNf\n", *result, new_moment);
#endif
            mpfr_set(*result, new_moment, GMP_RNDN);
            if (mpfr_cmp(new_moment, *result) == 0) {
                loop = 0;
            }
        } else if (mpfr_cmp_ui( ll, 180 ) < 0 ) {
            if ( mpfr_cmp_d( ll, 0.000000000000000000001 ) < 0) {
                loop = 0;
            } else {
                mode = 0;
                mpfr_sub_ui(delta, ll, 0, GMP_RNDN);
                mpfr_div_d(delta, delta, 360 / MEAN_SYNODIC_MONTH, GMP_RNDN);
                mpfr_sub( new_moment, *result, delta, GMP_RNDN );
#if (TRACE)
mpfr_fprintf(stderr, "sub %.120RNf -> %.120RNf\n", *result, new_moment);
#endif
                if (mpfr_cmp(new_moment, *result) == 0) {
                    loop = 0;
                }
                mpfr_set(*result, new_moment, GMP_RNDN);
            }
        } else {
            loop = 0;
        }
        if (flipped != -1 && flipped != mode) {
            mpfr_div_d(delta, delta, 1.1, GMP_RNDN);
        }
        mpfr_clear(new_moment);
    }
    mpfr_clear(delta);
    mpfr_clear(ll);
}

STATIC_INLINE
int
nth_new_moon( mpfr_t *result, int n_int ) {
    mpfr_t n, k, C, approx, E, solar_anomaly, lunar_anomaly, moon_argument, omega, extra, correction, additional;

#if(0)
PerlIO_printf(PerlIO_stderr(), "nth_new_moon = %d\n", n_int );
#endif
    if ( dt_astro_global_cache.cache_size > n_int ) {
        mpfr_t *cached = dt_astro_global_cache.cache[n_int];
        if (cached != NULL) {
#if(0)
            PerlIO_printf(PerlIO_stderr(), "Cache HIT for %d\n", n_int);
#endif
            mpfr_set( *result, *cached, GMP_RNDN );
            return 1;
        }
    }

    mpfr_init_set_ui( n, n_int, GMP_RNDN );

    /* k = n - 24724 */
    mpfr_init_set(k, n, GMP_RNDN);
    mpfr_sub_ui(k, k, 24724, GMP_RNDN );

    /* c = k / 1236.85 */
    mpfr_init_set(C, k, GMP_RNDN );
    mpfr_div_d(C, C, 1236.85, GMP_RNDN);

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(approx);
        mpfr_init_set_d(a, 730125.59765, GMP_RNDN );
        mpfr_init_set_d(b, MEAN_SYNODIC_MONTH * 1236.85, GMP_RNDN );
        mpfr_init_set_d(c, 0.0001337, GMP_RNDN );
        mpfr_init_set_d(d, -0.000000150, GMP_RNDN );
        mpfr_init_set_d(e, 0.00000000073, GMP_RNDN );
        polynomial( &approx, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "approx = %.10RNf\n", approx);
#endif
#endif
    }

    {
        mpfr_t a, b, c;
        mpfr_init(E);
        mpfr_init_set_ui(a, 1, GMP_RNDN);
        mpfr_init_set_d(b, -0.002516, GMP_RNDN );
        mpfr_init_set_d(c, -0.0000074, GMP_RNDN );
        polynomial( &E, &C, 3, &a, &b, &c );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(solar_anomaly);
        mpfr_init_set_d(a, 2.5534, GMP_RNDN);
        mpfr_init_set_d(b, 1236.85, GMP_RNDN);
        mpfr_mul_d(b, b, 29.10535669, GMP_RNDN);
        mpfr_init_set_d(c, -0.0000218, GMP_RNDN );
        mpfr_init_set_d(d, -0.00000011, GMP_RNDN );
        polynomial( &solar_anomaly, &C, 4, &a, &b, &c, &d);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(lunar_anomaly);
        mpfr_init_set_d(a, 201.5643, GMP_RNDN);
        mpfr_init_set_d(b, 385.81693528 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, 0.0107438, GMP_RNDN);
        mpfr_init_set_d(d, 0.00001239, GMP_RNDN);
        mpfr_init_set_d(e, -0.000000058, GMP_RNDN);
        polynomial( &lunar_anomaly, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(moon_argument);
        mpfr_init_set_d(a, 160.7108, GMP_RNDN);
        mpfr_init_set_d(b, 390.67050274 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, -0.0016431, GMP_RNDN);
        mpfr_init_set_d(d, -0.00000227, GMP_RNDN);
        mpfr_init_set_d(e, 0.000000011, GMP_RNDN);
        polynomial( &moon_argument, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(omega);
        mpfr_init_set_d(a, 124.7746, GMP_RNDN);
        mpfr_init_set_d(b, -1.56375580 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, 0.0020691, GMP_RNDN);
        mpfr_init_set_d(d, 0.00000215, GMP_RNDN);
        polynomial( &omega, &C, 4, &a, &b, &c, &d);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(extra);
        mpfr_init_set_d(a, 299.77, GMP_RNDN);
        mpfr_init_set_d(b, 132.8475848, GMP_RNDN);
        mpfr_init_set_d(c, -0.009173, GMP_RNDN);
        polynomial(&extra, &C, 3, &a, &b, &c);
        dt_astro_sin(&extra, &extra);
        mpfr_mul_d(extra, extra, 0.000325, GMP_RNDN);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    mpfr_init(correction);
    dt_astro_sin(&correction, &omega);
    mpfr_mul_d(correction, correction, -0.00017, GMP_RNDN);

    {
        int i;
        for( i = 0; i < NTH_NEW_MOON_CORRECTION_ARGS_SIZE; i++ ) {
            mpfr_t a, v, w, x, y, z;
            mpfr_init_set_d(v, NTH_NEW_MOON_CORRECTION_ARGS[i][0], GMP_RNDN);
            mpfr_init_set_d(w, NTH_NEW_MOON_CORRECTION_ARGS[i][1], GMP_RNDN);
            mpfr_init_set_d(x, NTH_NEW_MOON_CORRECTION_ARGS[i][2], GMP_RNDN);
            mpfr_init_set_d(y, NTH_NEW_MOON_CORRECTION_ARGS[i][3], GMP_RNDN);
            mpfr_init_set_d(z, NTH_NEW_MOON_CORRECTION_ARGS[i][4], GMP_RNDN);

            mpfr_mul(x, x, solar_anomaly, GMP_RNDN);
            mpfr_mul(y, y, lunar_anomaly, GMP_RNDN);
            mpfr_mul(z, z, moon_argument, GMP_RNDN);

            mpfr_add(x, x, y, GMP_RNDN);
            mpfr_add(x, x, z, GMP_RNDN);
            dt_astro_sin(&x, &x);

            mpfr_init(a);
            mpfr_pow(a, E, w, GMP_RNDN);

            mpfr_mul(a, a, v, GMP_RNDN);
            mpfr_mul(a, a, x, GMP_RNDN);
            mpfr_add( correction, correction, a, GMP_RNDN );

            mpfr_clear(a);
            mpfr_clear(v);
            mpfr_clear(w);
            mpfr_clear(x);
            mpfr_clear(y);
            mpfr_clear(z);
        }
    }

    {
        int z;
        mpfr_init_set_ui(additional, 0, GMP_RNDN);
        for (z = 0; z < NTH_NEW_MOON_ADDITIONAL_ARGS_SIZE; z++) {
            mpfr_t i, j, l;
            mpfr_init_set_d(i, NTH_NEW_MOON_ADDITIONAL_ARGS[z][0], GMP_RNDN);
            mpfr_init_set_d(j, NTH_NEW_MOON_ADDITIONAL_ARGS[z][1], GMP_RNDN);
            mpfr_init_set_d(l, NTH_NEW_MOON_ADDITIONAL_ARGS[z][2], GMP_RNDN);

            mpfr_mul(j, j, k, GMP_RNDN);
            mpfr_add(j, j, i, GMP_RNDN);
            dt_astro_sin(&j, &j);
            mpfr_mul(l, l, j, GMP_RNDN);

            mpfr_add(additional, additional, l, GMP_RNDN);

            mpfr_clear(i);
            mpfr_clear(j);
            mpfr_clear(l);
        }
    }

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "correction = %.10RNf\nextra = %.10RNf\nadditional = %.10RNf\n", correction, extra, additional );
#endif
#endif
    mpfr_set(*result, approx, GMP_RNDN);
    mpfr_add(*result, *result, correction, GMP_RNDN);
    mpfr_add(*result, *result, extra, GMP_RNDN);
    mpfr_add(*result, *result, additional, GMP_RNDN);

    adjust_lunar_phase_to_zero( result );

    mpfr_clear(n);
    mpfr_clear(k);
    mpfr_clear(C);
    mpfr_clear(approx);
    mpfr_clear(E);
    mpfr_clear(solar_anomaly);
    mpfr_clear(lunar_anomaly);
    mpfr_clear(moon_argument);
    mpfr_clear(omega);
    mpfr_clear(extra);
    mpfr_clear(correction);
    mpfr_clear(additional);


    if (dt_astro_global_cache.cache_size == 0) {
        dt_astro_global_cache.cache_size = 200000;
        Newxz( dt_astro_global_cache.cache, dt_astro_global_cache.cache_size, mpfr_t * );
    }

    if (dt_astro_global_cache.cache_size < n_int + 1) {
        int new_size = dt_astro_global_cache.cache_size * 2;
        Renew( dt_astro_global_cache.cache, new_size, mpfr_t *);
        dt_astro_global_cache.cache_size = new_size;
    }

    {
        mpfr_t *new_data;
        Newxz( new_data, 1, mpfr_t );
        mpfr_init( *new_data );
        mpfr_set( *new_data, *result, GMP_RNDN );
        dt_astro_global_cache.cache[n_int] = new_data;
#if (0)
        PerlIO_printf(PerlIO_stderr(), "CACHE set for %d\n", n_int);
#endif
    }

    return 1;
}

/* TODO: Check out errata 269 on 
    http://emr.cs.uiuc.edu/home/reingold/calendar-book/second-edition/errata.pdf
*/
STATIC_INLINE
int
new_moon_before_from_moment(mpfr_t *result, mpfr_t *o_moment) {
    mpfr_t t0, phi, big_n, radian, delta;
    mpfr_t fullangle;
    long n;

    mpfr_init(t0);
    nth_new_moon(&t0, 0);

    mpfr_init(phi);
    lunar_phase( &phi, o_moment );

    mpfr_init_set(delta, *o_moment, GMP_RNDN);
    mpfr_sub(delta, delta, t0, GMP_RNDN);
    mpfr_div_d(delta, delta, MEAN_SYNODIC_MONTH, GMP_RNDN);

    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );
    mpfr_init_set(radian, phi, GMP_RNDN);
    mpfr_div(radian, radian, fullangle, GMP_RNDN );

    mpfr_init_set(big_n, delta, GMP_RNDN);
    mpfr_sub(big_n, big_n, radian, GMP_RNDN);
    mpfr_round(big_n, big_n);

    n = mpfr_get_si(big_n, GMP_RNDN);

    mpfr_clear(t0);
    mpfr_clear(phi);
    mpfr_clear(big_n);
    mpfr_clear(radian);
    mpfr_clear(delta);
    mpfr_clear(fullangle);

    {
        int increment = 1;
        mpfr_t last_good, tmp;
        mpfr_init(tmp);
        mpfr_init(last_good);

        n = n - 1;
        nth_new_moon( &last_good, n );
        while (increment) {
            nth_new_moon( &tmp, n );
            if (mpfr_cmp( tmp, *o_moment ) < 0) {
                n = n + 1;
                mpfr_set( last_good, tmp, GMP_RNDN );
            } else {
                increment = 0;
                mpfr_set( *result, last_good, GMP_RNDN );
            }
        }
                
        mpfr_clear(tmp);
        mpfr_clear(last_good);
    }

    return 1;
}

STATIC_INLINE
int
new_moon_after_from_moment(mpfr_t *result, mpfr_t *o_moment) {
    mpfr_t t0, phi, big_n, radian, delta;
    mpfr_t fullangle;
    long n;

    mpfr_init(t0);
    nth_new_moon(&t0, 0);

    mpfr_init(phi);

    lunar_phase( &phi, o_moment );

    mpfr_init_set(delta, *o_moment, GMP_RNDN);
    mpfr_sub(delta, delta, t0, GMP_RNDN);
    mpfr_div_d(delta, delta, MEAN_SYNODIC_MONTH, GMP_RNDN);

    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );
    mpfr_init_set(radian, phi, GMP_RNDN);
    mpfr_div(radian, radian, fullangle, GMP_RNDN );

    mpfr_init_set(big_n, delta, GMP_RNDN);
    mpfr_sub(big_n, big_n, radian, GMP_RNDN);
    mpfr_round(big_n, big_n);

    n = mpfr_get_si(big_n, GMP_RNDN);

    mpfr_clear(t0);
    mpfr_clear(phi);
    mpfr_clear(big_n);
    mpfr_clear(radian);
    mpfr_clear(delta);
    mpfr_clear(fullangle);

    nth_new_moon( result, n );
#if (0)
mpfr_fprintf(stderr,
    "got result = %.10RNf against %.10RNf\n",
        result,
        o_moment);
#endif

    {
        /* if the result and moment are too close to each other, we
           wrongly match the same time. 
           fractional parts below 0.0001 doesn't make any change to
           the calculation, so we make that exception, and make sure
           to think of those two as the same
        */
        int loop_count = 0;
        int cmp_result = -1;
        mpfr_t delta;
        mpfr_init(delta);

        while (cmp_result <= 0) {
            loop_count++;
            cmp_result = mpfr_cmp( *result, *o_moment );
            if (cmp_result > 0) {
                mpfr_dim(delta, *result, *o_moment, GMP_RNDN);
                if (mpfr_cmp_d(delta, 0.001) <= 0) {
                    cmp_result = 0;
                }
            }

            if (cmp_result <= 0) {
                n = n + 1;
                nth_new_moon( result, n );
            }
        }
        mpfr_clear(delta);
    }

    return 1;
}

#endif /** __DT_ASTRO_LUNAR_C__ **/

