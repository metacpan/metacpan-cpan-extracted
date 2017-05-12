/*
 * Copyright (c) 2004-2005 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>

cairo_matrix_t *
cairo_perl_copy_matrix (cairo_matrix_t *src)
{
	cairo_matrix_t *dst;
	New (0, dst, 1, cairo_matrix_t);

	dst->xx = src->xx;
	dst->xy = src->xy;
	dst->x0 = src->x0;
	dst->yx = src->yx;
	dst->yy = src->yy;
	dst->y0 = src->y0;

	return dst;
}

MODULE = Cairo::Matrix	PACKAGE = Cairo::Matrix PREFIX = cairo_matrix_

##void cairo_matrix_init (cairo_matrix_t *matrix, double xx, double yx, double xy, double yy, double x0, double y0);
cairo_matrix_t * cairo_matrix_init (class, double xx, double yx, double xy, double yy, double x0, double y0)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_init (&matrix, xx, yx, xy, yy, x0, y0);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

##void cairo_matrix_init_identity (cairo_matrix_t *matrix);
cairo_matrix_t * cairo_matrix_init_identity (class)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_init_identity (&matrix);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

##void cairo_matrix_init_translate (cairo_matrix_t *matrix, double tx, double ty);
cairo_matrix_t * cairo_matrix_init_translate (class, double tx, double ty)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_init_translate (&matrix, tx, ty);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

##void cairo_matrix_init_scale (cairo_matrix_t *matrix, double sx, double sy);
cairo_matrix_t * cairo_matrix_init_scale (class, double sx, double sy)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_init_scale (&matrix, sx, sy);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

##void cairo_matrix_init_rotate (cairo_matrix_t *matrix, double radians);
cairo_matrix_t * cairo_matrix_init_rotate (class, double radians)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_init_rotate (&matrix, radians);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

void cairo_matrix_translate (cairo_matrix_t * matrix, double tx, double ty);

void cairo_matrix_scale (cairo_matrix_t * matrix, double sx, double sy);

void cairo_matrix_rotate (cairo_matrix_t * matrix, double radians);

cairo_status_t cairo_matrix_invert (cairo_matrix_t * matrix);

##void cairo_matrix_multiply (cairo_matrix_t * result, const cairo_matrix_t * a, const cairo_matrix_t * b);
cairo_matrix_t * cairo_matrix_multiply (cairo_matrix_t * a, cairo_matrix_t * b)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_matrix_multiply (&matrix, a, b);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

##void cairo_matrix_transform_distance (cairo_matrix_t * matrix, double * dx, double * dy);
void cairo_matrix_transform_distance (cairo_matrix_t * matrix, IN_OUTLIST double dx, IN_OUTLIST double dy);

##void cairo_matrix_transform_point (cairo_matrix_t * matrix, double * x, double * y);
void cairo_matrix_transform_point (cairo_matrix_t * matrix, IN_OUTLIST double x, IN_OUTLIST double y);

void DESTROY (cairo_matrix_t * matrix)
    CODE:
	Safefree (matrix);
