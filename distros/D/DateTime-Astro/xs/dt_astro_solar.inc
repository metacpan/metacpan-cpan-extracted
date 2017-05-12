#ifndef __DT_ASTRO_SOLAR_C__
#define __DT_ASTRO_SOLAR_C__
#include "dt_astro.h"

/* [1] Table 12.1 p.183 (zero-padded to align veritcally) */
#define SOLAR_LONGITUDE_ARGS_SIZE 49
static const double SOLAR_LONGITUDE_ARGS[59][3] = {
    /*      X          Y             Z        */
    /* left side of table 12.1                */
    { 403406, 270.54861,      0.9287892 },
    { 119433,  63.91854,  35999.4089666 },
    {   3891, 317.84300,  71998.2026100 },
    {   1721, 240.05200,  36000.3572600 },
    {    350, 247.23000,  32964.4678000 },
    {    314, 297.82000, 445267.1117000 },
    {    242, 166.79000,      3.1008000 },
    {    158,   3.50000,    -19.9739000 },
    {    129, 182.95000,   9038.0293000 },
    {     99,  29.80000,  33718.1480000 },
    {     86, 249.20000,  -2280.7730000 },
    {     72, 257.80000,  31556.4930000 },
    {     64,  69.90000,   9037.7500000 },
    {     38, 197.10000,  -4444.1760000 },
    {     32,  65.30000,  67555.3160000 },
    {     28, 341.50000,  -4561.5400000 },
    {     27,  98.50000,   1221.6550000 },
    {     24, 110.00000,  31437.3690000 },
    {     21, 342.60000, -31931.7570000 },
    {     18, 256.10000,   1221.9990000 },
    {     14, 242.90000,  -4442.0390000 },
    {     13, 151.80000,    119.0660000 },
    {     12,  53.30000,     -4.5780000 },
    {     10, 205.70000,    -39.1270000 },
    {     10, 146.10000,  90073.7780000 },
    /* right side of table 12.1               */
    { 195207, 340.19128,  35999.1376958 },
    { 112392, 331.26220,  35998.7287385 },
    {   2819,  86.63100,  71998.4403000 },
    {    660, 310.26000,  71997.4812000 },
    {    334, 260.87000,    -19.4410000 },
    {    268, 343.14000,  45036.8840000 },
    {    234,  81.53000,  22518.4434000 },
    {    132, 132.75000,  65928.9345000 },
    {    114, 162.03000,   3034.7684000 },
    {     93, 266.40000,   3034.4480000 },
    {     78, 157.60000,  29929.9920000 },
    {     68, 185.10000,    149.5880000 },
    {     46,   8.00000, 107997.4050000 },
    {     37, 250.40000,    151.7710000 },
    {     29, 162.70000,  31556.0800000 },
    {     27, 291.60000, 107996.7060000 },
    {     25, 146.70000,  62894.1670000 },
    {     21,   5.20000,  14578.2980000 },
    {     20, 230.90000,  34777.2430000 },
    {     17,  45.30000,  62894.5110000 },
    {     13, 115.20000, 107997.9090000 },
    {     13, 285.30000,  16859.0710000 },
    {     10, 126.60000,  26895.2920000 },
    {     10,  85.90000,  12297.5360000 }
};

STATIC_INLINE
int
solar_longitude( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t C, fugly, A, N, longitude, fullangle;

    mpfr_init(C);
    julian_centuries(&C, moment);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "julian_centuries = %.10RNf\n", C);
#endif
#endif
    {
        int i;
        mpfr_init_set_ui(fugly, 0, GMP_RNDN);
        for( i = 0; i < SOLAR_LONGITUDE_ARGS_SIZE; i++ ) {
            mpfr_t a, b, c;
            mpfr_init_set_d( a, SOLAR_LONGITUDE_ARGS[i][0], GMP_RNDN );
            mpfr_init_set_d( b, SOLAR_LONGITUDE_ARGS[i][1], GMP_RNDN );
            mpfr_init_set_d( c, SOLAR_LONGITUDE_ARGS[i][2], GMP_RNDN );
            mpfr_mul(c, c, C, GMP_RNDN);
            mpfr_add(b, b, c, GMP_RNDN);
            dt_astro_sin(&b, &b);
            mpfr_mul(a, a, b, GMP_RNDN);
            mpfr_add(fugly, fugly, a, GMP_RNDN);
            mpfr_clear(a);
            mpfr_clear(b);
            mpfr_clear(c);
        }
    }

    {
        mpfr_t b, c;
        mpfr_init_set_d(longitude, 282.7771834, GMP_RNDN);
        mpfr_init_set_d(b, 36000.76953744, GMP_RNDN);
        mpfr_mul(b, b, C, GMP_RNDN);
        mpfr_init_set_d(c, 0.000005729577951308232, GMP_RNDN);
        mpfr_mul(c, c, fugly, GMP_RNDN);
        mpfr_add(longitude, longitude, b, GMP_RNDN);
        mpfr_add(longitude, longitude, c, GMP_RNDN);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    mpfr_init(A);
    aberration(&A, moment);

    mpfr_init(N);
    nutation(&N, moment);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "longitude = %.10RNf\naberration = %.10RNf\nnutation = %.10RNf\n",
    longitude,
    A,
    N);
#endif
#endif

    mpfr_set( *result, longitude, GMP_RNDN);
    mpfr_add( *result, *result, A, GMP_RNDN );
    mpfr_add( *result, *result, N, GMP_RNDN );

    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "(solar) mod(%.10RNf) = ", *result );
#endif
#endif
    dt_astro_mod( result, result, &fullangle );
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "%.10RNf\n", *result );
#endif
#endif

    mpfr_clear(A);
    mpfr_clear(N);
    mpfr_clear(C);
    mpfr_clear(longitude);
    mpfr_clear(fullangle);
    mpfr_clear(fugly);

    return 1;
}

STATIC_INLINE
int
estimate_prior_solar_longitude(mpfr_t *result, mpfr_t *moment, mpfr_t *phi) {
    mpfr_t tau, delta;

    mpfr_init_set(tau, *moment, GMP_RNDN);
    mpfr_init(delta);

    {
        mpfr_t tmp;
        mpfr_t fullangle;
        mpfr_init(tmp);
        mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

        solar_longitude( &tmp, moment );
        mpfr_sub( tmp, tmp, *phi, GMP_RNDN );
        dt_astro_mod( &tmp, &tmp, &fullangle );
        mpfr_mul_d( tmp, tmp, SOLAR_YEAR_RATE, GMP_RNDN );

        mpfr_sub( tau, tau, tmp, GMP_RNDN );

        {
            mpfr_t tau_lon;

            mpfr_init(tau_lon);
            /* tau_lon = solar_longitude(tau_lon_arg) */
            solar_longitude( &tau_lon, &tau );

            mpfr_sub( tau_lon, tau_lon, *phi, GMP_RNDN );
            mpfr_add_ui( tau_lon, tau_lon, 180, GMP_RNDN );

            dt_astro_mod( &delta, &tau_lon, &fullangle );

            mpfr_clear(tau_lon);
        }

        mpfr_sub_ui( delta, delta, 180, GMP_RNDN );

        mpfr_clear(tmp);
        mpfr_clear(fullangle);
    }

    mpfr_mul_d( delta, delta, SOLAR_YEAR_RATE, GMP_RNDN );
    mpfr_sub( tau, tau, delta, GMP_RNDN );
    if (mpfr_cmp( *moment, tau ) > 0) {
        mpfr_set( *result, tau, GMP_RNDN );
    } else {
        mpfr_set( *result, *moment, GMP_RNDN);
    }
        
    mpfr_clear(tau);
    mpfr_clear(delta);

    return 1;
}

#define SOLAR_LONGITUDE_ALLOWED_DELTA 0.00000000000000000000000000000001

STATIC_INLINE
int
__solar_longitude_mu(mpfr_t *lo, mpfr_t *hi) {
    int result = 0;
    mpfr_t delta;
    mpfr_init_set(delta, *lo, GMP_RNDN);
    mpfr_sub(delta, delta, *hi, GMP_RNDN);
    mpfr_abs(delta, delta, GMP_RNDN);

    if (mpfr_cmp_d(delta, SOLAR_LONGITUDE_ALLOWED_DELTA) < 0) {
        result = 1;
    }
    mpfr_clear(delta);
    return result;
}

STATIC_INLINE
int
__solar_longitude_phi(mpfr_t *x, void *args, int n_args) {
    int result = 0;
    mpfr_t phi, lon, fullangle;

    PERL_UNUSED_VAR(n_args);
    
    mpfr_init_set_ui(fullangle, 360, GMP_RNDN);
    
    mpfr_init( lon );
    mpfr_init_set( phi, ((mpfr_t *) args)[0], GMP_RNDN );
    
    solar_longitude( &lon, x );

    mpfr_sub( lon, lon, phi, GMP_RNDN );
    dt_astro_mod( &lon, &lon, &fullangle );

    if ( mpfr_cmp_ui( lon, 180 ) < 0 ) {
        result = 1;
    }

    mpfr_clear(lon);
    mpfr_clear(phi);
    mpfr_clear(fullangle);
    return result;
}

STATIC_INLINE
int
solar_longitude_before( mpfr_t *result, mpfr_t *moment, mpfr_t *phi ) {
    mpfr_t tau, l, u;
    mpfr_init(tau);

    estimate_prior_solar_longitude( &tau, moment, phi );
    mpfr_init_set(l, tau, GMP_RNDN);
    mpfr_sub_ui(l, l, 5, GMP_RNDN);
    mpfr_init_set(u, tau, GMP_RNDN);
    mpfr_add_ui(u, u, 5, GMP_RNDN);
    
    if (mpfr_cmp( *moment, u ) < 0) {
        mpfr_set( u, *moment, GMP_RNDN );
    }

    __binary_search( result, &l, &u, __solar_longitude_phi, (void *) phi, 1, __solar_longitude_mu );

    mpfr_clear(tau);
    mpfr_clear(l);
    mpfr_clear(u);

    return 1;
}

STATIC_INLINE
int
solar_longitude_after( mpfr_t *result, mpfr_t *moment, mpfr_t *phi ) {
    mpfr_t tau, n, l, u;

    mpfr_init_set_d( n, SOLAR_YEAR_RATE, GMP_RNDN );

    {
        mpfr_t lon, x, fullangle;

        mpfr_init_set_ui(fullangle, 360, GMP_RNDN);
        mpfr_init(lon);
        solar_longitude( &lon, moment );
        mpfr_init_set( x, *phi, GMP_RNDN );
        mpfr_sub(x, x, lon, GMP_RNDN );
        dt_astro_mod( &x, &x, &fullangle );
        mpfr_mul( n, n, x, GMP_RNDN );

        mpfr_clear(lon);
        mpfr_clear(x);
        mpfr_clear(fullangle);
    }

    mpfr_init_set( tau, *moment, GMP_RNDN );
    mpfr_add( tau, tau, n, GMP_RNDN );

    {
        mpfr_t x;
        mpfr_init_set( x, tau, GMP_RNDN );
        mpfr_sub_ui( x, x, 5, GMP_RNDN );
        if ( mpfr_cmp (*moment, x) > 0 ) {
            mpfr_init_set( l, *moment, GMP_RNDN );
        } else {
            mpfr_init_set( l, x, GMP_RNDN );
        }

        mpfr_clear(x);
    }

    mpfr_init_set(u, tau, GMP_RNDN);
    mpfr_add_ui(u, u, 5, GMP_RNDN);

    __binary_search( result, &l, &u, __solar_longitude_phi, (void *) phi, 1, __solar_longitude_mu );

    mpfr_clear(tau);
    mpfr_clear(n);
    mpfr_clear(l);
    mpfr_clear(u);
    
    return 1;
}

#endif /** __DT_ASTRO_SOLAR_C__ **/

