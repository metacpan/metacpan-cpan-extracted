#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Route fatal errors through Perl's croak() */
#define COLOURING_FATAL(msg) croak("%s", (msg))

#include "in.h"
#include "in_ops.h"

MODULE = Colouring::In::XS  PACKAGE = Colouring::In::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

void
set_messages(...)
	CODE:
		AV * array = av_make(items, MARK+1);
		MESSAGES = (HV*)SvRV(av_pop(array));

SV *
new(...)
	CODE:
		SV * colour = ST(1);
		SV * a = (items > 2) && SvOK(ST(2)) ? ST(2) : newSViv(1);
		RETVAL = xs_new_color(ST(0), colour, a);
	OUTPUT:
		RETVAL

SV *
rgb(self, red, green, blue, ...)
	SV * self
	SV * red
	SV * green
	SV * blue
	CODE:
		double r = xs_scaled(red, 255);
		double g = xs_scaled(green, 255);
		double b = xs_scaled(blue, 255);
		AV * colour = newAV();
		double a = colouring_clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		av_push(colour, newSVnv(r));
		av_push(colour, newSVnv(g));
		av_push(colour, newSVnv(b));
		RETVAL = xs_new_color(self, newRV_noinc((SV*)colour), newSVnv(a));
	OUTPUT:
		RETVAL

SV *
rgba(self, red, green, blue, ...)
	SV * self
	SV * red
	SV * green
	SV * blue
	CODE:
		double r = xs_scaled(red, 255);
		double g = xs_scaled(green, 255);
		double b = xs_scaled(blue, 255);
		AV * colour = newAV();
		double a = colouring_clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		av_push(colour, newSVnv(r));
		av_push(colour, newSVnv(g));
		av_push(colour, newSVnv(b));
		RETVAL = xs_new_color(self, newRV_noinc((SV*)colour), newSVnv(a));
	OUTPUT:
		RETVAL

SV *
hsl(self, h, s, l, ...)
	SV * self
	SV * h
	SV * s
	SV * l
	CODE:
		double a = colouring_clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		colouring_rgba_t c = colouring_hsl2rgb(SvNV(h), SvNV(s), SvNV(l), a);
		RETVAL = xs_rgba_to_obj(self, c);
	OUTPUT:
		RETVAL

SV *
hsla(self, h, s, l, ...)
	SV * self
	SV * h
	SV * s
	SV * l
	CODE:
		double a = colouring_clamp(items > 4 ? SvNV(ST(4)) : 1, 1);
		colouring_rgba_t c = colouring_hsl2rgb(SvNV(h), SvNV(s), SvNV(l), a);
		RETVAL = xs_rgba_to_obj(self, c);
	OUTPUT:
		RETVAL

SV *
toCSS(self, ...)
	SV * self
	CODE:
		int r = items > 1 ? SvIV(ST(1)) : 0;
		int s = items > 2 ? SvIV(ST(1)) : 0;
		colouring_rgba_t c = xs_extract_rgba(self);
		double alpha = colouring_round(c.a, r);
		if (alpha == 1) {
			char css[8];
			colouring_fmt_hex(c, css, sizeof(css), s);
			RETVAL = newSVpvn(css, strlen(css));
		} else {
			char css[32];
			colouring_fmt_rgba(c, css, sizeof(css));
			RETVAL = newSVpvn(css, strlen(css));
		}
	OVERLOAD: \"\"
	OUTPUT:
		RETVAL

SV *
toTerm(self)
	SV * self
	CODE:
		char css[16];
		colouring_rgba_t c = xs_extract_rgba(self);
		colouring_fmt_term(c, css, sizeof(css));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toOnTerm(self)
	SV * self
	CODE:
		char css[20];
		colouring_rgba_t c = xs_extract_rgba(self);
		colouring_fmt_on_term(c, css, sizeof(css));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toRGB(self, ...)
	SV * self
	CODE:
		colouring_rgba_t c = xs_extract_rgba(self);
		SV * alpha_sv = *hv_fetch((HV*)SvRV(self), "alpha", 5, 0);
		if (numIs(alpha_sv) && SvIV(alpha_sv) != 1) {
			char css[32];
			colouring_fmt_rgba(c, css, sizeof(css));
			RETVAL = newSVpvn(css, strlen(css));
		} else {
			char css[24];
			colouring_fmt_rgb(c, css, sizeof(css));
			RETVAL = newSVpvn(css, strlen(css));
		}
	OUTPUT:
		RETVAL

SV *
toRGBA(self, ...)
	SV * self
	CODE:
		char css[32];
		colouring_rgba_t c = xs_extract_rgba(self);
		colouring_fmt_rgba(c, css, sizeof(css));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHEX(self, ...)
	SV * self
	CODE:
		char css[8];
		colouring_rgba_t c = xs_extract_rgba(self);
		int force_long = SvTRUE(ST(1)) && SvTYPE(ST(1)) == SVt_IV;
		colouring_fmt_hex(c, css, sizeof(css), force_long);
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHSL(self)
	SV * self
	CODE:
		char css[30];
		colouring_rgba_t c = xs_extract_rgba(self);
		colouring_hsl_t hsl = colouring_rgb2hsl(c.r, c.g, c.b, c.a);
		colouring_fmt_hsl(hsl, css, sizeof(css));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
toHSV(self)
	SV * self
	CODE:
		char css[30];
		colouring_rgba_t c = xs_extract_rgba(self);
		colouring_hsv_t hsv = colouring_rgb2hsv(c.r, c.g, c.b);
		colouring_fmt_hsv(hsv, css, sizeof(css));
		RETVAL = newSVpvn(css, strlen(css));
	OUTPUT:
		RETVAL

SV *
lighten(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_lighten(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
darken(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_darken(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
fade(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_fade(c.r, c.g, c.b, c.a, amount);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
fadeout(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_fadeout(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
fadein(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_fadein(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
mix(colour1, colour2, ...)
	SV * colour1
	SV * colour2
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int weight = 50;
		colouring_rgba_t c1, c2, out;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		colour1 = xs_ensure_obj(class, colour1);
		colour2 = xs_ensure_obj(class, colour2);
		c1 = xs_extract_rgba(colour1);
		c2 = xs_extract_rgba(colour2);
		out = colouring_mix(c1, c2, weight);
		RETVAL = xs_rgba_to_obj(class, out);
	OUTPUT:
		RETVAL

SV *
tint(colour, ...)
	SV * colour
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int weight = 50;
		colouring_rgba_t c, out;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		out = colouring_tint(c, weight);
		RETVAL = xs_rgba_to_obj(class, out);
	OUTPUT:
		RETVAL

SV *
shade(colour, ...)
	SV * colour
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int weight = 50;
		colouring_rgba_t c, out;
		if (SvOK(ST(2)) && SvIV(ST(2)) != 0) {
			weight = SvIV(ST(2));
		}
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		out = colouring_shade(c, weight);
		RETVAL = xs_rgba_to_obj(class, out);
	OUTPUT:
		RETVAL

SV *
saturate(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_saturate(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
desaturate(colour, amt, ...)
	SV * colour
	SV * amt
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		int relative = items > 2 && SvOK(ST(2)) && strcmp(SvPV_nolen(ST(2)), "relative") == 0;
		double amount = colouring_depercent(SvPV_nolen(amt));
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_desaturate(c.r, c.g, c.b, c.a, amount, relative);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

SV *
greyscale(colour)
	SV * colour
	CODE:
		SV * class = newSVpv("Colouring::In::XS", 17);
		colouring_rgba_t c;
		colour = xs_ensure_obj(class, colour);
		c = xs_extract_rgba(colour);
		c = colouring_greyscale(c.r, c.g, c.b, c.a);
		RETVAL = xs_rgba_to_obj(class, c);
	OUTPUT:
		RETVAL

void
colour(self)
	SV * self
	PPCODE:
		int i;
		AV * colour = (AV*)SvRV(*hv_fetch((HV*)SvRV(self), "colour", 6, 0));
		int len = av_len(colour);
		EXTEND(SP, len + 1);
		for (i = 0; i <= len; i++) {
			PUSHs(sv_2mortal(newSVsv(*av_fetch(colour, i, 0))));
		}

SV *
get_message(msg)
	SV * msg
	CODE:
		char * key = SvPV_nolen(msg);
		RETVAL = *hv_fetch(MESSAGES, key, strlen(key), 0);
	OUTPUT:
		RETVAL

BOOT:
	colouring_register_ops(aTHX);
