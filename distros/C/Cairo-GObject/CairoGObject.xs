/*
 * Copyright (c) 2011 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 */

#include <cairo-perl.h>
#include <gperl.h>

#include <cairo-gobject.h>

/* ------------------------------------------------------------------------- */

static SV *
context_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return own ?
		newSVCairo_noinc ((cairo_t *) boxed) :
		newSVCairo ((cairo_t *) boxed);
}

gpointer
context_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairo_ornull (sv);
}

GPerlBoxedWrapperClass context_wrapper_class = {
	context_wrap,
	context_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
pattern_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return own ?
		newSVCairoPattern_noinc ((cairo_pattern_t *) boxed) :
		newSVCairoPattern ((cairo_pattern_t *) boxed);
}

gpointer
pattern_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoPattern_ornull (sv);
}

GPerlBoxedWrapperClass pattern_wrapper_class = {
	pattern_wrap,
	pattern_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
surface_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return own ?
		newSVCairoSurface_noinc ((cairo_surface_t *) boxed) :
		newSVCairoSurface ((cairo_surface_t *) boxed);
}

gpointer
surface_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoSurface_ornull (sv);
}

GPerlBoxedWrapperClass surface_wrapper_class = {
	surface_wrap,
	surface_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
rectangle_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoRectangle ((cairo_rectangle_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
rectangle_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoRectangle_ornull (sv);
}

GPerlBoxedWrapperClass rectangle_wrapper_class = {
	rectangle_wrap,
	rectangle_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
rectangle_int_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoRectangleInt ((cairo_rectangle_int_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
rectangle_int_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoRectangleInt_ornull (sv);
}

GPerlBoxedWrapperClass rectangle_int_wrapper_class = {
	rectangle_int_wrap,
	rectangle_int_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
region_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoRegion ((cairo_region_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
region_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoRegion_ornull (sv);
}

GPerlBoxedWrapperClass region_wrapper_class = {
	region_wrap,
	region_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
scaled_font_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoScaledFont ((cairo_scaled_font_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
scaled_font_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoScaledFont_ornull (sv);
}

GPerlBoxedWrapperClass scaled_font_wrapper_class = {
	scaled_font_wrap,
	scaled_font_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
font_face_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoFontFace ((cairo_font_face_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
font_face_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoFontFace_ornull (sv);
}

GPerlBoxedWrapperClass font_face_wrapper_class = {
	font_face_wrap,
	font_face_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

static SV *
font_options_wrap (GType gtype, const char * package, gpointer boxed, gboolean own)
{
	SV * sv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	sv = newSVCairoFontOptions ((cairo_font_options_t *) boxed);
	if (own) {
		/* FIXME: What if some other allocator was used? */
		g_free (boxed);
	}
	return sv;
}

gpointer
font_options_unwrap (GType gtype, const char * package, SV * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	return SvCairoFontOptions_ornull (sv);
}

GPerlBoxedWrapperClass font_options_wrapper_class = {
	font_options_wrap,
	font_options_unwrap,
	NULL,
};

/* ------------------------------------------------------------------------- */

MODULE = Cairo::GObject	PACKAGE = Cairo::GObject

BOOT:
{
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_CONTEXT, "Cairo::Context",
	                      &context_wrapper_class);
	/* CAIRO_GOBJECT_TYPE_DEVICE not wrapped yet */
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_PATTERN, "Cairo::Pattern",
	                      &pattern_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_SURFACE, "Cairo::Surface",
	                      &surface_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_RECTANGLE, "Cairo::Rectangle",
	                      &rectangle_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_RECTANGLE_INT, "Cairo::RectangleInt",
	                      &rectangle_int_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_REGION, "Cairo::Region",
	                      &region_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_SCALED_FONT, "Cairo::ScaledFont",
	                      &scaled_font_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_FONT_FACE, "Cairo::FontFace",
	                      &font_face_wrapper_class);
	gperl_register_boxed (CAIRO_GOBJECT_TYPE_FONT_OPTIONS, "Cairo::FontOptions",
	                      &font_options_wrapper_class);
}
