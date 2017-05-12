/*
 * Copyright (c) 2004-2005, 2012 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

static const char *
get_package (cairo_font_face_t *face)
{
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_font_type_t type;
	const char *package;

	type = cairo_font_face_get_type (face);
	switch (type) {
	    case CAIRO_FONT_TYPE_TOY:
		package = "Cairo::ToyFontFace";
		break;

	    case CAIRO_FONT_TYPE_FT:
		package = "Cairo::FtFontFace";
		break;

	    /* These aren't wrapped yet: */
	    case CAIRO_FONT_TYPE_WIN32:
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)
	    case CAIRO_FONT_TYPE_QUARTZ:
#endif
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)
	    case CAIRO_FONT_TYPE_USER:
#endif
		package = "Cairo::FontFace";
		break;

	    default:
		warn ("unknown font face type %d encountered", type);
		package = "Cairo::FontFace";
		break;
	}

	return package;
#else
	const char *package = cairo_perl_package_table_lookup (face);
	return package ? package : "Cairo::FontFace";
#endif
}

SV *
cairo_font_face_to_sv (cairo_font_face_t *face)
{
	SV *sv = newSV (0);
	sv_setref_pv(sv, get_package (face), face);
	return sv;
}

/* ------------------------------------------------------------------------- */

MODULE = Cairo::Font	PACKAGE = Cairo::FontFace	PREFIX = cairo_font_face_

cairo_status_t cairo_font_face_status (cairo_font_face_t * font);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_font_type_t cairo_font_face_get_type (cairo_font_face_t *font_face);

#endif

void DESTROY (cairo_font_face_t * font)
    CODE:
	cairo_font_face_destroy (font);

# --------------------------------------------------------------------------- #

MODULE = Cairo	PACKAGE = Cairo::ToyFontFace	PREFIX = cairo_toy_font_face_

BOOT:
	cairo_perl_set_isa ("Cairo::ToyFontFace", "Cairo::FontFace");

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

# cairo_font_face_t * cairo_toy_font_face_create (const char *family, cairo_font_slant_t slant, cairo_font_weight_t weight)
cairo_font_face_t_noinc *
cairo_toy_font_face_create (class, const char_utf8 *family, cairo_font_slant_t slant, cairo_font_weight_t weight)
    C_ARGS:
	family, slant, weight
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ToyFontFace");
#endif

const char_utf8 * cairo_toy_font_face_get_family (cairo_font_face_t *font_face);

cairo_font_slant_t  cairo_toy_font_face_get_slant (cairo_font_face_t *font_face);

cairo_font_weight_t  cairo_toy_font_face_get_weight (cairo_font_face_t *font_face);

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Font	PACKAGE = Cairo::ScaledFont	PREFIX = cairo_scaled_font_

##cairo_scaled_font_t* cairo_scaled_font_create (cairo_font_face_t *font_face, const cairo_matrix_t *font_matrix, const cairo_matrix_t *ctm, const cairo_font_options_t *options);
cairo_scaled_font_t_noinc * cairo_scaled_font_create (class, cairo_font_face_t *font_face, const cairo_matrix_t *font_matrix, const cairo_matrix_t *ctm, const cairo_font_options_t *options)
    C_ARGS:
	font_face, font_matrix, ctm, options
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ScaledFont");
#endif

cairo_status_t cairo_scaled_font_status (cairo_scaled_font_t *scaled_font);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_font_type_t cairo_scaled_font_get_type (cairo_scaled_font_t *scaled_font);

#endif

##cairo_status_t cairo_scaled_font_extents (cairo_scaled_font_t *scaled_font, cairo_font_extents_t *extents);
cairo_font_extents_t * cairo_scaled_font_extents (cairo_scaled_font_t *scaled_font)
    PREINIT:
	cairo_font_extents_t extents;
    CODE:
	cairo_scaled_font_extents (scaled_font, &extents);
	RETVAL = &extents;
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

##void cairo_scaled_font_text_extents (cairo_scaled_font_t *scaled_font, const char *utf8, cairo_text_extents_t *extents);
cairo_text_extents_t * cairo_scaled_font_text_extents (cairo_scaled_font_t *scaled_font, const char_utf8 *utf8)
    PREINIT:
	cairo_text_extents_t extents;
    CODE:
	cairo_scaled_font_text_extents (scaled_font, utf8, &extents);
	RETVAL = &extents;
    OUTPUT:
	RETVAL

#endif

##void cairo_scaled_font_glyph_extents (cairo_scaled_font_t *scaled_font, cairo_glyph_t *glyphs, int num_glyphs, cairo_text_extents_t *extents);
cairo_text_extents_t * cairo_scaled_font_glyph_extents (cairo_scaled_font_t *scaled_font, ...)
    PREINIT:
	cairo_glyph_t * glyphs = NULL;
	int num_glyphs, i;
	cairo_text_extents_t extents;
    CODE:
	num_glyphs = items - 1;
	Newz (0, glyphs, num_glyphs, cairo_glyph_t);
	for (i = 1; i < items; i++)
		glyphs[i - 1] = *SvCairoGlyph (ST (i));
	cairo_scaled_font_glyph_extents (scaled_font, glyphs, num_glyphs, &extents);
	RETVAL = &extents;
	Safefree (glyphs);
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

##cairo_status_t cairo_scaled_font_text_to_glyphs (cairo_scaled_font_t *scaled_font, double x, double y, const char *utf8, int utf8_len, cairo_glyph_t **glyphs, int *num_glyphs, cairo_text_cluster_t **clusters, int *num_clusters, cairo_text_cluster_flags_t *cluster_flags);
void
cairo_scaled_font_text_to_glyphs (cairo_scaled_font_t *scaled_font, double x, double y, SV *utf8_sv)
    PREINIT:
	const char *utf8;
	STRLEN utf8_len;
	cairo_glyph_t *glyphs = NULL;
	int num_glyphs;
	cairo_text_cluster_t *clusters = NULL;
	int num_clusters;
	cairo_text_cluster_flags_t cluster_flags;
	cairo_status_t status;
    PPCODE:
	sv_utf8_upgrade (utf8_sv);
	utf8 = SvPV (utf8_sv, utf8_len);
	status = cairo_scaled_font_text_to_glyphs (
	           scaled_font,
	           x, y,
	           utf8, utf8_len,
	           &glyphs, &num_glyphs,
	           &clusters, &num_clusters, &cluster_flags);
	PUSHs (sv_2mortal (newSVCairoStatus (status)));
	if (CAIRO_STATUS_SUCCESS == status) {
		AV *glyphs_av, *clusters_av;
		int i;
		glyphs_av = newAV ();
		for (i = 0; i < num_glyphs; i++)
			av_push (glyphs_av, newSVCairoGlyph (&glyphs[i]));
		cairo_glyph_free (glyphs);
		clusters_av = newAV ();
		for (i = 0; i < num_clusters; i++)
			av_push (clusters_av, newSVCairoTextCluster (&clusters[i]));
		cairo_text_cluster_free (clusters);
		EXTEND (SP, 4);
		PUSHs (sv_2mortal (newRV_noinc ((SV *) glyphs_av)));
		PUSHs (sv_2mortal (newRV_noinc ((SV *) clusters_av)));
		PUSHs (sv_2mortal (newSVCairoTextClusterFlags (cluster_flags)));
	}


#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_font_face_t * cairo_scaled_font_get_font_face (cairo_scaled_font_t *scaled_font);

##void cairo_scaled_font_get_font_matrix (cairo_scaled_font_t *scaled_font, cairo_matrix_t *font_matrix);
cairo_matrix_t * cairo_scaled_font_get_font_matrix (cairo_scaled_font_t *scaled_font)
    PREINIT:
	cairo_matrix_t font_matrix;
    CODE:
	cairo_scaled_font_get_font_matrix (scaled_font, &font_matrix);
	RETVAL = cairo_perl_copy_matrix (&font_matrix);
    OUTPUT:
	RETVAL

##void cairo_scaled_font_get_ctm (cairo_scaled_font_t *scaled_font, cairo_matrix_t *ctm);
cairo_matrix_t * cairo_scaled_font_get_ctm (cairo_scaled_font_t *scaled_font)
    PREINIT:
	cairo_matrix_t ctm;
    CODE:
	cairo_scaled_font_get_ctm (scaled_font, &ctm);
	RETVAL = cairo_perl_copy_matrix (&ctm);
    OUTPUT:
	RETVAL

##void cairo_scaled_font_get_font_options (cairo_scaled_font_t *scaled_font, cairo_font_options_t *options);
cairo_font_options_t * cairo_scaled_font_get_font_options (cairo_scaled_font_t *scaled_font)
    CODE:
	RETVAL = cairo_font_options_create ();
	cairo_scaled_font_get_font_options (scaled_font, RETVAL);
    OUTPUT:
	RETVAL

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

##void cairo_scaled_font_get_scale_matrix (cairo_scaled_font_t *scaled_font, cairo_matrix_t *scale_matrix);
cairo_matrix_t *
cairo_scaled_font_get_scale_matrix (cairo_scaled_font_t *scaled_font)
    PREINIT:
	cairo_matrix_t matrix;
    CODE:
	cairo_scaled_font_get_scale_matrix (scaled_font, &matrix);
	RETVAL = cairo_perl_copy_matrix (&matrix);
    OUTPUT:
	RETVAL

#endif

void DESTROY (cairo_scaled_font_t * font)
    CODE:
	cairo_scaled_font_destroy (font);

# --------------------------------------------------------------------------- #

MODULE = Cairo::Font	PACKAGE = Cairo::FontOptions	PREFIX = cairo_font_options_

##cairo_font_options_t * cairo_font_options_create (void);
cairo_font_options_t * cairo_font_options_create (class)
    C_ARGS:
	/* void */

# FIXME: Necessary?
##cairo_font_options_t * cairo_font_options_copy (const cairo_font_options_t *original);

cairo_status_t cairo_font_options_status (cairo_font_options_t *options);

void cairo_font_options_merge (cairo_font_options_t *options, const cairo_font_options_t *other);

cairo_bool_t cairo_font_options_equal (const cairo_font_options_t *options, const cairo_font_options_t *other);

unsigned long cairo_font_options_hash (const cairo_font_options_t *options);

void cairo_font_options_set_antialias (cairo_font_options_t *options, cairo_antialias_t antialias);

cairo_antialias_t cairo_font_options_get_antialias (const cairo_font_options_t *options);

void cairo_font_options_set_subpixel_order (cairo_font_options_t *options, cairo_subpixel_order_t subpixel_order);

cairo_subpixel_order_t cairo_font_options_get_subpixel_order (const cairo_font_options_t *options);

void cairo_font_options_set_hint_style (cairo_font_options_t *options, cairo_hint_style_t hint_style);

cairo_hint_style_t cairo_font_options_get_hint_style (const cairo_font_options_t *options);

void cairo_font_options_set_hint_metrics (cairo_font_options_t *options, cairo_hint_metrics_t hint_metrics);

cairo_hint_metrics_t cairo_font_options_get_hint_metrics (const cairo_font_options_t *options);

void DESTROY (cairo_font_options_t *options)
    CODE:
	cairo_font_options_destroy (options);
