/*
 * in.h - Perl-XS bridge helpers for Colouring::In::XS
 *
 * Provides the glue between Perl SVs/HVs/AVs and the pure-C
 * colouring_rgba_t from colouring.h.  Header-only; requires
 * PERL_NO_GET_CONTEXT, perl.h and XSUB.h already included.
 *
 * Re-usable by Eshu (CSS preprocessor) or any other XS module
 * that works with Colouring::In colour objects.
 */

#ifndef COLOURING_IN_H
#define COLOURING_IN_H

#include "colouring.h"

/* ── Class name constant ──────────────────────────────────────── */

#define COLOURING_CLASS      "Colouring::In::XS"
#define COLOURING_CLASS_LEN  17

/* ── Message store (set from Perl side) ───────────────────────── */
/* Holds a refcount-managed reference to the user's message hash so
 * the underlying HV stays alive after set_messages() returns. */

static SV * MESSAGES_REF = NULL;

#define MESSAGES \
	((MESSAGES_REF && SvROK(MESSAGES_REF)) ? (HV*)SvRV(MESSAGES_REF) : NULL)

/* ── Bless a hash into the caller's class ─────────────────────── */

static SV * xs_new(SV * class, HV * hash) {
	dTHX;
	if (SvROK(class)) {
		char * name = HvNAME(SvSTASH(SvRV(class)));
		class = newSVpv(name, strlen(name));
	}
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
}

/* ── Quick "does this SV look numeric?" check ─────────────────── */

static int numIs(SV * num) {
	dTHX;
	if (!num || !SvOK(num)) return 0;
	/* looks_like_number is Perl's portable, bounds-safe numeric test
	 * (handles ints, floats, scientific notation, Unicode digits). The
	 * previous hand-rolled scanner had an unbounded write into a
	 * fixed-size stack buffer — a stack-smash on long all-digit input. */
	return looks_like_number(num) ? 1 : 0;
}

/* ── Scale a value that may be a percentage ───────────────────── */

static double xs_scaled(SV * num, int size) {
	dTHX;
	STRLEN len;
	char * number = SvPV(num, len);
	double n = atof(number);
	/* Percent suffix: check the last *character*, not the trailing
	 * NUL (`number[strlen(number)]` always reads '\0'). */
	if (len > 0 && number[len - 1] == '%') {
		return (n * size) / 100;
	}
	return n;
}

/* ── Extract RGBA from a blessed Colouring::In::XS object ─────── */

static colouring_rgba_t xs_extract_rgba(SV * self) {
	dTHX;
	colouring_rgba_t c;
	AV * colour = (AV*)SvRV(*hv_fetch((HV*)SvRV(self), "colour", 6, 0));
	int len = av_len(colour);
	SV *r, *g, *b;

	r = len >= 0 ? *av_fetch(colour, 0, 0) : NULL;
	g = len >= 1 ? *av_fetch(colour, 1, 0) : NULL;
	b = len >= 2 ? *av_fetch(colour, 2, 0) : NULL;

	c.r = (r && SvOK(r)) ? SvNV(r) : 255;
	c.g = (g && SvOK(g)) ? SvNV(g) : 255;
	c.b = (b && SvOK(b)) ? SvNV(b) : 255;
	c.a = SvNV(*hv_fetch((HV*)SvRV(self), "alpha", 5, 0));
	return c;
}

/* ── Convert a colour string into an AV ref of [r,g,b(,a)] ────── */

static SV * xs_convert_colour(const char * colour) {
	dTHX;
	colouring_rgba_t c;
	AV * av;

	if (!colouring_parse(colour, &c)) {
		croak("Cannot convert the colour format");
		return &PL_sv_undef;
	}

	av = newAV();
	av_push(av, newSVnv(c.r));
	av_push(av, newSVnv(c.g));
	av_push(av, newSVnv(c.b));
	if (c.a != 1.0) {
		av_push(av, newSVnv(c.a));
	}
	return newRV_noinc((SV*)av);
}

/* ── Pack RGBA back into a blessed object ─────────────────────── */

static SV * xs_new_color(SV * class, SV * colour, SV * a) {
	dTHX;
	HV * hash = newHV();
	/* Branch on whether colour is a [r,g,b(,a)] arrayref or a string
	 * like "#fff" / "rgb(...)". Crucially, SvRV() is undefined on a
	 * non-reference SV — guard with SvROK first. */
	if (SvROK(colour) && SvTYPE(SvRV(colour)) == SVt_PVAV) {
		if (av_len((AV*)SvRV(colour)) == 3) {
			a = av_pop((AV*)SvRV(colour));
		}
		hv_store(hash, "colour", 6, newSVsv(colour), 0);
	} else {
		colour = xs_convert_colour(SvPV_nolen(colour));
		if (av_len((AV*)SvRV(colour)) == 3) {
			a = av_pop((AV*)SvRV(colour));
		}
		hv_store(hash, "colour", 6, colour, 0);
	}
	hv_store(hash, "alpha", 5, numIs(a) ? newSVsv(a) : newSViv(1), 0);
	return xs_new(class, hash);
}

/* ── Build a new object from colouring_rgba_t ─────────────────── */

static SV * xs_rgba_to_obj(SV * class, colouring_rgba_t c) {
	dTHX;
	AV * av = newAV();
	av_push(av, newSVnv(c.r));
	av_push(av, newSVnv(c.g));
	av_push(av, newSVnv(c.b));
	return xs_new_color(class, newRV_noinc((SV*)av), newSVnv(c.a));
}

/* ── Ensure SV is a colour object (convert string -> obj) ─────── */

static SV * xs_ensure_obj(SV * class, SV * colour) {
	dTHX;
	if (!SvROK(colour)) {
		return xs_new_color(class, colour, newSVnv(1));
	}
	return colour;
}

/* ── Convenience: class SV from constant ──────────────────────── */
/* Mortalised so callers don't have to remember to free it. The hot
 * path (custom ops + helper methods) was previously leaking one SV
 * per invocation. */

static SV * xs_class_sv(void) {
	dTHX;
	return sv_2mortal(newSVpv(COLOURING_CLASS, COLOURING_CLASS_LEN));
}

#endif /* COLOURING_IN_H */
