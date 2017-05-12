/*
 * Copyright (c) 2004-2011 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include <cairo-perl.h>
#include <cairo-perl-private.h>

#include "ppport.h"

#define MY_MAGIC_SIG 0xCAFE /* Let's hope this is unique enough */

static MAGIC *
cairo_perl_mg_find (SV *sv, int type)
{
	if (sv) {
		MAGIC *mg;
		for (mg = SvMAGIC (sv); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == type && mg->mg_private == MY_MAGIC_SIG)
				return mg;
		}
	}
	return NULL;
}

static void *
cairo_perl_mg_get (SV * sv)
{
	MAGIC * mg;
	if (!cairo_perl_sv_is_ref (sv) ||
	    !(mg = cairo_perl_mg_find (SvRV (sv), PERL_MAGIC_ext)))
		return NULL;
	return mg->mg_ptr;
}

/* ------------------------------------------------------------------------- */

static SV *
create_tie (SV * sv, void * object, const char * package)
{
	SV * tie;
	HV * stash;
	MAGIC * mg;

	/* Create a tied reference. */
	tie = newRV_noinc (sv);
	stash = gv_stashpv (package, TRUE);
	sv_bless (tie, stash);
	sv_magic (sv, tie, PERL_MAGIC_tied, Nullch, 0);

	/* Associate the array with the original path via magic. */
	sv_magic (sv, 0, PERL_MAGIC_ext, (const char *) object, 0);

	mg = mg_find (sv, PERL_MAGIC_ext);

	/* Mark the mg as belonging to us. */
	mg->mg_private = MY_MAGIC_SIG;

#if PERL_REVISION <= 5 && PERL_VERSION <= 6
	/* perl 5.6.x doesn't actually set mg_ptr when namlen == 0, so do it
	 * now. */
	mg->mg_ptr = (char *) object;
#endif /* 5.6.x */

	return tie;
}

static SV *
create_tied_av (void * object, const char * package)
{
	return create_tie ((SV *) newAV (), object, package);
}

static SV *
create_tied_hv (void * object, const char * package)
{
	return create_tie ((SV *) newHV (), object, package);
}

/* ------------------------------------------------------------------------- */

#define FETCH_POINT(i)						\
	if ((svp = av_fetch (points, i, 0)) &&			\
	    cairo_perl_sv_is_defined (*svp))			\
	{							\
		point = (AV *) SvRV (*svp);			\
		if ((svp = av_fetch (point, 0, 0)))		\
			data[i+1].point.x = SvNV (*svp);	\
		if ((svp = av_fetch (point, 1, 0)))		\
			data[i+1].point.y = SvNV (*svp);	\
	}

static void
fill_data_from_array (cairo_path_data_t * data, cairo_path_data_type_t type, AV * points)
{
	SV ** svp;
	AV * point;
	switch (type) {
	    case CAIRO_PATH_MOVE_TO:
		data->header.type = CAIRO_PATH_MOVE_TO;
		data->header.length = 2;
		FETCH_POINT (0);
		break;

	    case CAIRO_PATH_LINE_TO:
		data->header.type = CAIRO_PATH_LINE_TO;
		data->header.length = 2;
		FETCH_POINT (0);
		break;

	    case CAIRO_PATH_CURVE_TO:
		data->header.type = CAIRO_PATH_CURVE_TO;
		data->header.length = 4;
		FETCH_POINT (0);
		FETCH_POINT (1);
		FETCH_POINT (2);
		break;

	    case CAIRO_PATH_CLOSE_PATH:
		data->header.type = CAIRO_PATH_CLOSE_PATH;
		data->header.length = 1;
		break;
	}
}

/* This uses cairo_perl_alloc_temp.  So the return value is only valid until
 * the next FREETMPS occurs.  At the moment, the only cairo function that
 * *takes* a cairo_path_t is cairo_append_path, and it acts on the path
 * immediately and does not store it.  So that's fine. */
static cairo_path_t *
path_from_array (SV * sv)
{
	AV *av;
	int i, num_data;
	cairo_path_t *path;
	cairo_path_data_t *data;

	if (!cairo_perl_sv_is_array_ref (sv))
		croak ("a Cairo::Path has to be an array reference");

	av = (AV *) SvRV (sv);

	num_data = 0;
	for (i = 0; i <= av_len (av); i++) {
		SV **svp;
		HV *hv;

		svp = av_fetch (av, i, 0);
		if (!svp || !cairo_perl_sv_is_hash_ref (*svp))
			croak ("a Cairo::Path has to contain hash references");
		hv = (HV *) SvRV (*svp);

		svp = hv_fetch (hv, "type", 4, 0);
		if (!svp || !cairo_perl_sv_is_defined (*svp))
			croak ("hash references inside a Cairo::Path must have a 'type' key");

		switch (cairo_path_data_type_from_sv (*svp)) {
		    case CAIRO_PATH_MOVE_TO:
		    case CAIRO_PATH_LINE_TO:
			num_data += 2;
			break;
		    case CAIRO_PATH_CURVE_TO:
			num_data += 4;
			break;
		    case CAIRO_PATH_CLOSE_PATH:
			num_data += 1;
			break;
		}
	}

	path = cairo_perl_alloc_temp (sizeof (cairo_path_t));
	path->num_data = num_data;
	path->data = cairo_perl_alloc_temp (path->num_data * sizeof (cairo_path_data_t));
	path->status = CAIRO_STATUS_SUCCESS;

	data = path->data;
	for (i = 0; i <= av_len (av); i++) {
		SV **svp;
		HV *hv;
		AV *points;

		svp = av_fetch (av, i, 0);
		hv = (HV *) SvRV (*svp);

		svp = hv_fetch (hv, "points", 6, 0);
		if (!svp || !cairo_perl_sv_is_array_ref (*svp))
			croak ("hash references inside a Cairo::Path must "
			       "contain a 'points' key which contains an array "
			       "reference of points");
		points = (AV *) SvRV (*svp);

		svp = hv_fetch (hv, "type", 4, 0);
		fill_data_from_array (data, cairo_path_data_type_from_sv (*svp), points);
		data += data->header.length;
	}

	return path;
}

SV *
newSVCairoPath (cairo_path_t * path)
{
	return create_tied_av (path, "Cairo::Path");
}

cairo_path_t *
SvCairoPath (SV * sv)
{
	cairo_path_t * path;
	path = cairo_perl_mg_get (sv);
	if (!path) {
		path = path_from_array (sv);
	}
	return path;
}

/* ------------------------------------------------------------------------- */

static SV *
newSVCairoPathData (cairo_path_data_t * data)
{
	return create_tied_hv (data, "Cairo::Path::Data");
}

static cairo_path_data_t *
SvCairoPathData (SV * sv)
{
	return cairo_perl_mg_get (sv);
}

/* ------------------------------------------------------------------------- */

static SV *
newSVCairoPathPoints (cairo_path_data_t * data)
{
	return create_tied_av (data, "Cairo::Path::Points");
}

static cairo_path_data_t *
SvCairoPathPoints (SV * sv)
{
	return cairo_perl_mg_get (sv);
}

/* ------------------------------------------------------------------------- */

static SV *
newSVCairoPathPoint (cairo_path_data_t * data)
{
	return create_tied_av (data, "Cairo::Path::Point");
}

static cairo_path_data_t *
SvCairoPathPoint (SV * sv)
{
	return cairo_perl_mg_get (sv);
}

/* ------------------------------------------------------------------------- */

static IV
n_points (cairo_path_data_t * data)
{
	switch (data->header.type) {
	    case CAIRO_PATH_MOVE_TO:
	    case CAIRO_PATH_LINE_TO:
		return 1;
	    case CAIRO_PATH_CURVE_TO:
		return 3;
	    case CAIRO_PATH_CLOSE_PATH:
		return 0;
	}
	return -1;
}

/* ------------------------------------------------------------------------- */

MODULE = Cairo::Path	PACKAGE = Cairo::Path

void DESTROY (SV * sv)
    PREINIT:
	cairo_path_t *path;
    CODE:
	path = SvCairoPath (sv);
	if (path) {
#if PERL_REVISION <= 5 && PERL_VERSION <= 6
		/* Unset mg_ptr to prevent perl 5.6.x from trying to free it again. */
		MAGIC *mg = cairo_perl_mg_find (SvRV (sv), PERL_MAGIC_ext);
		mg->mg_ptr = NULL;
#endif /* 5.6.x */
		cairo_path_destroy (path);
	}

IV FETCHSIZE (cairo_path_t * path)
    PREINIT:
	int i;
    CODE:
	RETVAL = 0;
	for (i = 0; i < path->num_data; i += path->data[i].header.length)
		RETVAL++;
    OUTPUT:
	RETVAL

SV * FETCH (cairo_path_t * path, IV index)
    PREINIT:
	int i, counter = 0;
    CODE:
	RETVAL = &PL_sv_undef;
	for (i = 0; i < path->num_data; i += path->data[i].header.length) {
		if (counter++ == index) {
			cairo_path_data_t *data = &path->data[i];
			RETVAL = newSVCairoPathData (data);
			break;
		}
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Cairo::Path	PACKAGE = Cairo::Path::Data

#if PERL_REVISION <= 5 && PERL_VERSION <= 6

void DESTROY (SV * sv)
    CODE:
	/* Unset mg_ptr to prevent perl 5.6.x from trying to free it. */
	MAGIC *mg = cairo_perl_mg_find (SvRV (sv), PERL_MAGIC_ext);
	if (mg)
		mg->mg_ptr = NULL;

#endif /* 5.6.x */

SV * FETCH (SV * sv, const char * key)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathData (sv);
	if (strEQ (key, "type")) {
		RETVAL = cairo_path_data_type_to_sv (data->header.type);
	} else if (strEQ (key, "points")) {
		RETVAL = newSVCairoPathPoints (data);
	} else {
		croak ("Unknown key '%s' for Cairo::Path::Data", key);
		RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

SV * STORE (SV * sv, const char * key, SV * value)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathData (sv);
	if (strEQ (key, "points")) {
		RETVAL = newSVCairoPathPoints (data);
		fill_data_from_array (data, data->header.type, (AV *) SvRV (value));
	} else {
		croak ("Unhandled key '%s' for Cairo::Path::Data; "
		       "only changing 'points' is supported", key);
		RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

bool EXISTS (sv, const char * key)
    CODE:
	if (strEQ (key, "type")) {
		RETVAL = TRUE;
	} else if (strEQ (key, "points")) {
		RETVAL = TRUE;
	} else {
		RETVAL = FALSE;
	}
    OUTPUT:
	RETVAL

const char * FIRSTKEY (sv)
    CODE:
	RETVAL = "type";
    OUTPUT:
	RETVAL

const char * NEXTKEY (sv, const char * lastkey)
    CODE:
	if (strEQ (lastkey, "type")) {
		RETVAL = "points";
	} else {
		RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Cairo::Path	PACKAGE = Cairo::Path::Points

#if PERL_REVISION <= 5 && PERL_VERSION <= 6

void DESTROY (SV * sv)
    CODE:
	/* Unset mg_ptr to prevent perl 5.6.x from trying to free it. */
	MAGIC *mg = cairo_perl_mg_find (SvRV (sv), PERL_MAGIC_ext);
	if (mg)
		mg->mg_ptr = NULL;

#endif /* 5.6.x */

IV FETCHSIZE (SV * sv)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathPoints (sv);
	RETVAL = n_points (data);
    OUTPUT:
	RETVAL

SV * FETCH (SV * sv, IV index)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathPoints (sv);
	if (index >= 0 && index < n_points (data)) {
		RETVAL = newSVCairoPathPoint (&data[index + 1]);
	} else {
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

SV * STORE (SV * sv, IV index, SV * value)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathPoints (sv);
	if (index >= 0 && index < n_points (data)) {
		cairo_path_data_t * point;
		AV * av;
		SV ** svp;
		point = &data[index + 1];
		RETVAL = newSVCairoPathPoint (point);
		av = (AV *) SvRV (value);
		if ((svp = av_fetch (av, 0, 0)))
			point->point.x = SvNV (*svp);
		if ((svp = av_fetch (av, 1, 0)))
			point->point.y = SvNV (*svp);
	} else {
		RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Cairo::Path	PACKAGE = Cairo::Path::Point

#if PERL_REVISION <= 5 && PERL_VERSION <= 6

void DESTROY (SV * sv)
    CODE:
	/* Unset mg_ptr to prevent perl 5.6.x from trying to free it. */
	MAGIC *mg = cairo_perl_mg_find (SvRV (sv), PERL_MAGIC_ext);
	if (mg)
		mg->mg_ptr = NULL;

#endif /* 5.6.x */

IV FETCHSIZE (sv)
    CODE:
	RETVAL = 2;
    OUTPUT:
	RETVAL

SV * FETCH (SV * sv, IV index)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathPoint (sv);
	switch (index) {
	    case 0:
		RETVAL = newSVnv (data->point.x);
		break;
	    case 1:
		RETVAL = newSVnv (data->point.y);
		break;
	    default:
		RETVAL = &PL_sv_undef;
		break;
	}
    OUTPUT:
	RETVAL

SV * STORE (SV * sv, IV index, NV value)
    PREINIT:
	cairo_path_data_t * data;
    CODE:
	data = SvCairoPathPoint (sv);
	switch (index) {
	    case 0:
		RETVAL = newSVnv (data->point.x = value);
		break;
	    case 1:
		RETVAL = newSVnv (data->point.y = value);
		break;
	    default:
		RETVAL = &PL_sv_undef;
		break;
	}
    OUTPUT:
	RETVAL
