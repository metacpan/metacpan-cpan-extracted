/*
 * Copyright (c) 2007 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

static const cairo_user_data_key_t face_key;

static void
face_destroy (void *face)
{
	SvREFCNT_dec ((SV *) face);
}

MODULE = Cairo::Ft	PACKAGE = Cairo::FtFontFace PREFIX = cairo_ft_font_face_

BOOT:
	cairo_perl_set_isa ("Cairo::FtFontFace", "Cairo::FontFace");

# cairo_font_face_t * cairo_ft_font_face_create_for_ft_face (FT_Face face, int load_flags);
cairo_font_face_t_noinc *
cairo_ft_font_face_create (class, SV *face, int load_flags=0)
    PREINIT:
	FT_Face real_face = NULL;
	cairo_status_t status;
    CODE:
	if (sv_isobject (face) && sv_derived_from (face, "Font::FreeType::Face")) {
		real_face = (FT_Face) SvIV ((SV *) SvRV (face));
	} else {
		croak("'%s' is not of type Font::FreeType::Face",
		      SvPV_nolen (face));
	}
	RETVAL = cairo_ft_font_face_create_for_ft_face (real_face, load_flags);
	/* Keep the face SV (and thus the FT_Face) alive long enough */
	SvREFCNT_inc (face);
	status = cairo_font_face_set_user_data (RETVAL, &face_key, face,
	                                        face_destroy);
	if (status) {
		warn ("Couldn't install a user data handler, "
		      "so an FT_Face will be leaked");
	}
    OUTPUT:
	RETVAL
