/*
 * Copyright (c) 2004-2005 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

#include "ppport.h"

static const char *
get_package (cairo_pattern_t *pattern)
{
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_pattern_type_t type;
	const char *package;

	type = cairo_pattern_get_type (pattern);
	switch (type) {
	    case CAIRO_PATTERN_TYPE_SOLID:
		package = "Cairo::SolidPattern";
		break;

	    case CAIRO_PATTERN_TYPE_SURFACE:
		package = "Cairo::SurfacePattern";
		break;

	    case CAIRO_PATTERN_TYPE_LINEAR:
		package = "Cairo::LinearGradient";
		break;

	    case CAIRO_PATTERN_TYPE_RADIAL:
		package = "Cairo::RadialGradient";
		break;

	    default:
		warn ("unknown pattern type %d encountered", type);
		package = "Cairo::Pattern";
		break;
	}

	return package;
#else
	const char *package = cairo_perl_package_table_lookup (pattern);
	return package ? package : "Cairo::Pattern";
#endif
}

SV *
cairo_pattern_to_sv (cairo_pattern_t *pattern)
{
	SV *sv = newSV (0);
	sv_setref_pv(sv, get_package (pattern), pattern);
	return sv;
}

/* ------------------------------------------------------------------------- */

MODULE = Cairo::Pattern	PACKAGE = Cairo::Pattern PREFIX = cairo_pattern_

void DESTROY (cairo_pattern_t * pattern);
    CODE:
	cairo_pattern_destroy (pattern);

void cairo_pattern_set_matrix (cairo_pattern_t * pattern, cairo_matrix_t * matrix);

## void cairo_pattern_get_matrix (cairo_pattern_t * pattern, cairo_matrix_t * matrix);
cairo_matrix_t * cairo_pattern_get_matrix (cairo_pattern_t * pattern);
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_pattern_get_matrix (pattern, &matrix);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

cairo_status_t cairo_pattern_status (cairo_pattern_t *pattern);

void cairo_pattern_set_extend (cairo_pattern_t * pattern, cairo_extend_t extend);

void cairo_pattern_set_filter (cairo_pattern_t * pattern, cairo_filter_t filter);

cairo_filter_t cairo_pattern_get_filter (cairo_pattern_t * pattern);

cairo_extend_t cairo_pattern_get_extend (cairo_pattern_t * pattern);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_pattern_type_t cairo_pattern_get_type (cairo_pattern_t *pattern);

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Pattern	PACKAGE = Cairo::SolidPattern	PREFIX = cairo_pattern_

BOOT:
	cairo_perl_set_isa ("Cairo::SolidPattern", "Cairo::Pattern");

# cairo_pattern_t* cairo_pattern_create_rgb (double red, double green, double blue);
cairo_pattern_t_noinc * cairo_pattern_create_rgb (class, double red, double green, double blue)
    C_ARGS:
	red, green, blue
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::SolidPattern");
#endif

# cairo_pattern_t* cairo_pattern_create_rgba (double red, double green, double blue, double alpha);
cairo_pattern_t_noinc * cairo_pattern_create_rgba (class, double red, double green, double blue, double alpha)
    C_ARGS:
	red, green, blue, alpha
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::SolidPattern");
#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## cairo_status_t cairo_pattern_get_rgba (cairo_pattern_t *pattern, double *red, double *green, double *blue, double *alpha);
void cairo_pattern_get_rgba (cairo_pattern_t *pattern)
    PREINIT:
	cairo_status_t status;
	double red, green, blue, alpha;
    PPCODE:
	status = cairo_pattern_get_rgba (pattern, &red, &green, &blue, &alpha);
	CAIRO_PERL_CHECK_STATUS (status);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVnv (red)));
	PUSHs (sv_2mortal (newSVnv (green)));
	PUSHs (sv_2mortal (newSVnv (blue)));
	PUSHs (sv_2mortal (newSVnv (alpha)));

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Pattern	PACKAGE = Cairo::SurfacePattern	PREFIX = cairo_pattern_

BOOT:
	cairo_perl_set_isa ("Cairo::SurfacePattern", "Cairo::Pattern");

cairo_pattern_t_noinc * create (class, cairo_surface_t * surface);
    CODE:
	RETVAL = cairo_pattern_create_for_surface (surface);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::SurfacePattern");
#endif
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## cairo_status_t cairo_pattern_get_surface (cairo_pattern_t *pattern, cairo_surface_t **surface);
cairo_surface_t * cairo_pattern_get_surface (cairo_pattern_t *pattern)
    PREINIT:
	cairo_status_t status;
    CODE:
	status = cairo_pattern_get_surface (pattern, &RETVAL);
	CAIRO_PERL_CHECK_STATUS (status);
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Pattern	PACKAGE = Cairo::Gradient	PREFIX = cairo_pattern_

BOOT:
	cairo_perl_set_isa ("Cairo::Gradient", "Cairo::Pattern");

void cairo_pattern_add_color_stop_rgb (cairo_pattern_t *pattern, double offset, double red, double green, double blue);

void cairo_pattern_add_color_stop_rgba (cairo_pattern_t *pattern, double offset, double red, double green, double blue, double alpha);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## cairo_status_t cairo_pattern_get_color_stop_count (cairo_pattern_t *pattern, int *count);
## cairo_status_t cairo_pattern_get_color_stop_rgba (cairo_pattern_t *pattern, int index, double *offset, double *red, double *green, double *blue, double *alpha);
void cairo_pattern_get_color_stops (cairo_pattern_t *pattern)
    PREINIT:
	cairo_status_t status;
	int count, i;
	double offset, red, green, blue, alpha;
    PPCODE:
	status = cairo_pattern_get_color_stop_count (pattern, &count);
	CAIRO_PERL_CHECK_STATUS (status);
	EXTEND (sp, count);
	for (i = 0; i < count; i++) {
		AV *av;
		status = cairo_pattern_get_color_stop_rgba (pattern, i, &offset, &red, &green, &blue, &alpha);
		CAIRO_PERL_CHECK_STATUS (status);
		av = newAV ();
		av_push (av, newSVnv (offset));
		av_push (av, newSVnv (red));
		av_push (av, newSVnv (green));
		av_push (av, newSVnv (blue));
		av_push (av, newSVnv (alpha));
		PUSHs (sv_2mortal (newRV_noinc ((SV *) av)));
	}

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Pattern	PACKAGE = Cairo::LinearGradient	PREFIX = cairo_pattern_

BOOT:
	cairo_perl_set_isa ("Cairo::LinearGradient", "Cairo::Gradient");

cairo_pattern_t_noinc * create (class, double x0, double y0, double x1, double y1);
    CODE:
	RETVAL = cairo_pattern_create_linear (x0, y0, x1, y1);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::LinearGradient");
#endif
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## cairo_status_t cairo_pattern_get_linear_points (cairo_pattern_t *pattern, double *x0, double *y0, double *x1, double *y1);
void cairo_pattern_get_points (cairo_pattern_t *pattern)
    PREINIT:
	cairo_status_t status;
	double x0, y0, x1, y1;
    PPCODE:
	status = cairo_pattern_get_linear_points (pattern, &x0, &y0, &x1, &y1);
	CAIRO_PERL_CHECK_STATUS (status);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVnv (x0)));
	PUSHs (sv_2mortal (newSVnv (y0)));
	PUSHs (sv_2mortal (newSVnv (x1)));
	PUSHs (sv_2mortal (newSVnv (y1)));

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Pattern	PACKAGE = Cairo::RadialGradient	PREFIX = cairo_pattern_

BOOT:
	cairo_perl_set_isa ("Cairo::RadialGradient", "Cairo::Gradient");

cairo_pattern_t_noinc * create (class, double cx0, double cy0, double radius0, double cx1, double cy1, double radius1);
    CODE:
	RETVAL = cairo_pattern_create_radial (cx0, cy0, radius0, cx1, cy1, radius1);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::RadialGradient");
#endif
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## cairo_status_t cairo_pattern_get_radial_circles (cairo_pattern_t *pattern, double *x0, double *y0, double *r0, double *x1, double *y1, double *r1)
void cairo_pattern_get_circles (cairo_pattern_t *pattern)
    PREINIT:
	cairo_status_t status;
	double x0, y0, r0, x1, y1, r1;
    PPCODE:
	status = cairo_pattern_get_radial_circles (pattern, &x0, &y0, &r0, &x1, &y1, &r1);
	CAIRO_PERL_CHECK_STATUS (status);
	EXTEND (sp, 6);
	PUSHs (sv_2mortal (newSVnv (x0)));
	PUSHs (sv_2mortal (newSVnv (y0)));
	PUSHs (sv_2mortal (newSVnv (r0)));
	PUSHs (sv_2mortal (newSVnv (x1)));
	PUSHs (sv_2mortal (newSVnv (y1)));
	PUSHs (sv_2mortal (newSVnv (r1)));

#endif
