#ifndef __DT_ASTRO_SOLAR_TERM_C__
#define __DT_ASTRO_SOLAR_TERM_C__
#include "dt_astro.h"

STATIC_INLINE
int
next_term_at( mpfr_t *result, mpfr_t *moment, mpfr_t *phi ) {
    return solar_longitude_after( result, moment, phi );
}

STATIC_INLINE
int
prev_term_at( mpfr_t *result, mpfr_t *moment, mpfr_t *phi ) {
    return estimate_prior_solar_longitude( result, moment, phi );
}

STATIC_INLINE
int
major_term_after( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t x, lon, l, midnight, fullangle;

    mpfr_init_set( midnight, *moment, GMP_RNDN );
    mpfr_floor( midnight, midnight );
    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );

    mpfr_init(lon);
    solar_longitude( &lon, &midnight );
    mpfr_init_set(x, lon, GMP_RNDN);
    mpfr_div_ui(x, x, 30, GMP_RNDN);
    mpfr_clear(lon);

    mpfr_ceil( x, x );
    mpfr_mul_ui( x, x, 30, GMP_RNDN );
    mpfr_init(l);
    dt_astro_mod( &l, &x, &fullangle );
    mpfr_clear(x);

    next_term_at( result, moment, &l);

    mpfr_clear(l);
    mpfr_clear( fullangle );
    mpfr_clear( midnight );
    return 1;
}

STATIC_INLINE
int
major_term_before( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t x, lon, l, midnight, fullangle;

    mpfr_init_set( midnight, *moment, GMP_RNDN );
    mpfr_floor( midnight, midnight );
    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );

    mpfr_init(lon);
    solar_longitude( &lon, &midnight );
    mpfr_init_set(x, lon, GMP_RNDN);
    mpfr_div_ui(x, x, 30, GMP_RNDN);
    mpfr_clear(lon);

    mpfr_floor( x, x );
    mpfr_mul_ui( x, x, 30, GMP_RNDN );
    mpfr_init(l);
    dt_astro_mod( &l, &x, &fullangle );
    mpfr_clear(x);

    prev_term_at( result, moment, &l);

    mpfr_clear(l);
    mpfr_clear( fullangle );
    mpfr_clear( midnight );
    return 1;
}

STATIC_INLINE
int
minor_term_after( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t l, fullangle, lon, midnight;

    mpfr_init_set( midnight, *moment, GMP_RNDN );
    mpfr_floor( midnight, midnight );
    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );

    mpfr_init(lon);
    solar_longitude( &lon, &midnight );
    mpfr_sub_ui( lon, lon, 15, GMP_RNDN );
    mpfr_div_ui( lon, lon, 30, GMP_RNDN );
    mpfr_ceil( lon, lon );
    mpfr_mul_ui( lon, lon, 30, GMP_RNDN );
    mpfr_add_ui( lon, lon, 15, GMP_RNDN );
    mpfr_init(l);
    dt_astro_mod( &l, &lon, &fullangle );
    mpfr_clear(lon);

    next_term_at( result, moment, &l );

    mpfr_clear(l);
    mpfr_clear( fullangle );
    mpfr_clear( midnight );
    return 1;
}

STATIC_INLINE
int
minor_term_before( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t l, fullangle, lon, midnight;
    mpfr_init_set( midnight, *moment, GMP_RNDN );
    mpfr_floor( midnight, midnight );
    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );

    mpfr_init(lon);
    solar_longitude( &lon, &midnight );
    mpfr_sub_ui( lon, lon, 15, GMP_RNDN );
    mpfr_div_ui( lon, lon, 30, GMP_RNDN );
    mpfr_floor( lon, lon );
    mpfr_mul_ui( lon, lon, 30, GMP_RNDN );
    mpfr_add_ui( lon, lon, 15, GMP_RNDN );
    mpfr_init(l);
    dt_astro_mod( &l, &lon, &fullangle );
    mpfr_clear( lon );

    prev_term_at( result, moment, &l );

    mpfr_clear( l );
    mpfr_clear( fullangle );
    mpfr_clear( midnight );
    return 1;
}


#endif /** __DT_ASTRO_SOLAR_TERM_C__ **/