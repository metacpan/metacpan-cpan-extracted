/*
 * Copyright (c) 2004-2013 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 *
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

/* ------------------------------------------------------------------------- */

static void
call_xs (pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark)
{
	dSP;
	PUSHMARK (mark);
	(*subaddr) (aTHX_ cv);
	PUTBACK;	/* forget return values */
}

#ifndef XS_EXTERNAL
# define XS_EXTERNAL(name) XS(name)
#endif
#define CAIRO_PERL_CALL_BOOT(name)				\
	{							\
		extern XS_EXTERNAL (name);			\
		call_xs (aTHX_ name, cv, mark);	\
	}

/* ------------------------------------------------------------------------- */

/* Copied from Glib/Glib.xs. */
void *
cairo_perl_alloc_temp (int nbytes)
{
	dTHR;
	SV * s;

	if (nbytes <= 0) return NULL;

	s = sv_2mortal (NEWSV (0, nbytes));
	memset (SvPVX (s), 0, nbytes);
	return SvPVX (s);
}

/* Copied from Glib/GType.xs. */
void
cairo_perl_set_isa (const char *child_package,
                    const char *parent_package)
{
	char *child_isa_full;
	AV *isa;

	New (0, child_isa_full, strlen(child_package) + 5 + 1, char);
	child_isa_full = strcpy (child_isa_full, child_package);
	child_isa_full = strcat (child_isa_full, "::ISA");
	isa = get_av (child_isa_full, TRUE); /* create on demand */
	Safefree (child_isa_full);

	av_push (isa, newSVpv (parent_package, 0));
}

/* Copied from Glib/Glib.xs. */
cairo_bool_t
cairo_perl_sv_is_defined (SV *sv)
{
	/* This is adapted from PP(pp_defined) in perl's pp.c */

	if (!sv || !SvANY(sv))
		return FALSE;

	switch (SvTYPE(sv)) {
	    case SVt_PVAV:
		if (AvMAX(sv) >= 0 || SvGMAGICAL(sv)
		    || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
			return TRUE;
		break;
	    case SVt_PVHV:
		if (HvARRAY(sv) || SvGMAGICAL(sv)
		    || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
			return TRUE;
		break;
	    case SVt_PVCV:
		if (CvROOT(sv) || CvXSUB(sv))
			return TRUE;
		break;
	    default:
		if (SvGMAGICAL(sv))
			mg_get(sv);
		if (SvOK(sv))
			return TRUE;
	}

	return FALSE;
}

/* ------------------------------------------------------------------------- */

void *
cairo_object_from_sv (SV *sv, const char *package)
{
	if (!cairo_perl_sv_is_ref (sv) || !sv_derived_from (sv, package))
		croak("Cannot convert scalar %p to an object of type %s",
		      sv, package);
	return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));
}

SV *
cairo_object_to_sv (void *object, const char *package)
{
	SV *sv = newSV (0);
	sv_setref_pv(sv, package, object);
	return sv;
}

/* ------------------------------------------------------------------------- */

void *
cairo_struct_from_sv (SV *sv, const char *package)
{
	if (!cairo_perl_sv_is_ref (sv) || !sv_derived_from (sv, package))
		croak("Cannot convert scalar %p to a struct of type %s",
		      sv, package);
	return INT2PTR (void *, SvIV ((SV *) SvRV (sv)));
}

SV *
cairo_struct_to_sv (void *object, const char *package)
{
	SV *sv = newSV (0);
	sv_setref_pv(sv, package, object);
	return sv;
}

/* ------------------------------------------------------------------------- */

SV *
newSVCairoFontExtents (cairo_font_extents_t *extents)
{
	HV *hv;
	double value;

	if (!extents)
		return &PL_sv_undef;

	hv = newHV ();

	value = extents->ascent;
	hv_store (hv, "ascent", 6, newSVnv (value), 0);

	value = extents->descent;
	hv_store (hv, "descent", 7, newSVnv (value), 0);

	value = extents->height;
	hv_store (hv, "height", 6, newSVnv (value), 0);

	value = extents->max_x_advance;
	hv_store (hv, "max_x_advance", 13, newSVnv (value), 0);

	value = extents->max_y_advance;
	hv_store (hv, "max_y_advance", 13, newSVnv (value), 0);

	return newRV_noinc ((SV *) hv);
}

/* ------------------------------------------------------------------------- */

SV *
newSVCairoTextExtents (cairo_text_extents_t *extents)
{
	HV *hv;
	double value;

	if (!extents)
		return &PL_sv_undef;

	hv = newHV ();

	value = extents->x_bearing;
	hv_store (hv, "x_bearing", 9, newSVnv (value), 0);

	value = extents->y_bearing;
	hv_store (hv, "y_bearing", 9, newSVnv (value), 0);

	value = extents->width;
	hv_store (hv, "width", 5, newSVnv (value), 0);

	value = extents->height;
	hv_store (hv, "height", 6, newSVnv (value), 0);

	value = extents->x_advance;
	hv_store (hv, "x_advance", 9, newSVnv (value), 0);

	value = extents->y_advance;
	hv_store (hv, "y_advance", 9, newSVnv (value), 0);

	return newRV_noinc ((SV *) hv);
}

/* ------------------------------------------------------------------------- */

SV *
newSVCairoGlyph (cairo_glyph_t *glyph)
{
	HV *hv;
	unsigned long index;
	double value;

	if (!glyph)
		return &PL_sv_undef;

	hv = newHV ();

	index = glyph->index;
	hv_store (hv, "index", 5, newSVuv (index), 0);

	value = glyph->x;
	hv_store (hv, "x", 1, newSVnv (value), 0);

	value = glyph->y;
	hv_store (hv, "y", 1, newSVnv (value), 0);

	return newRV_noinc ((SV *) hv);
}

cairo_glyph_t *
SvCairoGlyph (SV *sv)
{
	HV *hv;
	SV **value;
	cairo_glyph_t *glyph;

	if (!cairo_perl_sv_is_hash_ref (sv))
		croak ("cairo_glyph_t must be a hash reference");

	hv = (HV *) SvRV (sv);
	glyph = cairo_perl_alloc_temp (sizeof (cairo_glyph_t));

	value = hv_fetch (hv, "index", 5, 0);
	if (value && SvOK (*value))
		glyph->index = SvUV (*value);

	value = hv_fetch (hv, "x", 1, 0);
	if (value && SvOK (*value))
		glyph->x = SvNV (*value);

	value = hv_fetch (hv, "y", 1, 0);
	if (value && SvOK (*value))
		glyph->y = SvNV (*value);

	return glyph;
}

/* ------------------------------------------------------------------------- */

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

SV *
newSVCairoRectangle (cairo_rectangle_t *rectangle)
{
	HV *hv;

	if (!rectangle)
		return &PL_sv_undef;

	hv = newHV ();

	hv_store (hv, "x", 1, newSVnv (rectangle->x), 0);
	hv_store (hv, "y", 1, newSVnv (rectangle->y), 0);
	hv_store (hv, "width", 5, newSVnv (rectangle->width), 0);
	hv_store (hv, "height", 6, newSVnv (rectangle->height), 0);

	return newRV_noinc ((SV *) hv);
}

cairo_rectangle_t *
SvCairoRectangle (SV *sv)
{
	HV *hv;
	SV **value;
	cairo_rectangle_t *rectangle;

	if (!cairo_perl_sv_is_hash_ref (sv))
		croak ("cairo_rectangle_t must be a hash reference");

	hv = (HV *) SvRV (sv);
	rectangle = cairo_perl_alloc_temp (sizeof (cairo_rectangle_t));

	value = hv_fetchs (hv, "x", 0);
	if (value && SvOK (*value))
		rectangle->x = SvNV (*value);

	value = hv_fetchs (hv, "y", 0);
	if (value && SvOK (*value))
		rectangle->y = SvNV (*value);

	value = hv_fetchs (hv, "width", 0);
	if (value && SvOK (*value))
		rectangle->width = SvNV (*value);

	value = hv_fetchs (hv, "height", 0);
	if (value && SvOK (*value))
		rectangle->height = SvNV (*value);

	return rectangle;
}

#endif

/* ------------------------------------------------------------------------- */

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)

SV *
newSVCairoRectangleInt (cairo_rectangle_int_t *rectangle)
{
	HV *hv;

	if (!rectangle)
		return &PL_sv_undef;

	hv = newHV ();

	hv_store (hv, "x", 1, newSViv (rectangle->x), 0);
	hv_store (hv, "y", 1, newSViv (rectangle->y), 0);
	hv_store (hv, "width", 5, newSViv (rectangle->width), 0);
	hv_store (hv, "height", 6, newSViv (rectangle->height), 0);

	return newRV_noinc ((SV *) hv);
}

cairo_rectangle_int_t *
SvCairoRectangleInt (SV *sv)
{
	HV *hv;
	SV **value;
	cairo_rectangle_int_t *rectangle;

	if (!cairo_perl_sv_is_hash_ref (sv))
		croak ("cairo_rectangle_int_t must be a hash reference");

	hv = (HV *) SvRV (sv);
	rectangle = cairo_perl_alloc_temp (sizeof (cairo_rectangle_t));

	value = hv_fetchs (hv, "x", 0);
	if (value && SvOK (*value))
		rectangle->x = SvIV (*value);

	value = hv_fetchs (hv, "y", 0);
	if (value && SvOK (*value))
		rectangle->y = SvIV (*value);

	value = hv_fetchs (hv, "width", 0);
	if (value && SvOK (*value))
		rectangle->width = SvIV (*value);

	value = hv_fetchs (hv, "height", 0);
	if (value && SvOK (*value))
		rectangle->height = SvIV (*value);

	return rectangle;
}

#endif

/* ------------------------------------------------------------------------- */

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

SV *
newSVCairoTextCluster (cairo_text_cluster_t *cluster)
{
	HV *hv;

	if (!cluster)
		return &PL_sv_undef;

	hv = newHV ();

	hv_store (hv, "num_bytes", 9, newSViv (cluster->num_bytes), 0);
	hv_store (hv, "num_glyphs", 10, newSVnv (cluster->num_glyphs), 0);

	return newRV_noinc ((SV *) hv);
}

cairo_text_cluster_t *
SvCairoTextCluster (SV *sv)
{
	HV *hv;
	SV **value;
	cairo_text_cluster_t *cluster;

	if (!cairo_perl_sv_is_hash_ref (sv))
		croak ("cairo_text_cluster_t must be a hash reference");

	hv = (HV *) SvRV (sv);
	cluster = cairo_perl_alloc_temp (sizeof (cairo_text_cluster_t));

	value = hv_fetch (hv, "num_bytes", 9, 0);
	if (value && SvOK (*value))
		cluster->num_bytes = SvIV (*value);

	value = hv_fetch (hv, "num_glyphs", 10, 0);
	if (value && SvOK (*value))
		cluster->num_glyphs = SvIV (*value);

	return cluster;
}

#endif

/* ------------------------------------------------------------------------- */

MODULE = Cairo	PACKAGE = Cairo	PREFIX = cairo_

BOOT:
#include "cairo-perl-boot.xsh"
#if CAIRO_PERL_DEBUG
	call_atexit ((ATEXIT_t) cairo_debug_reset_static_data, NULL);
#endif

# The VERSION fallback is implemented in lib/Cairo.pm.
int LIB_VERSION (...)
    CODE:
	PERL_UNUSED_VAR (items);
	RETVAL = CAIRO_VERSION;
    OUTPUT:
	RETVAL

int LIB_VERSION_ENCODE (...)
    ALIAS:
	VERSION_ENCODE = 1
    PREINIT:
	int major, minor, micro;
    CODE:
	PERL_UNUSED_VAR (ix);
	if (items == 3) {
		major = SvIV (ST (0));
		minor = SvIV (ST (1));
		micro = SvIV (ST (2));
	} else if (items == 4) {
		major = SvIV (ST (1));
		minor = SvIV (ST (2));
		micro = SvIV (ST (3));
	} else {
		croak ("Usage: Cairo::LIB_VERSION_ENCODE (major, minor, micro) or Cairo->LIB_VERSION_ENCODE (major, minor, micro)");
	}

	RETVAL = CAIRO_VERSION_ENCODE (major, minor, micro);
    OUTPUT:
	RETVAL

# int cairo_version ();
int cairo_version (class=NULL)
    ALIAS:
	lib_version = 1
    C_ARGS:
	/* void */
    CLEANUP:
	PERL_UNUSED_VAR (ix);

# const char* cairo_version_string ();
const char* cairo_version_string (class=NULL)
    ALIAS:
	lib_version_string = 1
    C_ARGS:
	/* void */
    CLEANUP:
	PERL_UNUSED_VAR (ix);

# ---------------------------------------------------------------------------- #

MODULE = Cairo	PACKAGE = Cairo::Context	PREFIX = cairo_

cairo_t_noinc * cairo_create (class, cairo_surface_t * target);
    C_ARGS:
	target

void DESTROY (cairo_t * cr);
    CODE:
	cairo_destroy (cr);

void cairo_save (cairo_t * cr);

void cairo_restore (cairo_t * cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_push_group (cairo_t *cr);

void cairo_push_group_with_content (cairo_t *cr, cairo_content_t content);

cairo_pattern_t * cairo_pop_group (cairo_t *cr);

void cairo_pop_group_to_source (cairo_t *cr);

#endif

void cairo_set_operator (cairo_t * cr, cairo_operator_t op);

void cairo_set_source_rgb (cairo_t *cr, double red, double green, double blue);

void cairo_set_source_rgba (cairo_t *cr, double red, double green, double blue, double alpha);

void cairo_set_source (cairo_t *cr, cairo_pattern_t *source);

void cairo_set_source_surface (cairo_t *cr, cairo_surface_t *surface, double x, double y);

void cairo_set_tolerance (cairo_t * cr, double tolerance);

void cairo_set_antialias (cairo_t *cr, cairo_antialias_t antialias);

void cairo_set_fill_rule (cairo_t * cr, cairo_fill_rule_t fill_rule);

void cairo_set_line_width (cairo_t * cr, double width);

void cairo_set_line_cap (cairo_t * cr, cairo_line_cap_t line_cap);

void cairo_set_line_join (cairo_t * cr, cairo_line_join_t line_join);

##void cairo_set_dash (cairo_t * cr, double * dashes, int ndash, double offset);
void cairo_set_dash (cairo_t * cr, double offset, ...)
    PREINIT:
	int i, n;
	double *pts;
    CODE:
#define FIRST 2
	n = (items - FIRST);
	if (n == 0) {
		pts = NULL;
	} else {
		New (0, pts, n, double);
		if (!pts)
			croak ("malloc failure for (%d) elements", n);
		for (i = FIRST ; i < items ; i++)
			pts[i - FIRST] = SvNV (ST (i));
	}
#undef FIRST
	cairo_set_dash (cr, pts, n, offset);
    CLEANUP:
	if (pts)
		Safefree (pts);

void cairo_set_miter_limit (cairo_t * cr, double limit);

void cairo_translate (cairo_t * cr, double tx, double ty);

void cairo_scale (cairo_t * cr, double sx, double sy);

void cairo_rotate (cairo_t * cr, double angle);

void cairo_transform (cairo_t *cr, const cairo_matrix_t *matrix);

void cairo_set_matrix (cairo_t * cr, const cairo_matrix_t * matrix);

void cairo_identity_matrix (cairo_t * cr);

void cairo_user_to_device (cairo_t *cr, IN_OUTLIST double x, IN_OUTLIST double y);

void cairo_user_to_device_distance (cairo_t *cr, IN_OUTLIST double dx, IN_OUTLIST double dy);

void cairo_device_to_user (cairo_t *cr, IN_OUTLIST double x, IN_OUTLIST double y);

void cairo_device_to_user_distance (cairo_t *cr, IN_OUTLIST double dx, IN_OUTLIST double dy);

void cairo_new_path (cairo_t * cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_new_sub_path (cairo_t *cr);

#endif

void cairo_move_to (cairo_t * cr, double x, double y);

void cairo_line_to (cairo_t * cr, double x, double y);

void cairo_curve_to (cairo_t * cr, double x1, double y1, double x2, double y2, double x3, double y3);

void cairo_arc (cairo_t * cr, double xc, double yc, double radius, double angle1, double angle2);

void cairo_arc_negative (cairo_t * cr, double xc, double yc, double radius, double angle1, double angle2);

void cairo_rel_move_to (cairo_t * cr, double dx, double dy);

void cairo_rel_line_to (cairo_t * cr, double dx, double dy);

void cairo_rel_curve_to (cairo_t * cr, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3);

void cairo_rectangle (cairo_t * cr, double x, double y, double width, double height);

void cairo_close_path (cairo_t * cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)

void cairo_path_extents (cairo_t *cr, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2);

#endif

void cairo_paint (cairo_t *cr);

void cairo_paint_with_alpha (cairo_t *cr, double alpha);

void cairo_mask (cairo_t *cr, cairo_pattern_t *pattern);

void cairo_mask_surface (cairo_t *cr, cairo_surface_t *surface, double surface_x, double surface_y);

void cairo_stroke (cairo_t * cr);

void cairo_stroke_preserve (cairo_t *cr);

void cairo_fill (cairo_t * cr);

void cairo_fill_preserve (cairo_t *cr);

void cairo_copy_page (cairo_t * cr);

void cairo_show_page (cairo_t * cr);

int cairo_in_stroke (cairo_t * cr, double x, double y);

int cairo_in_fill (cairo_t * cr, double x, double y);

void cairo_stroke_extents (cairo_t * cr, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2);

void cairo_fill_extents (cairo_t * cr, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2);

void cairo_clip (cairo_t * cr);

void cairo_clip_preserve (cairo_t *cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

##cairo_rectangle_list_t * cairo_copy_clip_rectangle_list (cairo_t *cr);
void cairo_copy_clip_rectangle_list (cairo_t *cr)
    PREINIT:
	cairo_rectangle_list_t *list;
	int i;
    PPCODE:
	list = cairo_copy_clip_rectangle_list (cr);
	CAIRO_PERL_CHECK_STATUS (list->status);
	EXTEND (sp, list->num_rectangles);
	for (i = 0; i < list->num_rectangles; i++)
		PUSHs (sv_2mortal (newSVCairoRectangle (&(list->rectangles[i]))));
	cairo_rectangle_list_destroy (list);

void cairo_clip_extents (cairo_t *cr, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)

cairo_bool_t cairo_in_clip (cairo_t *cr, double x, double y);

#endif

void cairo_reset_clip (cairo_t *cr);

void cairo_select_font_face (cairo_t *cr, const char_utf8 *family, cairo_font_slant_t slant, cairo_font_weight_t weight);

void cairo_set_font_size (cairo_t *cr, double size);

void cairo_set_font_matrix (cairo_t *cr, const cairo_matrix_t *matrix);

##void cairo_get_font_matrix (cairo_t *cr, cairo_matrix_t *matrix);
cairo_matrix_t * cairo_get_font_matrix (cairo_t *cr)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_get_font_matrix (cr, &matrix);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

void cairo_set_font_options (cairo_t *cr, const cairo_font_options_t *options);

##void cairo_get_font_options (cairo_t *cr, cairo_font_options_t *options);
cairo_font_options_t * cairo_get_font_options (cairo_t *cr)
    CODE:
	RETVAL = cairo_font_options_create ();
	cairo_get_font_options (cr, RETVAL);
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_set_scaled_font (cairo_t *cr, const cairo_scaled_font_t *scaled_font);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

cairo_scaled_font_t * cairo_get_scaled_font (cairo_t *cr);

#endif

void cairo_show_text (cairo_t * cr, const char_utf8 * utf8);

##void cairo_show_glyphs (cairo_t * cr, cairo_glyph_t * glyphs, int num_glyphs);
void cairo_show_glyphs (cairo_t * cr, ...)
    PREINIT:
	cairo_glyph_t * glyphs = NULL;
	int num_glyphs, i;
    CODE:
	num_glyphs = items - 1;
	Newz (0, glyphs, num_glyphs, cairo_glyph_t);
	for (i = 1; i < items; i++)
		glyphs[i - 1] = *SvCairoGlyph (ST (i));
	cairo_show_glyphs (cr, glyphs, num_glyphs);
	Safefree (glyphs);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

##void cairo_show_text_glyphs (cairo_t *cr, const char *utf8, int utf8_len, const cairo_glyph_t *glyphs, int num_glyphs, const cairo_text_cluster_t *clusters, int num_clusters, cairo_text_cluster_flags_t cluster_flags);
void
cairo_show_text_glyphs (cairo_t *cr, SV *utf8_sv, SV *glyphs_sv, SV *clusters_sv, cairo_text_cluster_flags_t cluster_flags)
    PREINIT:
	const char *utf8 = NULL;
	STRLEN utf8_len = 0;
	cairo_glyph_t * glyphs = NULL;
	cairo_text_cluster_t * clusters = NULL;
	int i, num_glyphs, num_clusters;
	AV *glyphs_av, *clusters_av;
    CODE:
	if (!cairo_perl_sv_is_array_ref (glyphs_sv))
		croak ("glyphs must be an array ref");
	if (!cairo_perl_sv_is_array_ref (clusters_sv))
		croak ("text clusters must be an array ref");

	sv_utf8_upgrade (utf8_sv);
	utf8 = SvPV (utf8_sv, utf8_len);

	glyphs_av = (AV *) SvRV (glyphs_sv);
	num_glyphs = av_len (glyphs_av) + 1;
	glyphs = cairo_glyph_allocate (num_glyphs);
	for (i = 0; i < num_glyphs; i++) {
		SV **value = av_fetch (glyphs_av, i, 0);
		if (value)
			glyphs[i] = *SvCairoGlyph (*value);
	}

	clusters_av = (AV *) SvRV (clusters_sv);
	num_clusters = av_len (clusters_av) + 1;
	clusters = cairo_text_cluster_allocate (num_clusters);
	for (i = 0; i < num_clusters; i++) {
		SV **value = av_fetch (clusters_av, i, 0);
		if (value)
			clusters[i] = *SvCairoTextCluster (*value);
	}

	cairo_show_text_glyphs (cr,
	                        utf8, (int) utf8_len,
	                        glyphs, num_glyphs,
	                        clusters, num_clusters, cluster_flags);

	cairo_text_cluster_free (clusters);
	cairo_glyph_free (glyphs);

#endif

cairo_font_face_t * cairo_get_font_face (cairo_t *cr);

##void cairo_font_extents (cairo_t *cr, cairo_font_extents_t *extents);
cairo_font_extents_t * cairo_font_extents (cairo_t *cr)
    PREINIT:
	cairo_font_extents_t extents;
    CODE:
	cairo_font_extents (cr, &extents);
	RETVAL = &extents;
    OUTPUT:
	RETVAL

void cairo_set_font_face (cairo_t *cr, cairo_font_face_t *font_face);

##void cairo_text_extents (cairo_t * cr, const char * utf8, cairo_text_extents_t * extents);
cairo_text_extents_t * cairo_text_extents (cairo_t * cr, const char_utf8 * utf8)
    PREINIT:
	cairo_text_extents_t extents;
    CODE:
	cairo_text_extents (cr, utf8, &extents);
	RETVAL = &extents;
    OUTPUT:
	RETVAL

##void cairo_glyph_extents (cairo_t * cr, cairo_glyph_t * glyphs, int num_glyphs, cairo_text_extents_t * extents);
cairo_text_extents_t * cairo_glyph_extents (cairo_t * cr, ...)
    PREINIT:
	cairo_text_extents_t extents;
	cairo_glyph_t * glyphs = NULL;
	int num_glyphs, i;
    CODE:
	num_glyphs = items - 1;
	Newz (0, glyphs, num_glyphs, cairo_glyph_t);
	for (i = 1; i < items; i++)
		glyphs[i - 1] = *SvCairoGlyph (ST (i));
	cairo_glyph_extents (cr, glyphs, num_glyphs, &extents);
	RETVAL = &extents;
	Safefree (glyphs);
    OUTPUT:
	RETVAL

void cairo_text_path  (cairo_t * cr, const char_utf8 * utf8);

##void cairo_glyph_path (cairo_t * cr, cairo_glyph_t * glyphs, int num_glyphs);
void cairo_glyph_path (cairo_t * cr, ...)
    PREINIT:
	cairo_glyph_t * glyphs = NULL;
	int num_glyphs, i;
    CODE:
	num_glyphs = items - 1;
	Newz (0, glyphs, num_glyphs, cairo_glyph_t);
	for (i = 1; i < items; i++)
		glyphs[i - 1] = *SvCairoGlyph (ST (i));
	cairo_glyph_path (cr, glyphs, num_glyphs);
	Safefree (glyphs);

cairo_operator_t cairo_get_operator (cairo_t *cr);

cairo_pattern_t * cairo_get_source (cairo_t *cr);

double cairo_get_tolerance (cairo_t *cr);

cairo_antialias_t cairo_get_antialias (cairo_t *cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)

cairo_bool_t cairo_has_current_point (cairo_t *cr);

#endif

void cairo_get_current_point (cairo_t *cr, OUTLIST double x, OUTLIST double y);

cairo_fill_rule_t cairo_get_fill_rule (cairo_t *cr);

double cairo_get_line_width (cairo_t *cr);

cairo_line_cap_t cairo_get_line_cap (cairo_t *cr);

cairo_line_join_t cairo_get_line_join (cairo_t *cr);

double cairo_get_miter_limit (cairo_t *cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)

## int cairo_get_dash_count (cairo_t *cr);
## void cairo_get_dash (cairo_t *cr, double *dashes, double *offset);
void cairo_get_dash (cairo_t *cr)
    PREINIT:
	int count, i;
	double *dashes, offset;
    PPCODE:
	count = cairo_get_dash_count (cr);
	if (count == 0) {
		dashes = NULL;
	} else {
		New (0, dashes, count, double);
		if (!dashes)
			croak ("malloc failure for (%d) elements", count);
	}
	cairo_get_dash (cr, dashes, &offset);
	EXTEND (sp, count + 1);
	PUSHs (sv_2mortal (newSVnv (offset)));
	for (i = 0; i < count; i++)
		PUSHs (sv_2mortal (newSVnv (dashes[i])));
	Safefree (dashes);

#endif

##void cairo_get_matrix (cairo_t *cr, cairo_matrix_t *matrix);
cairo_matrix_t * cairo_get_matrix (cairo_t *cr)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_get_matrix (cr, &matrix);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

cairo_surface_t * cairo_get_target (cairo_t *cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_surface_t * cairo_get_group_target (cairo_t *cr);

#endif

cairo_path_t * cairo_copy_path (cairo_t *cr);

cairo_path_t * cairo_copy_path_flat (cairo_t *cr);

void cairo_append_path (cairo_t *cr, cairo_path_t *path);

cairo_status_t cairo_status (cairo_t *cr);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 16, 0)

void cairo_tag_begin (cairo_t * cr, const char_utf8 * tag_name, const char_utf8 * attributes);

void cairo_tag_end (cairo_t * cr, const char_utf8 * tag_name);

BOOT:
    HV *stash = gv_stashpv("Cairo", 0);
    newCONSTSUB (stash, "TAG_DEST",  newSVpv (CAIRO_TAG_DEST, 0));
    newCONSTSUB (stash, "TAG_LINK",  newSVpv (CAIRO_TAG_LINK, 0));

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo	PACKAGE = Cairo	PREFIX = cairo_

bool
HAS_PS_SURFACE ()
    CODE:
#ifdef CAIRO_HAS_PS_SURFACE
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

bool
HAS_PDF_SURFACE ()
    CODE:
#ifdef CAIRO_HAS_PDF_SURFACE
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

bool
HAS_SVG_SURFACE ()
    CODE:
#ifdef CAIRO_HAS_SVG_SURFACE
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

bool
HAS_RECORDING_SURFACE ()
    CODE:
#ifdef CAIRO_HAS_RECORDING_SURFACE
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

bool
HAS_FT_FONT ()
    CODE:
#ifdef CAIRO_HAS_FT_FONT
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

bool
HAS_PNG_FUNCTIONS ()
    CODE:
#ifdef CAIRO_HAS_PNG_FUNCTIONS
	RETVAL = TRUE;
#else
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL
