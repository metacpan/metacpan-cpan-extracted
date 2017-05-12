/*
 * Copyright (c) 2011 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 */

#include <cairo-perl.h>

MODULE = Cairo::Region	PACKAGE = Cairo::Region PREFIX = cairo_region_

void DESTROY (cairo_region_t * region);
    CODE:
	cairo_region_destroy (region);

# cairo_region_t * cairo_region_create (void);
# cairo_region_t * cairo_region_create_rectangle (const cairo_rectangle_int_t *rect);
# cairo_region_t * cairo_region_create_rectangles (const cairo_rectangle_int_t *rects, int count);
cairo_region_t_noinc *
cairo_region_create (class, ...)
    CODE:
	if (items == 1) {
		RETVAL = cairo_region_create ();
	} else if (items == 2) {
		RETVAL = cairo_region_create_rectangle (SvCairoRectangleInt (ST (1)));
	} else {
		cairo_rectangle_int_t *rects;
		int i, count;
		count = items - 1;
		Newz (0, rects, count, cairo_rectangle_int_t);
		for (i = 1; i < items; i++) {
			rects[i-1] = *SvCairoRectangleInt (ST (i));
		}
		RETVAL = cairo_region_create_rectangles (rects, count);
		Safefree (rects);
	}
    OUTPUT:
	RETVAL

cairo_status_t cairo_region_status (const cairo_region_t *region);

# void cairo_region_get_extents (const cairo_region_t *region, cairo_rectangle_int_t *extents);
cairo_rectangle_int_t *
cairo_region_get_extents (const cairo_region_t *region)
    PREINIT:
	cairo_rectangle_int_t rect;
    CODE:
	cairo_region_get_extents (region, &rect);
	RETVAL = &rect;
    OUTPUT:
	RETVAL

int cairo_region_num_rectangles (const cairo_region_t *region);

# void cairo_region_get_rectangle (const cairo_region_t *region, int nth, cairo_rectangle_int_t *rectangle);
cairo_rectangle_int_t *
cairo_region_get_rectangle (const cairo_region_t *region, int nth)
    PREINIT:
	cairo_rectangle_int_t rect;
    CODE:
	cairo_region_get_rectangle (region, nth, &rect);
	RETVAL = &rect;
    OUTPUT:
	RETVAL

cairo_bool_t cairo_region_is_empty (const cairo_region_t *region);

cairo_bool_t cairo_region_contains_point (const cairo_region_t *region, int x, int y);

cairo_region_overlap_t cairo_region_contains_rectangle (const cairo_region_t *region, const cairo_rectangle_int_t *rectangle);

cairo_bool_t cairo_region_equal (const cairo_region_t *a, const cairo_region_t *b);

void cairo_region_translate (cairo_region_t *region, int dx, int dy);

cairo_status_t cairo_region_intersect (cairo_region_t *dst, const cairo_region_t *other);

cairo_status_t cairo_region_intersect_rectangle (cairo_region_t *dst, const cairo_rectangle_int_t *rectangle);

cairo_status_t cairo_region_subtract (cairo_region_t *dst, const cairo_region_t *other);

cairo_status_t cairo_region_subtract_rectangle (cairo_region_t *dst, const cairo_rectangle_int_t *rectangle);

cairo_status_t cairo_region_union (cairo_region_t *dst, const cairo_region_t *other);

cairo_status_t cairo_region_union_rectangle (cairo_region_t *dst, const cairo_rectangle_int_t *rectangle);

cairo_status_t cairo_region_xor (cairo_region_t *dst, const cairo_region_t *other);

cairo_status_t cairo_region_xor_rectangle (cairo_region_t *dst, const cairo_rectangle_int_t *rectangle);
