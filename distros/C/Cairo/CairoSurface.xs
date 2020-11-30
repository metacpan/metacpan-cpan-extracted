/*
 * Copyright (c) 2004-2006, 2012-2013 by the cairo perl team (see the file
 * README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

#define NEED_sv_2pv_flags
#include "ppport.h"

#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)

static HV *pointer_to_package = NULL;

/* A hex character represents four bits in the address of a pointer, so we'll
 * need BITS_PER_POINTER/4 characters.  That's sizeof (void*) * 2.  Add 2 for
 * the "0x" part.  Add 1 for the trailing \0.
 */
#define MAX_KEY_LENGTH ((sizeof(void*) * 2) + 2 + 1)

/* This stuff is also used in CairoPattern.xs, hence no static on the
 * functions.
 */

void
cairo_perl_package_table_insert (void *pointer, const char *package)
{
	char key[MAX_KEY_LENGTH];

	if (!pointer_to_package) {
		pointer_to_package = newHV ();
	}

	sprintf (key, "%p", pointer);
	hv_store (pointer_to_package, key, strlen (key), newSVpv (package, 0), 0);
}

const char *
cairo_perl_package_table_lookup (void *pointer)
{
	char key[MAX_KEY_LENGTH];
	SV **sv;

	if (!pointer_to_package) {
		return NULL;
	}

	sprintf (key, "%p", pointer);
	sv = hv_fetch (pointer_to_package, key, strlen (key), 0);
	if (sv && SvOK (*sv)) {
		return SvPV_nolen (*sv);
	}

	return NULL;
}

#endif /* !1.2.0 */

static const char *
get_package (cairo_surface_t *surface)
{
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_surface_type_t type;
	const char *package;

	type = cairo_surface_get_type (surface);
	switch (type) {
	    case CAIRO_SURFACE_TYPE_IMAGE:
		package = "Cairo::ImageSurface";
		break;

	    case CAIRO_SURFACE_TYPE_PDF:
		package = "Cairo::PdfSurface";
		break;

	    case CAIRO_SURFACE_TYPE_PS:
		package = "Cairo::PsSurface";
		break;

	    case CAIRO_SURFACE_TYPE_SVG:
		package = "Cairo::SvgSurface";
		break;

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)
	    case CAIRO_SURFACE_TYPE_RECORDING:
		package = "Cairo::RecordingSurface";
		break;
#endif

	    case CAIRO_SURFACE_TYPE_XLIB:
	    case CAIRO_SURFACE_TYPE_XCB:
	    case CAIRO_SURFACE_TYPE_GLITZ:
	    case CAIRO_SURFACE_TYPE_QUARTZ:
	    case CAIRO_SURFACE_TYPE_WIN32:
	    case CAIRO_SURFACE_TYPE_BEOS:
	    case CAIRO_SURFACE_TYPE_DIRECTFB:
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 4, 0)
	    case CAIRO_SURFACE_TYPE_OS2:
#endif
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)
	    case CAIRO_SURFACE_TYPE_WIN32_PRINTING:
	    case CAIRO_SURFACE_TYPE_QUARTZ_IMAGE:
#endif
#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)
	    case CAIRO_SURFACE_TYPE_SCRIPT:
	    case CAIRO_SURFACE_TYPE_QT:
	    case CAIRO_SURFACE_TYPE_VG:
	    case CAIRO_SURFACE_TYPE_GL:
	    case CAIRO_SURFACE_TYPE_DRM:
	    case CAIRO_SURFACE_TYPE_TEE:
	    case CAIRO_SURFACE_TYPE_XML:
	    case CAIRO_SURFACE_TYPE_SKIA:
	    case CAIRO_SURFACE_TYPE_SUBSURFACE:
#endif
		package = "Cairo::Surface";
		break;

	    default:
		warn ("unknown surface type %d encountered", type);
		package = "Cairo::Surface";
		break;
	}

	return package;
#else
	const char *package = cairo_perl_package_table_lookup (surface);
	return package ? package : "Cairo::Surface";
#endif
}

SV *
cairo_surface_to_sv (cairo_surface_t *surface)
{
	SV *sv = newSV (0);
	sv_setref_pv(sv, get_package (surface), surface);
	return sv;
}

/* -------------------------------------------------------------------------- */

typedef struct {
	SV *func;
	SV *data;
	void *context;
} CairoPerlCallback;

#ifdef PERL_IMPLICIT_CONTEXT
# define dCAIRO_PERL_CALLBACK_MARSHAL_SP		\
	SV ** sp;
# define CAIRO_PERL_CALLBACK_MARSHAL_INIT(callback)	\
	PERL_SET_CONTEXT (callback->context);		\
	SPAGAIN;
#else
# define dCAIRO_PERL_CALLBACK_MARSHAL_SP		\
	dSP;
# define CAIRO_PERL_CALLBACK_MARSHAL_INIT(callback)	\
	/* nothing to do */
#endif

static CairoPerlCallback *
cairo_perl_callback_new (SV *func, SV *data)
{
	CairoPerlCallback *callback;

	Newz (0, callback, 1, CairoPerlCallback);

	callback->func = newSVsv (func);
	if (data)
		callback->data = newSVsv (data);

#ifdef PERL_IMPLICIT_CONTEXT
	callback->context = aTHX;
#endif

	return callback;
}

static void
cairo_perl_callback_free (CairoPerlCallback *callback)
{
	SvREFCNT_dec (callback->func);
	if (callback->data)
		SvREFCNT_dec (callback->data);
	Safefree (callback);
}

/* -------------------------------------------------------------------------- */

/* Caller owns returned SV */
static SV *
strip_off_location (SV *error)
{
	SV *saved_defsv, *result;
	saved_defsv = newSVsv (DEFSV);
	ENTER;
	SAVETMPS;
	sv_setsv (DEFSV, error);
	eval_pv ("s/^([-_\\w]+) .+$/$1/s", FALSE);
	result = newSVsv (DEFSV);
	FREETMPS;
	LEAVE;
	sv_setsv (DEFSV, saved_defsv);
	SvREFCNT_dec (saved_defsv);
	return result;
}

static cairo_status_t
write_func_marshaller (void *closure,
                       const unsigned char *data,
                       unsigned int length)
{
	CairoPerlCallback *callback;
	cairo_status_t status = CAIRO_STATUS_SUCCESS;
	dCAIRO_PERL_CALLBACK_MARSHAL_SP;

	callback = (CairoPerlCallback *) closure;

	CAIRO_PERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (callback->data ? callback->data : &PL_sv_undef);
	PUSHs (sv_2mortal (newSVpv ((const char *) data, length)));

	PUTBACK;
	call_sv (callback->func, G_DISCARD | G_EVAL);
	SPAGAIN;

	if (SvTRUE (ERRSV)) {
		SV *sv = strip_off_location (ERRSV);
		status = SvCairoStatus (sv);
		SvREFCNT_dec (sv);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

/* -------------------------------------------------------------------------- */

static cairo_status_t
read_func_marshaller (void *closure,
                      unsigned char *data,
                      unsigned int length)
{
	CairoPerlCallback *callback;
	cairo_status_t status = CAIRO_STATUS_SUCCESS;
	dCAIRO_PERL_CALLBACK_MARSHAL_SP;

	callback = (CairoPerlCallback *) closure;

	CAIRO_PERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (callback->data ? callback->data : &PL_sv_undef);
	PUSHs (sv_2mortal (newSVuv (length)));

	PUTBACK;
	call_sv (callback->func, G_SCALAR | G_EVAL);
	SPAGAIN;

	if (SvTRUE (ERRSV)) {
		SV *sv = strip_off_location (ERRSV);
		status = SvCairoStatus (sv);
		SvREFCNT_dec (sv);
	} else {
		SV *retval = POPs;
		STRLEN len = 0;
		const char *sv_data = SvPV (retval, len);
		/* should we assert that len == length? */
		memcpy (data, sv_data, len);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

/* -------------------------------------------------------------------------- */

static void
data_destroy (void *data)
{
	SvREFCNT_dec ((SV *) data);
}

/* -------------------------------------------------------------------------- */

MODULE = Cairo::Surface	PACKAGE = Cairo::Surface	PREFIX = cairo_surface_

void DESTROY (cairo_surface_t * surface);
    CODE:
	cairo_surface_destroy (surface);

cairo_surface_t_noinc *
cairo_surface_create_similar (...)
    PREINIT:
	int offset = 0;
	cairo_surface_t * other = NULL;
	cairo_content_t content = 0;
	int width = 0;
	int height = 0;
    CODE:
	if (items == 4) {
		offset = 0;
	} else if (items == 5) {
		offset = 1;
	} else {
		croak ("Usage: Cairo::Surface->create_similar ($other, $content, $width, $height)\n"
		       " -or-: $other->create_similar ($content, $width, $height)");
	}
	other = SvCairoSurface (ST (0 + offset));
	content = SvCairoContent (ST (1 + offset));
	width = SvIV (ST (2 + offset));
	height = SvIV (ST (3 + offset));
	RETVAL = cairo_surface_create_similar (other, content, width, height);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	{
	const char *package = cairo_perl_package_table_lookup (other);
	cairo_perl_package_table_insert (RETVAL, package ? package : "Cairo::Surface");
	}
#endif
    OUTPUT:
	RETVAL

void cairo_surface_finish (cairo_surface_t *surface);

cairo_status_t cairo_surface_status (cairo_surface_t *surface);

void cairo_surface_set_device_offset (cairo_surface_t *surface, double x_offset, double y_offset);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_surface_get_device_offset (cairo_surface_t *surface, OUTLIST double x_offset, OUTLIST double y_offset);

void cairo_surface_set_fallback_resolution (cairo_surface_t *surface, double x_pixels_per_inch, double y_pixels_per_inch);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 8, 0)

void cairo_surface_get_fallback_resolution (cairo_surface_t *surface, OUTLIST double x_pixels_per_inch, OUTLIST double y_pixels_per_inch);

#endif

##void cairo_surface_get_font_options (cairo_surface_t *surface, cairo_font_options_t *options);
cairo_font_options_t * cairo_surface_get_font_options (cairo_surface_t *surface)
    CODE:
	RETVAL = cairo_font_options_create ();
	cairo_surface_get_font_options (surface, RETVAL);
    OUTPUT:
	RETVAL

void cairo_surface_flush (cairo_surface_t *surface);

void cairo_surface_mark_dirty (cairo_surface_t *surface);

void cairo_surface_mark_dirty_rectangle (cairo_surface_t *surface, int x, int y, int width, int height);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

cairo_surface_type_t cairo_surface_get_type (cairo_surface_t *surface);

cairo_content_t cairo_surface_get_content (cairo_surface_t *surface);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)

# cairo_status_t cairo_surface_set_mime_data (cairo_surface_t *surface, const char *mime_type, const unsigned char *data, unsigned long  length, cairo_destroy_func_t destroy, void *closure);
cairo_status_t
cairo_surface_set_mime_data (cairo_surface_t *surface, const char *mime_type, SV *data);
    PREINIT:
	const unsigned char *mime_data;
	unsigned long length;
    CODE:
	SvREFCNT_inc (data);
	mime_data = (const unsigned char *) SvPV(data, length);
	RETVAL = cairo_surface_set_mime_data (surface, mime_type, mime_data, length, data_destroy, data);
    OUTPUT:
	RETVAL

# void cairo_surface_get_mime_data (cairo_surface_t *surface, const char *mime_type, const unsigned char **data, unsigned long *length);
SV *
cairo_surface_get_mime_data (cairo_surface_t *surface, const char *mime_type);
    PREINIT:
	const unsigned char *data;
	unsigned long length;
    CODE:
	cairo_surface_get_mime_data (surface, mime_type, &data, &length);
	RETVAL = newSVpvn ((const char *) data, length);
    OUTPUT:
	RETVAL

BOOT:
    HV *stashsurface = gv_stashpv("Cairo::Surface", 0);
    newCONSTSUB (stashsurface, "MIME_TYPE_JP2",  newSVpv (CAIRO_MIME_TYPE_JP2,  0));
    newCONSTSUB (stashsurface, "MIME_TYPE_JPEG", newSVpv (CAIRO_MIME_TYPE_JPEG, 0));
    newCONSTSUB (stashsurface, "MIME_TYPE_PNG",  newSVpv (CAIRO_MIME_TYPE_PNG,  0));
    newCONSTSUB (stashsurface, "MIME_TYPE_URI",  newSVpv (CAIRO_MIME_TYPE_URI,  0));

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 12, 0)

cairo_bool_t cairo_surface_supports_mime_type (cairo_surface_t *surface, const char *mime_type);

BOOT:
    newCONSTSUB (stashsurface, "MIME_TYPE_UNIQUE_ID",  newSVpv (CAIRO_MIME_TYPE_UNIQUE_ID,  0));

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 14, 0)

BOOT:
    newCONSTSUB (stashsurface, "MIME_TYPE_JBIG2",            newSVpv (CAIRO_MIME_TYPE_JBIG2,            0));
    newCONSTSUB (stashsurface, "MIME_TYPE_JBIG2_GLOBAL",     newSVpv (CAIRO_MIME_TYPE_JBIG2_GLOBAL,     0));
    newCONSTSUB (stashsurface, "MIME_TYPE_JBIG2_GLOBAL_ID",  newSVpv (CAIRO_MIME_TYPE_JBIG2_GLOBAL_ID,  0));

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 16, 0)

BOOT:
    newCONSTSUB (stashsurface, "MIME_TYPE_CCITT_FAX",         newSVpv (CAIRO_MIME_TYPE_CCITT_FAX,          0));
    newCONSTSUB (stashsurface, "MIME_TYPE_CCITT_FAX_PARAMS",  newSVpv (CAIRO_MIME_TYPE_CCITT_FAX_PARAMS,   0));
    newCONSTSUB (stashsurface, "MIME_TYPE_EPS",               newSVpv (CAIRO_MIME_TYPE_EPS,                0));
    newCONSTSUB (stashsurface, "MIME_TYPE_EPS_PARAMS",        newSVpv (CAIRO_MIME_TYPE_EPS_PARAMS,         0));

#endif

#ifdef CAIRO_HAS_PNG_FUNCTIONS

cairo_status_t cairo_surface_write_to_png (cairo_surface_t *surface, const char *filename);

##cairo_status_t cairo_surface_write_to_png_stream (cairo_surface_t *surface, cairo_write_func_t write_func, void *closure);
cairo_status_t
cairo_surface_write_to_png_stream (cairo_surface_t *surface, SV *func, SV *data=NULL)
    PREINIT:
	CairoPerlCallback *callback;
    CODE:
	callback = cairo_perl_callback_new (func, data);
	RETVAL = cairo_surface_write_to_png_stream (surface,
	                                            write_func_marshaller,
	                                            callback);
	cairo_perl_callback_free (callback);
    OUTPUT:
	RETVAL

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE (1, 6, 0)

void cairo_surface_copy_page (cairo_surface_t *surface);

void cairo_surface_show_page (cairo_surface_t *surface);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE (1, 8, 0)

cairo_bool_t cairo_surface_has_show_text_glyphs (cairo_surface_t *surface);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE (1, 10, 0)

# cairo_surface_t * cairo_surface_create_for_rectangle (cairo_surface_t *target, double x, double y, double width, double height);
cairo_surface_t_noinc *
cairo_surface_create_for_rectangle (class, cairo_surface_t *target, double x, double y, double width, double height)
    C_ARGS:
	target, x, y, width, height

#endif

# --------------------------------------------------------------------------- #

MODULE = Cairo::Surface	PACKAGE = Cairo::ImageSurface	PREFIX = cairo_image_surface_

BOOT:
	cairo_perl_set_isa ("Cairo::ImageSurface", "Cairo::Surface");

##cairo_surface_t * cairo_image_surface_create (cairo_format_t format, int width, int height);
cairo_surface_t_noinc * cairo_image_surface_create (class, cairo_format_t format, int width, int height)
    C_ARGS:
	format, width, height
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ImageSurface");
#endif

##cairo_surface_t * cairo_image_surface_create_for_data (unsigned char *data, cairo_format_t format, int width, int height, int stride);
cairo_surface_t_noinc * cairo_image_surface_create_for_data (class, unsigned char *data, cairo_format_t format, int width, int height, int stride)
    C_ARGS:
	data, format, width, height, stride
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ImageSurface");
#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

# unsigned char * cairo_image_surface_get_data (cairo_surface_t *surface);
SV *
cairo_image_surface_get_data (cairo_surface_t *surface)
    PREINIT:
	unsigned char *data;
	int height, stride;
    CODE:
	data = cairo_image_surface_get_data (surface);
	height = cairo_image_surface_get_height (surface);
	stride = cairo_image_surface_get_stride (surface);
	RETVAL = data ? newSVpv ((char *) data, height * stride) : &PL_sv_undef;
    OUTPUT:
	RETVAL

cairo_format_t cairo_image_surface_get_format (cairo_surface_t *surface);

#endif

int cairo_image_surface_get_width (cairo_surface_t *surface);

int cairo_image_surface_get_height (cairo_surface_t *surface);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

int cairo_image_surface_get_stride (cairo_surface_t *surface);

#endif

#ifdef CAIRO_HAS_PNG_FUNCTIONS

##cairo_surface_t * cairo_image_surface_create_from_png (const char *filename);
cairo_surface_t_noinc * cairo_image_surface_create_from_png (class, const char *filename)
    C_ARGS:
	filename
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ImageSurface");
#endif

##cairo_surface_t * cairo_image_surface_create_from_png_stream (cairo_read_func_t read_func, void *closure);
cairo_surface_t_noinc *
cairo_image_surface_create_from_png_stream (class, SV *func, SV *data=NULL)
    PREINIT:
	CairoPerlCallback *callback;
    CODE:
	callback = cairo_perl_callback_new (func, data);
	RETVAL = cairo_image_surface_create_from_png_stream (
			read_func_marshaller, callback);
	cairo_perl_callback_free (callback);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::ImageSurface");
#endif
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

#ifdef CAIRO_HAS_PDF_SURFACE

MODULE = Cairo::Surface	PACKAGE = Cairo::PdfSurface	PREFIX = cairo_pdf_surface_

BOOT:
	cairo_perl_set_isa ("Cairo::PdfSurface", "Cairo::Surface");

##cairo_surface_t * cairo_pdf_surface_create (const char *filename, double width_in_points, double height_in_points);
cairo_surface_t_noinc * cairo_pdf_surface_create (class, const char *filename, double width_in_points, double height_in_points)
    C_ARGS:
	filename, width_in_points, height_in_points
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::PdfSurface");
#endif

##cairo_surface_t * cairo_pdf_surface_create_for_stream (cairo_write_func_t write_func, void *closure, double width_in_points, double height_in_points);
cairo_surface_t_noinc *
cairo_pdf_surface_create_for_stream (class, SV *func, SV *data, double width_in_points, double height_in_points)
    PREINIT:
	CairoPerlCallback *callback;
    CODE:
	callback = cairo_perl_callback_new (func, data);
	RETVAL = cairo_pdf_surface_create_for_stream (write_func_marshaller,
	                                              callback,
	                                              width_in_points,
	                                              height_in_points);
	cairo_surface_set_user_data (
		RETVAL, (const cairo_user_data_key_t *) &callback, callback,
		(cairo_destroy_func_t) cairo_perl_callback_free);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::PdfSurface");
#endif
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_pdf_surface_set_size (cairo_surface_t *surface, double width_in_points, double height_in_points);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 10, 0)

void cairo_pdf_surface_restrict_to_version (cairo_surface_t *surface, cairo_pdf_version_t version);

# void cairo_pdf_get_versions (cairo_pdf_version_t const **versions, int *num_versions);
void
cairo_pdf_surface_get_versions (class=NULL)
    PREINIT:
	cairo_pdf_version_t const *versions = NULL;
	int num_versions = 0, i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	cairo_pdf_get_versions (&versions, &num_versions);
	EXTEND (sp, num_versions);
	for (i = 0; i < num_versions; i++)
		PUSHs (sv_2mortal (newSVCairoPdfVersion (versions[i])));

# const char * cairo_pdf_version_to_string (cairo_pdf_version_t version);
const char *
cairo_pdf_surface_version_to_string (...)
    CODE:
	if (items == 1) {
		RETVAL = cairo_pdf_version_to_string (SvCairoPdfVersion (ST (0)));
	} else if (items == 2) {
		RETVAL = cairo_pdf_version_to_string (SvCairoPdfVersion (ST (1)));
	} else {
		RETVAL = NULL;
		croak ("Usage: Cairo::PdfSurface::version_to_string (version) or Cairo::PdfSurface->version_to_string (version)");
	}
    OUTPUT:
	RETVAL

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 16, 0)

int cairo_pdf_surface_add_outline (cairo_surface_t *surface, int parent_id, const char *utf8, const char *link_attribs, cairo_pdf_outline_flags_t flags);

BOOT:
    HV *stashpdfsurface = gv_stashpv("Cairo::PdfSurface", 0);
    newCONSTSUB(stashpdfsurface, "OUTLINE_ROOT", newSViv(CAIRO_PDF_OUTLINE_ROOT));

void cairo_pdf_surface_set_metadata (cairo_surface_t *surface, cairo_pdf_metadata_t metadata, const char_utf8 * utf8);

void cairo_pdf_surface_set_page_label (cairo_surface_t *surface, const char *utf8);

void cairo_pdf_surface_set_thumbnail_size (cairo_surface_t *surface, int width, int height);

#endif

#endif

# --------------------------------------------------------------------------- #

#ifdef CAIRO_HAS_PS_SURFACE

MODULE = Cairo::Surface	PACKAGE = Cairo::PsSurface	PREFIX = cairo_ps_surface_

BOOT:
	cairo_perl_set_isa ("Cairo::PsSurface", "Cairo::Surface");

##cairo_surface_t * cairo_ps_surface_create (const char *filename, double width_in_points, double height_in_points);
cairo_surface_t_noinc * cairo_ps_surface_create (class, const char *filename, double width_in_points, double height_in_points)
    C_ARGS:
	filename, width_in_points, height_in_points
    POSTCALL:
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::PsSurface");
#endif

##cairo_surface_t * cairo_ps_surface_create_for_stream (cairo_write_func_t write_func, void *closure, double width_in_points, double height_in_points);
cairo_surface_t_noinc *
cairo_ps_surface_create_for_stream (class, SV *func, SV *data, double width_in_points, double height_in_points)
    PREINIT:
	CairoPerlCallback *callback;
    CODE:
	callback = cairo_perl_callback_new (func, data);
	RETVAL = cairo_ps_surface_create_for_stream (write_func_marshaller,
	                                             callback,
	                                             width_in_points,
	                                             height_in_points);
	cairo_surface_set_user_data (
		RETVAL, (const cairo_user_data_key_t *) &callback, callback,
		(cairo_destroy_func_t) cairo_perl_callback_free);
#if CAIRO_VERSION < CAIRO_VERSION_ENCODE(1, 2, 0)
	cairo_perl_package_table_insert (RETVAL, "Cairo::PsSurface");
#endif
    OUTPUT:
	RETVAL

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 2, 0)

void cairo_ps_surface_set_size (cairo_surface_t *surface, double width_in_points, double height_in_points);

void cairo_ps_surface_dsc_comment (cairo_surface_t *surface, const char *comment);

void cairo_ps_surface_dsc_begin_setup (cairo_surface_t *surface);

void cairo_ps_surface_dsc_begin_page_setup (cairo_surface_t *surface);

#endif

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)

void cairo_ps_surface_restrict_to_level (cairo_surface_t *surface, cairo_ps_level_t level);

# void cairo_ps_get_levels (cairo_ps_level_t const **levels, int *num_levels);
void
cairo_ps_surface_get_levels (class=NULL)
    PREINIT:
	cairo_ps_level_t const *levels = NULL;
	int num_levels = 0, i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	cairo_ps_get_levels (&levels, &num_levels);
	EXTEND (sp, num_levels);
	for (i = 0; i < num_levels; i++)
		PUSHs (sv_2mortal (newSVCairoPsLevel (levels[i])));

# const char * cairo_ps_level_to_string (cairo_ps_level_t level);
const char *
cairo_ps_surface_level_to_string (...)
    CODE:
	if (items == 1) {
		RETVAL = cairo_ps_level_to_string (SvCairoPsLevel (ST (0)));
	} else if (items == 2) {
		RETVAL = cairo_ps_level_to_string (SvCairoPsLevel (ST (1)));
	} else {
		RETVAL = NULL;
		croak ("Usage: Cairo::PsSurface::level_to_string (level) or Cairo::PsSurface->level_to_string (level)");
	}
    OUTPUT:
	RETVAL

void cairo_ps_surface_set_eps (cairo_surface_t *surface, cairo_bool_t eps);

cairo_bool_t cairo_ps_surface_get_eps (cairo_surface_t *surface);

#endif

#endif

# --------------------------------------------------------------------------- #

# The SVG surface doesn't need the special package treatment because it didn't
# exist in cairo 1.0.

#ifdef CAIRO_HAS_SVG_SURFACE

MODULE = Cairo::Surface	PACKAGE = Cairo::SvgSurface	PREFIX = cairo_svg_surface_

BOOT:
	cairo_perl_set_isa ("Cairo::SvgSurface", "Cairo::Surface");

# cairo_surface_t * cairo_svg_surface_create (const char *filename, double width_in_points, double height_in_points);
cairo_surface_t_noinc *
cairo_svg_surface_create (class, const char *filename, double width_in_points, double height_in_points)
    C_ARGS:
	filename, width_in_points, height_in_points

# cairo_surface_t * cairo_svg_surface_create_for_stream (cairo_write_func_t write_func, void *closure, double width_in_points, double height_in_points);
cairo_surface_t_noinc *
cairo_svg_surface_create_for_stream (class, SV *func, SV *data, double width_in_points, double height_in_points)
    PREINIT:
	CairoPerlCallback *callback;
    CODE:
	callback = cairo_perl_callback_new (func, data);
	RETVAL = cairo_svg_surface_create_for_stream (write_func_marshaller,
						      callback,
						      width_in_points,
						      height_in_points);
	cairo_surface_set_user_data (
		RETVAL, (const cairo_user_data_key_t *) &callback, callback,
		(cairo_destroy_func_t) cairo_perl_callback_free);
    OUTPUT:
	RETVAL

void cairo_svg_surface_restrict_to_version (cairo_surface_t *surface, cairo_svg_version_t version);

# void cairo_svg_get_versions (cairo_svg_version_t const **versions, int *num_versions);
void
cairo_svg_surface_get_versions (class=NULL)
    PREINIT:
	cairo_svg_version_t const *versions = NULL;
	int num_versions = 0, i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	cairo_svg_get_versions (&versions, &num_versions);
	EXTEND (sp, num_versions);
	for (i = 0; i < num_versions; i++)
		PUSHs (sv_2mortal (newSVCairoSvgVersion (versions[i])));

# const char * cairo_svg_version_to_string (cairo_svg_version_t version);
const char *
cairo_svg_surface_version_to_string (...)
    CODE:
	if (items == 1) {
		RETVAL = cairo_svg_version_to_string (SvCairoSvgVersion (ST (0)));
	} else if (items == 2) {
		RETVAL = cairo_svg_version_to_string (SvCairoSvgVersion (ST (1)));
	} else {
		RETVAL = NULL;
		croak ("Usage: Cairo::SvgSurface::version_to_string (version) or Cairo::SvgSurface->version_to_string (version)");
	}
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

# The recording surface doesn't need the special package treatment because it
# didn't exist in cairo 1.0.

#ifdef CAIRO_HAS_RECORDING_SURFACE

MODULE = Cairo::Surface	PACKAGE = Cairo::RecordingSurface	PREFIX = cairo_recording_surface_

BOOT:
	cairo_perl_set_isa ("Cairo::RecordingSurface", "Cairo::Surface");

# cairo_surface_t * cairo_recording_surface_create (cairo_content_t, const cairo_rectangle_t *extents);
cairo_surface_t_noinc *
cairo_recording_surface_create (class, cairo_content_t content, cairo_rectangle_t_ornull *extents)
    C_ARGS:
	content, extents

void cairo_recording_surface_ink_extents (cairo_surface_t *surface, OUTLIST double x0, OUTLIST double y0, OUTLIST double width, OUTLIST double height);

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 12, 0)

# cairo_bool_t cairo_recording_surface_get_extents (cairo_surface_t *surface, cairo_rectangle_t *extents);
cairo_rectangle_t *
cairo_recording_surface_get_extents (cairo_surface_t *surface)
    PREINIT:
	cairo_bool_t status;
	cairo_rectangle_t rect;
    CODE:
	status = cairo_recording_surface_get_extents (surface, &rect);
	RETVAL = status ? &rect : NULL;
    OUTPUT:
	RETVAL

#endif

#endif

# --------------------------------------------------------------------------- #

#if CAIRO_VERSION >= CAIRO_VERSION_ENCODE(1, 6, 0)

MODULE = Cairo::Surface	PACKAGE = Cairo::Format	PREFIX = cairo_format_

=for apidoc __function__
=cut
int cairo_format_stride_for_width (cairo_format_t format, int width);

#endif
